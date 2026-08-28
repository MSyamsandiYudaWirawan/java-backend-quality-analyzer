#!/usr/bin/env node
// ============================================================================
// Native Mode Orchestrator: Start service → wait for ready → run k6 → stop
// ============================================================================
// Used by run-experiment.sh in native mode (without --docker).
// Does NOT generate k6 report — run-experiment.sh handles that uniformly.
//
// Usage:
//   node benchmarks/orchestrate.js baseline
//   node benchmarks/orchestrate.js advanced
// ============================================================================

const { spawn } = require('child_process');
const fs = require('fs');
const http = require('http');
const path = require('path');

const MODE = process.argv[2] || 'baseline';
if (!['baseline', 'advanced'].includes(MODE)) {
  console.error('Usage: node benchmarks/orchestrate.js <baseline|advanced>');
  process.exit(1);
}

const JAR = 'target/service-0.0.1-SNAPSHOT.jar';
// Override k6 script via env var: node benchmarks/orchestrate.js advanced
const K6_SCRIPT = process.env.K6_SCRIPT || 'benchmarks/k6.js';
const OUTPUT_JSON = `evidence/k6-${MODE}.json`;
const JFR_FILE = path.resolve(`evidence/${MODE}.jfr`);
// If localhost fails on your system (IPv4/IPv6 mismatch), override:
//   SERVICE_URL=http://127.0.0.1:8080 node benchmarks/orchestrate.js baseline
const SERVICE_URL = process.env.SERVICE_URL || 'http://localhost:8080';

let javaProc = null;
let shuttingDown = false;

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, { timeout: 5000 }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
  });
}

async function waitForService(maxSeconds = 90) {
  const url = `${SERVICE_URL}/actuator/health`;
  for (let i = 0; i < maxSeconds; i++) {
    try {
      const res = await httpGet(url);
      if (res.status === 200) return true;
    } catch {
      // service not ready yet
    }
    process.stdout.write('.');
    await new Promise((r) => setTimeout(r, 1000));
  }
  return false;
}

function runProcess(cmd, args, opts) {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, opts);
    proc.on('error', reject);
    proc.on('close', (code) => {
      if (code === 0 || code === null) resolve(code);
      else reject(new Error(`${cmd} exited with code ${code}`));
    });
  });
}

async function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  if (javaProc && !javaProc.killed) {
    console.log('\nStopping service...');
    javaProc.kill('SIGTERM');
    // Give it a few seconds to die gracefully, then force
    setTimeout(() => {
      if (javaProc && !javaProc.killed) javaProc.kill('SIGKILL');
    }, 5000);
    await new Promise((r) => javaProc.on('close', r));
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

async function main() {
  // 1. Start Spring Boot service with JFR (no duration → records until JVM exits)
  console.log(`Starting service  (JFR → ${JFR_FILE})`);
  javaProc = spawn(
    'java',
    [
      `-XX:StartFlightRecording=filename=${JFR_FILE},name=${MODE},settings=profile`,
      '-jar',
      JAR,
    ],
    {
      cwd: 'service',
      stdio: 'inherit',
    }
  );

  // 2. Wait for service to be ready
  console.log('Waiting for service');
  const ready = await waitForService();
  if (!ready) {
    console.error('\nService failed to start within timeout');
    await shutdown();
    process.exit(1);
  }
  console.log('  ready!');

  // 3. Run k6
  // Pass TARGET_URL so health poll and k6 hit the same address.
  // Pass through workload env vars so overrides reach k6.
  console.log(`Running k6 ${MODE}`);
  const k6Args = [
    'run',
    '--env', `MODE=${MODE}`,
    '--env', `TARGET_URL=${SERVICE_URL}`,
  ];
  if (process.env.VUS)          k6Args.push('--env', `VUS=${process.env.VUS}`);
  if (process.env.DURATION)     k6Args.push('--env', `DURATION=${process.env.DURATION}`);
  if (process.env.RAMP)         k6Args.push('--env', `RAMP=${process.env.RAMP}`);
  if (process.env.WRITE_RATIO)  k6Args.push('--env', `WRITE_RATIO=${process.env.WRITE_RATIO}`);
  if (process.env.ENTITY_COUNT) k6Args.push('--env', `ENTITY_COUNT=${process.env.ENTITY_COUNT}`);
  k6Args.push(K6_SCRIPT);
  await runProcess('k6', k6Args, { cwd: '.', stdio: 'inherit' });

  // 4. Stop service (flushes JFR)
  // NOTE: k6 report generation is handled by run-experiment.sh uniformly
  // for both native and Docker modes.
  await shutdown();

  console.log('\nDone.');
  console.log(`  JFR   : ${JFR_FILE}`);
  console.log(`  JSON  : ${OUTPUT_JSON}`);
}

main().catch(async (err) => {
  console.error('\n' + err.message);
  await shutdown();
  process.exit(1);
});
