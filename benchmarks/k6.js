import http from 'k6/http';
import { check } from 'k6';

// ============================================================================
// Comprehensive Load Test Template  —  LEGACY (h2, 2026-08-29)
// ============================================================================
// SUPERSEDED for the quality-analyzer event work: k6 scripts for TARGET
// repos are generated via template + slots and committed per repo —
// see service/advanced/k6/template.js and service/advanced/gen-k6.py.
// This file remains as the original free-form reference.
//
// What to change:
//   1. setup()    — seed payload shape, endpoint, and entity count
//   2. default()  — read endpoint, write endpoint, payload shape
//   3. thresholds — adjust p95 / error budgets if needed
//
// Override at runtime:
//   k6 run --env TARGET_URL=http://127.0.0.1:8080 benchmarks/k6.js
//   k6 run --env VUS=100 --env DURATION=120s benchmarks/k6.js
//   k6 run --env WRITE_RATIO=0.2 --env ENTITY_COUNT=500 benchmarks/k6.js
//
// Docker benchmark resource limits (docker-compose.benchmark.yml):
//   Service:  2 CPU / 2 GB   (JVM pinned: -XX:ActiveProcessorCount=2, -Xmx1536m)
//   k6:       1 CPU / 512 MB
//   Postgres: 1 CPU / 512 MB
// Keep defaults reasonable. Raising VUS above ~100 or ENTITY_COUNT above ~500
// on this stack risks k6 OOM (512 MB) or JVM heap exhaustion (1536 MB).
// ============================================================================

const TARGET_URL = __ENV.TARGET_URL || 'http://localhost:8080';
const VUS = parseInt(__ENV.VUS || '50');
const DURATION = __ENV.DURATION || '60s';
const RAMP = __ENV.RAMP || '10s';
const MODE = __ENV.MODE || 'baseline';
const WRITE_RATIO = parseFloat(__ENV.WRITE_RATIO || '0.1'); // 10% writes
const ENTITY_COUNT = parseInt(__ENV.ENTITY_COUNT || '100');
// TODO: Set these from the problem PDF requirements.
const P95_THRESHOLD_MS = parseInt(__ENV.P95_THRESHOLD_MS || '500');
const ERROR_RATE_THRESHOLD = parseFloat(__ENV.ERROR_RATE_THRESHOLD || '0.01');
const CHECK_RATE_THRESHOLD = parseFloat(__ENV.CHECK_RATE_THRESHOLD || '0.95');

export const options = {
  stages: [
    { duration: RAMP, target: VUS },
    { duration: DURATION, target: VUS },
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_duration: [`p(95)<${P95_THRESHOLD_MS}`],
    http_req_failed: [`rate<${ERROR_RATE_THRESHOLD}`],
    checks: [`rate>${CHECK_RATE_THRESHOLD}`],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

export function setup() {
  // TODO: Adapt payload shape and POST endpoint to the problem domain.
  // Example:
  //   const payload = JSON.stringify({ name: `Item-${i}`, value: 10 + (i % 90) });
  //   const res = http.post(`${TARGET_URL}/api/v1/orders`, payload, { headers });

  const headers = { 'Content-Type': 'application/json' };
  const entityIds = [];

  for (let i = 0; i < ENTITY_COUNT; i++) {
    const payload = JSON.stringify({
      // TODO: adapt fields to the actual API
      name: `Entity-${i}`,
    });
    const res = http.post(`${TARGET_URL}/api/v1/[ENDPOINT]`, payload, { headers });

    if (res.status === 201 && res.body) {
      const body = JSON.parse(res.body);
      entityIds.push(body.id);
    } else {
      console.warn(`Setup seed ${i} failed: ${res.status}`);
    }
  }

  if (entityIds.length === 0) {
    throw new Error('Setup failed: no entities seeded. Is the service running?');
  }

  console.log(`Seeded ${entityIds.length} entities`);
  return { entityIds };
}

export default function (data) {
  const ids = data.entityIds;
  const id = ids[Math.floor(Math.random() * ids.length)];

  if (Math.random() < WRITE_RATIO) {
    // TODO: Adapt write endpoint and payload to the problem domain.
    // Example: POST /api/v1/orders (create)
    // Example: PUT  /api/v1/orders/{id}/status (update)

    const payload = JSON.stringify({
      // TODO: adapt fields
      name: `Updated-${Math.floor(Math.random() * 1000)}`,
    });
    const res = http.post(`${TARGET_URL}/api/v1/[ENDPOINT]`, payload, {
      headers: { 'Content-Type': 'application/json' },
    });

    check(res, {
      'write status is 201': (r) => r.status === 201,
      'write time < 200ms': (r) => r.timings.duration < 200,
    });
  } else {
    // TODO: Adapt read endpoint to the problem domain.
    // Example: GET /api/v1/orders/{id}

    const res = http.get(`${TARGET_URL}/api/v1/[ENDPOINT]/${id}`);

    check(res, {
      'read status is 200': (r) => r.status === 200,
      'read time < 200ms': (r) => r.timings.duration < 200,
    });
  }
}

export function handleSummary(data) {
  const filename = `evidence/k6-${MODE}.json`;
  const title = MODE.toUpperCase();
  return {
    stdout: textSummary(data, { indent: ' ', enableColors: true }, title),
    [filename]: JSON.stringify(data, null, 2),
  };
}

function textSummary(data, options, title) {
  const indent = options.indent || '';
  const colors = options.enableColors !== false;
  const c = colors
    ? { grn: '\x1b[32m', red: '\x1b[31m', yel: '\x1b[33m', rst: '\x1b[0m' }
    : { grn: '', red: '', yel: '', rst: '' };

  const m = data.metrics;
  const reqs = m.http_reqs || {};
  const dur = m.http_req_duration || {};
  const fail = m.http_req_failed || {};
  const checks = m.checks || {};

  let out = '';
  out += `${indent}╔══════════════════════════════════════════╗\n`;
  out += `${indent}║         K6 ${title} SUMMARY             ║\n`;
  out += `${indent}╚══════════════════════════════════════════╝\n`;
  out += `${indent}Requests : ${reqs.count || 0} total @ ${(reqs.rate || 0).toFixed(2)} req/s\n`;
  out += `${indent}Failed   : ${(fail.value || 0).toFixed(4)}% (${fail.passes || 0} / ${(fail.passes || 0) + (fail.fails || 0)})\n`;
  out += `${indent}Checks   : ${(checks.value * 100 || 0).toFixed(2)}% passed\n`;
  out += `${indent}Latency  : avg=${dur.avg ? dur.avg.toFixed(2) : 'N/A'}ms`;
  out += ` med=${dur.med ? dur.med.toFixed(2) : 'N/A'}ms`;
  out += ` p95=${dur['p(95)'] ? dur['p(95)'].toFixed(2) : 'N/A'}ms`;
  out += ` p99=${dur['p(99)'] ? dur['p(99)'].toFixed(2) : 'N/A'}ms`;
  out += ` max=${dur.max ? dur.max.toFixed(2) : 'N/A'}ms\n`;

  const pass =
    (checks.value || 0) > 0.95 &&
    (fail.value || 0) < 0.01 &&
    (dur['p(95)'] || 0) < 200;

  out += `${indent}Result   : ${pass ? c.grn + 'PASS' + c.rst : c.red + 'FAIL' + c.rst}\n`;
  out += `${indent}Saved to : evidence/k6-${MODE}.json\n`;
  return out;
}
