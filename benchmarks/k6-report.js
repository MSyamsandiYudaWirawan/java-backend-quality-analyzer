#!/usr/bin/env node
// ============================================================================
// K6 Summary JSON → Fixed-Shape Load Report (h2)
// ============================================================================
// h2 re-point (2026-08-29, exp/h2-k6-generation): reports on a TARGET repo,
// not on our own service's baseline/advanced modes. The old baseline-delta
// tracker table is gone — the report shape is fixed across repos for
// comparability (prompts/README.md §5):
//   RPS, latency percentiles (p50/p95/p99/max), fail rate, check pass rate,
//   threshold verdict, raw k6 JSON path.
//
// Usage:
//   node benchmarks/k6-report.js <k6-summary.json> --repo NAME [--out DIR]
//   node benchmarks/k6-report.js --finding REASON --repo NAME [--out DIR]
//
// --finding mode: a target that cannot be load-tested (build/boot/smoke-gate
// failure) gets a NOT_TESTABLE report with an explicit note — a finding
// (Runtime scores 0), not a harness failure.
//
// Outputs (into --out, default: alongside the k6 JSON):
//   load-report.json   machine-readable fixed shape
//   load-report.md     human-readable table
//
// Exit codes: 0 ok, 1 unusable k6 JSON, 2 usage/io error.
// ============================================================================

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const args = { file: null, finding: null, repo: null, out: null };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--repo' && i + 1 < argv.length) args.repo = argv[++i];
    else if (argv[i] === '--out' && i + 1 < argv.length) args.out = argv[++i];
    else if (argv[i] === '--finding' && i + 1 < argv.length) args.finding = argv[++i];
    else if (!argv[i].startsWith('--') && !args.file) args.file = argv[i];
  }
  return args;
}

const args = parseArgs(process.argv);
if (!args.repo || Boolean(args.file) === Boolean(args.finding)) {
  console.error('Usage: node benchmarks/k6-report.js <k6-summary.json> --repo NAME [--out DIR]');
  console.error('       node benchmarks/k6-report.js --finding REASON --repo NAME [--out DIR]');
  process.exit(2);
}

const nowUtc = () => new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

function breachedThresholds(metrics) {
  const breached = [];
  for (const [metricName, entry] of Object.entries(metrics).sort()) {
    for (const [expr, result] of Object.entries(entry.thresholds || {}).sort()) {
      if (!result.ok) breached.push(`${metricName}: ${expr}`);
    }
  }
  return breached;
}

function buildReport(k6, repo, rawJsonPath) {
  const m = k6.metrics || {};
  if (typeof m !== 'object' || !m.http_reqs) {
    console.error('ERROR: not a k6 summary JSON (no metrics.http_reqs)');
    process.exit(1);
  }
  const v = (name) => (m[name] && m[name].values) || {};
  const reqs = v('http_reqs');
  const dur = v('http_req_duration');
  const breached = breachedThresholds(m);
  return {
    repo,
    dateUtc: nowUtc(),
    rps: reqs.rate || 0,
    totalRequests: reqs.count || 0,
    latency: {
      avg: dur.avg ?? null,
      p50: dur.med ?? null,
      p95: dur['p(95)'] ?? null,
      p99: dur['p(99)'] ?? null,
      max: dur.max ?? null,
    },
    failRate: v('http_req_failed').rate || 0,
    checkPassRate: v('checks').rate || 0,
    thresholds: { verdict: breached.length === 0 ? 'PASS' : 'FAIL', breached },
    rawK6Json: rawJsonPath,
  };
}

function buildFindingReport(repo, reason) {
  return {
    repo,
    dateUtc: nowUtc(),
    rps: null,
    totalRequests: 0,
    latency: { avg: null, p50: null, p95: null, p99: null, max: null },
    failRate: null,
    checkPassRate: null,
    thresholds: { verdict: 'NOT_TESTABLE', breached: [] },
    rawK6Json: null,
    note: `could not generate a valid load scenario: ${reason}`,
  };
}

function renderMd(report) {
  const fmt = (x) => (typeof x === 'number' ? x.toFixed(2) : 'N/A');
  const pct = (x) => (typeof x === 'number' ? `${(x * 100).toFixed(2)}%` : 'N/A');
  const lines = [
    `# Load report: ${report.repo}`,
    '',
    `- Date (UTC): ${report.dateUtc}`,
    `- Raw k6 JSON: \`${report.rawK6Json}\``,
    `- Threshold verdict: **${report.thresholds.verdict}**`,
    ...report.thresholds.breached.map((b) => `  - breached: \`${b}\``),
  ];
  if (report.note) lines.push(`- Note: ${report.note}`);
  lines.push(
    '',
    '| Metric | Value |',
    '|--------|-------|',
    `| RPS | ${fmt(report.rps)} req/s |`,
    `| Total requests | ${report.totalRequests} |`,
    `| Fail rate | ${pct(report.failRate)} |`,
    `| Check pass rate | ${pct(report.checkPassRate)} |`,
    `| p50 latency | ${fmt(report.latency.p50)} ms |`,
    `| p95 latency | ${fmt(report.latency.p95)} ms |`,
    `| p99 latency | ${fmt(report.latency.p99)} ms |`,
    `| max latency | ${fmt(report.latency.max)} ms |`,
    ''
  );
  return lines.join('\n');
}

let report;
if (args.finding) {
  report = buildFindingReport(args.repo, args.finding);
} else {
  let k6;
  try {
    k6 = JSON.parse(fs.readFileSync(args.file, 'utf8'));
  } catch (e) {
    console.error(`ERROR: cannot read k6 JSON ${args.file}: ${e.message}`);
    process.exit(2);
  }
  report = buildReport(k6, args.repo, args.file);
}

const outDir = args.out || path.dirname(args.file);
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'load-report.json'), JSON.stringify(report, null, 2) + '\n');
fs.writeFileSync(path.join(outDir, 'load-report.md'), renderMd(report));

if (report.thresholds.verdict === 'NOT_TESTABLE') {
  console.log(`>> load report for ${report.repo}: NOT_TESTABLE (${args.finding}) -> ${outDir}`);
} else {
  console.log(
    `>> load report for ${report.repo}: ${report.thresholds.verdict} ` +
    `(rps=${report.rps.toFixed(2)} p95=${report.latency.p95} ` +
    `checks=${(report.checkPassRate * 100).toFixed(2)}%) -> ${outDir}`
  );
}
