#!/usr/bin/env node
// ============================================================================
// Native Mode Orchestrator: Boot TARGET jar → smoke gate → k6 full run → stop
// ============================================================================
// Used by run-experiment.sh in native mode (dev iteration; official measured
// runs use --docker). h2 re-point (2026-08-29): boots a TARGET repo's jar —
// the old own-service baseline/advanced MODE is gone.
//
// Driven entirely by env (set by run-experiment.sh):
//   REPO_DIR     working dir for the java process (target repo root)
//   TARGET_JAR   absolute path to the target's boot jar
//   K6_SCRIPT    committed per-repo script (evidence/advanced/h2/<repo>/load-test.js)
//   EVIDENCE_DIR where k6-smoke.json / k6-full.json land
//   SERVICE_URL  default http://localhost:8080
//
// Exit codes: 0 ok (k6 may still have breached thresholds → k6's own 99 is
// passed through), 1 boot/k6 error, 3 smoke gate rejected the scenario.
// ============================================================================

const { spawn } = require('child_process');
const fs = require('fs');
const http = require('http');
const path = require('path');

const REPO_DIR = process.env.REPO_DIR;
const TARGET_JAR = process.env.TARGET_JAR;
const K6_SCRIPT = process.env.K6_SCRIPT;
const EVIDENCE_DIR = process.env.EVIDENCE_DIR;
const SERVICE_URL = process.env.SERVICE_URL || 'http://localhost:8080';

for (const [k, v] of Object.entries({ REPO_DIR, TARGET_JAR, K6_SCRIPT, EVIDENCE_DIR })) {
  if (!v) {
    console.error(`ERROR: ${k} is required (set by run-experiment.sh)`);
    process.exit(2);
  }
}

const SMOKE_JSON = path.join(EVIDENCE_DIR, 'k6-smoke.json');
const FULL_JSON = path.join(EVIDENCE_DIR, 'k6-full.json');

let javaProc = null;
let shuttingDown = false;

function httpGet(url) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, { timeout: 5000 }, (res) => {
      res.resume();
      res.on('end', () => resolve({ status: res.statusCode }));
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
  });
}

// Actuator is not guaranteed on arbitrary repos: ANY HTTP response (even a
// 404) means the web server is up.
async function waitForService(maxSeconds = 120) {
  for (let i = 0; i < maxSeconds; i++) {
    if (javaProc.exitCode !== null) return false; // died during boot
    try {
      await httpGet(`${SERVICE_URL}/`);
      return true;
    } catch {
      // not ready yet
    }
    process.stdout.write('.');
    await new Promise((r) => setTimeout(r, 1000));
  }
  return false;
}

// Resolves with k6's exit code (99 = thresholds breached = measured FAIL,
// still a successful measurement).
function runK6(jsonOut, extraEnv = {}) {
  return new Promise((resolve, reject) => {
    const args = ['run', '--env', `TARGET_URL=${SERVICE_URL}`, '--env', `K6_JSON_OUT=${jsonOut}`];
    for (const [k, v] of Object.entries(extraEnv)) args.push('--env', `${k}=${v}`);
    args.push(K6_SCRIPT);
    const proc = spawn('k6', args, { stdio: 'inherit' });
    proc.on('error', reject);
    proc.on('close', (code) => resolve(code === null ? 1 : code));
  });
}

async function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  if (javaProc && javaProc.exitCode === null) {
    console.log('\nStopping target service...');
    javaProc.kill('SIGTERM');
    setTimeout(() => {
      if (javaProc && javaProc.exitCode === null) javaProc.kill('SIGKILL');
    }, 5000);
    await new Promise((r) => javaProc.on('close', r));
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

async function main() {
  // 1. Boot the target jar
  console.log(`Booting target (${path.basename(TARGET_JAR)}) ...`);
  javaProc = spawn('java', ['-jar', TARGET_JAR, '--server.port=8080'], {
    cwd: REPO_DIR,
    stdio: 'inherit',
  });

  console.log('Waiting for target');
  const ready = await waitForService();
  if (!ready) {
    console.error('\nTarget failed to start within timeout');
    await shutdown();
    process.exit(1);
  }
  console.log('  ready!');

  // 2. Smoke gate: short validation run, then check the summary JSON —
  //    setup must have seeded and checks must have passed at least once.
  console.log('Smoke gate (2 VUs, 5s; validates the committed script) ...');
  const smokeRc = await runK6(SMOKE_JSON, {
    K6_VUS: '2', K6_DURATION: '5s', K6_RAMP: '1s', K6_ENTITY_COUNT: '3',
  });
  let gateOk = false;
  try {
    const m = JSON.parse(fs.readFileSync(SMOKE_JSON, 'utf8')).metrics || {};
    const reqs = (m.http_reqs && m.http_reqs.values.count) || 0;
    const checks = (m.checks && m.checks.values.rate) || 0;
    gateOk = reqs > 0 && checks > 0;
  } catch {
    gateOk = false;
  }
  if (!gateOk) {
    console.error(`Smoke gate FAILED (k6 exit ${smokeRc}): setup did not complete; ` +
      'the scenario is not valid for this repo.');
    await shutdown();
    process.exit(3);
  }

  // 3. Full run with the committed script's fixed profile
  console.log('Full run (fixed profile from committed script) ...');
  const fullRc = await runK6(FULL_JSON);

  // 4. Stop target
  await shutdown();

  console.log('\nDone.');
  console.log(`  smoke : ${SMOKE_JSON}`);
  console.log(`  full  : ${FULL_JSON}`);
  process.exit(fullRc);
}

main().catch(async (err) => {
  console.error('\n' + err.message);
  await shutdown();
  process.exit(1);
});
