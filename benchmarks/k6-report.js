#!/usr/bin/env node
// ============================================================================
// K6 Summary JSON → Markdown Report Generator
// ============================================================================
// Usage:
//   node benchmarks/k6-report.js baseline
//   node benchmarks/k6-report.js advanced
//   node benchmarks/k6-report.js evidence/k6-run.json [--baseline evidence/k6-baseline.json]
//
// Outputs a markdown block you can paste directly into your experiment tracker.
//
// NOTE: When comparing baseline vs advanced, ensure both runs used the same
// resource envelope. Docker mode (--docker) enforces:
//   Service:  2 CPU / 2 GB  |  k6: 1 CPU / 512 MB  |  Postgres: 1 CPU / 512 MB
// Native mode shares the host — keep other apps closed for fair comparison.
// ============================================================================

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const args = { file: null, baseline: null };
  const first = argv[2] || null;
  if (first === 'baseline' || first === 'advanced') {
    args.file = `evidence/k6-${first}.json`;
    if (first === 'advanced') args.baseline = 'evidence/k6-baseline.json';
  } else {
    args.file = first;
    for (let i = 3; i < argv.length; i++) {
      if (argv[i] === '--baseline' && i + 1 < argv.length) {
        args.baseline = argv[i + 1];
        i++;
      }
    }
  }
  return args;
}

const args = parseArgs(process.argv);
const experimentName = (args.file || '').includes('advanced') ? 'ADVANCED' : 'BASELINE';

if (!args.file || !fs.existsSync(args.file)) {
  console.error('Usage: node benchmarks/k6-report.js <baseline|advanced|k6-summary.json> [--baseline <baseline.json>]');
  process.exit(1);
}

// --- Load metrics -----------------------------------------------------------
function loadMetrics(filePath) {
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const m = data.metrics || {};
  const rv = (metric) => (metric && metric.values) || {};
  return {
    reqs: rv(m.http_reqs),
    dur: rv(m.http_req_duration),
    fail: rv(m.http_req_failed),
    checks: rv(m.checks),
    iterations: rv(m.iterations),
    vus: rv(m.vus_max),
  };
}

// Auto-detect baseline if not provided and file is not already baseline
if (!args.baseline && !args.file.includes('baseline') && fs.existsSync('evidence/k6-baseline.json')) {
  args.baseline = 'evidence/k6-baseline.json';
}
const hasBaselineArg = args.baseline && fs.existsSync(args.baseline);
const run = loadMetrics(args.file);
const base = hasBaselineArg ? loadMetrics(args.baseline) : null;

// --- Extract helper ---------------------------------------------------------
function extract(x) {
  return {
    rps: x.reqs.rate || 0,
    totalReqs: x.reqs.count || 0,
    totalIterations: x.iterations.count || 0,
    failRate: (x.fail.rate || 0) * 100,
    checkRate: (x.checks.rate || 0) * 100,
    avg: x.dur.avg != null ? x.dur.avg : null,
    med: x.dur.med != null ? x.dur.med : null,
    p90: x.dur['p(90)'] != null ? x.dur['p(90)'] : null,
    p95: x.dur['p(95)'] != null ? x.dur['p(95)'] : null,
    p99: x.dur['p(99)'] != null ? x.dur['p(99)'] : null,
    max: x.dur.max != null ? x.dur.max : null,
    maxVus: x.vus.max != null ? x.vus.max : (x.vus.value != null ? x.vus.value : null),
  };
}

// When no --baseline is given, the single file IS the baseline record.
// When --baseline IS given, args.file = This Run, args.baseline = Baseline.
const thisRun = extract(run);
const baseline = hasBaselineArg ? extract(base) : extract(run);

// --- Formatting helpers -----------------------------------------------------
const fmt = (v, unit = '') => v != null ? `${v.toFixed(2)}${unit}` : 'N/A';
const fmtInt = (v) => v != null ? v.toLocaleString() : 'N/A';

function delta(thisVal, baseVal, unit = '', invert = false) {
  if (thisVal == null || baseVal == null) return '—';
  const diff = thisVal - baseVal;
  const pct = baseVal !== 0 ? ((diff / baseVal) * 100) : 0;
  const sign = diff > 0 ? '+' : '';
  const arrow = invert
    ? (diff < 0 ? '↓' : diff > 0 ? '↑' : '')
    : (diff > 0 ? '↑' : diff < 0 ? '↓' : '');
  return `${sign}${diff.toFixed(2)}${unit} (${sign}${pct.toFixed(1)}%) ${arrow}`;
}

// --- Markdown output --------------------------------------------------------
const out = [];

out.push(`## K6 Load Test Report: ${experimentName}`);
out.push('');
out.push(`- **Source:** \`${path.basename(args.file)}\``);
if (hasBaselineArg) out.push(`- **Baseline:** \`${path.basename(args.baseline)}\``);
out.push(`- **Max VUs:** ${fmtInt(thisRun.maxVus)}`);
out.push(`- **Total Requests:** ${fmtInt(thisRun.totalReqs)}`);
out.push(`- **Total Iterations:** ${fmtInt(thisRun.totalIterations)}`);
out.push(`- **Fail Rate:** ${fmt(thisRun.failRate, '%')}`);
out.push(`- **Check Pass Rate:** ${fmt(thisRun.checkRate, '%')}`);
out.push('');

out.push('### Latency');
out.push('');
out.push('| Metric | Value |');
out.push('|--------|-------|');
out.push(`| avg | ${fmt(thisRun.avg)} ms |`);
out.push(`| med | ${fmt(thisRun.med)} ms |`);
out.push(`| p90 | ${fmt(thisRun.p90)} ms |`);
out.push(`| p95 | ${fmt(thisRun.p95)} ms |`);
out.push(`| p99 | ${fmt(thisRun.p99)} ms |`);
out.push(`| max | ${fmt(thisRun.max)} ms |`);
out.push('');

out.push('### Experiment Tracker Row');
out.push('');
out.push('Paste this row into your experiment tracker:');
out.push('');
out.push('| Metric | Baseline | This Run | Delta |');
out.push('|--------|----------|----------|-------|');

const r = thisRun;
const b = baseline;

out.push(`| RPS (req/s) | ${fmt(b.rps)} | ${r ? fmt(r.rps) : '—'} | ${delta(r && r.rps, b.rps, '', false)} |`);
out.push(`| p50 latency (ms) | ${fmt(b.med)} | ${r ? fmt(r.med) : '—'} | ${delta(r && r.med, b.med, '', true)} |`);
out.push(`| p95 latency (ms) | ${fmt(b.p95)} | ${r ? fmt(r.p95) : '—'} | ${delta(r && r.p95, b.p95, '', true)} |`);
out.push(`| p99 latency (ms) | ${fmt(b.p99)} | ${r ? fmt(r.p99) : '—'} | ${delta(r && r.p99, b.p99, '', true)} |`);
out.push(`| max latency (ms) | ${fmt(b.max)} | ${r ? fmt(r.max) : '—'} | ${delta(r && r.max, b.max, '', true)} |`);
out.push(`| errors (%) | ${fmt(b.failRate, '%')} | ${r ? fmt(r.failRate, '%') : '—'} | ${delta(r && r.failRate, b.failRate, '%', true)} |`);
out.push(`| checks passed (%) | ${fmt(b.checkRate, '%')} | ${r ? fmt(r.checkRate, '%') : '—'} | ${delta(r && r.checkRate, b.checkRate, '%', false)} |`);
out.push(`| max VUs | ${fmtInt(b.maxVus)} | ${r ? fmtInt(r.maxVus) : '—'} | — |`);
out.push('');

out.push('### Raw JSON Path');
out.push(`- This run: \`${args.file}\``);
if (hasBaselineArg) out.push(`- Baseline: \`${args.baseline}\``);
out.push('');

const md = out.join('\n');
console.log(md);

// Optionally write to a sidecar .md file
const mdFile = args.file.replace(/\.json$/, '.md');
fs.writeFileSync(mdFile, md);
console.log(`Report also saved to: ${mdFile}`);
