// ============================================================================
// GENERATED FILE — do not edit by hand.
// Rendered from service/advanced/k6/template-form.js + committed slots JSON via
// service/advanced/gen-k6.py. Re-runs use THIS committed script, never
// regeneration (prompts/README.md §5 — k6 Generation Policy).
//
// Fixed scenario standard (identical across repos for comparability):
//   setup()    seeds ENTITY_COUNT entities via the repo's real create endpoint
//   default()  WRITE_RATIO creates, 1-WRITE_RATIO reads of seeded entities
//   thresholds identical across repos (see SLOTS)
//
// Form scenario: create POSTs application/x-www-form-urlencoded and the new
// entity id comes from the redirect Location header (SLOTS.idRegex, group 1).
//
// Runner overrides (service/advanced/run-load.sh):
//   TARGET_URL        booted target address (default: SLOTS.baseUrl)
//   K6_JSON_OUT       summary JSON path (default: k6-summary.json)
// Smoke-gate overrides (validation run only):
//   K6_VUS / K6_DURATION / K6_RAMP / K6_ENTITY_COUNT / K6_WRITE_RATIO
// ============================================================================

import http from 'k6/http';
import { check } from 'k6';

const SLOTS = {
  "baseUrl": "http://localhost:8080",
  "bootEnv": {},
  "checkRateThreshold": 0.95,
  "createPath": "/owners/new",
  "createStatus": 302,
  "duration": "60s",
  "entityCount": 50,
  "errorRateThreshold": 0.01,
  "formFields": {
    "address": "1 Test St",
    "city": "Testville",
    "firstName": "k6-__UNIQ__",
    "lastName": "loadtest",
    "telephone": "1234567890"
  },
  "headers": {
    "Content-Type": "application/json"
  },
  "idRegex": "/owners/(\\d+)",
  "infra": [],
  "infraEnv": {},
  "p95ThresholdMs": 500,
  "ramp": "10s",
  "readPath": "/owners/{id}",
  "readStatus": 200,
  "repoName": "petclinic-degraded",
  "scenario": "form",
  "vus": 200,
  "writeRatio": 0.1
};

const TARGET_URL = __ENV.TARGET_URL || SLOTS.baseUrl;
const VUS = parseInt(__ENV.K6_VUS || `${SLOTS.vus}`);
const DURATION = __ENV.K6_DURATION || SLOTS.duration;
const RAMP = __ENV.K6_RAMP || SLOTS.ramp;
const ENTITY_COUNT = parseInt(__ENV.K6_ENTITY_COUNT || `${SLOTS.entityCount}`);
const WRITE_RATIO = parseFloat(__ENV.K6_WRITE_RATIO || `${SLOTS.writeRatio}`);

export const options = {
  stages: [
    { duration: RAMP, target: VUS },
    { duration: DURATION, target: VUS },
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_duration: [`p(95)<${SLOTS.p95ThresholdMs}`],
    http_req_failed: [`rate<${SLOTS.errorRateThreshold}`],
    checks: [`rate>${SLOTS.checkRateThreshold}`],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

let seedCounter = 0;
function uniq() {
  seedCounter += 1;
  return `${Date.now()}-${__VU}-${seedCounter}`;
}

function formBody() {
  const parts = [];
  for (const [key, value] of Object.entries(SLOTS.formFields)) {
    parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value.replace(/__UNIQ__/g, uniq()))}`);
  }
  return parts.join('&');
}

function createEntity() {
  // redirects: 0 — k6 auto-follows redirects by default, which would lose
  // the Location header the id is extracted from.
  return http.post(`${TARGET_URL}${SLOTS.createPath}`, formBody(), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    redirects: 0,
  });
}

export function setup() {
  const ids = [];
  const idRe = new RegExp(SLOTS.idRegex);
  for (let i = 0; i < ENTITY_COUNT; i++) {
    const res = createEntity();
    if (res.status === SLOTS.createStatus) {
      const location = res.headers['Location'];
      const m = location ? location.match(idRe) : null;
      if (m) {
        ids.push(m[1]);
      } else {
        console.warn(`setup seed ${i}: no id match in Location header: ${location}`);
      }
    } else {
      console.warn(`setup seed ${i} failed: status=${res.status}`);
    }
  }

  if (ids.length === 0) {
    throw new Error(
      `Setup failed: 0/${ENTITY_COUNT} entities seeded ` +
      `(POST ${SLOTS.createPath} expected ${SLOTS.createStatus} with Location matching ${SLOTS.idRegex}). ` +
      'Is the service running? Is the scenario valid for this repo?'
    );
  }

  console.log(`Seeded ${ids.length}/${ENTITY_COUNT} entities`);
  return { ids };
}

export default function (data) {
  if (Math.random() < WRITE_RATIO) {
    const res = createEntity();
    check(res, {
      'create status ok': (r) => r.status === SLOTS.createStatus,
    });
  } else {
    const id = data.ids[Math.floor(Math.random() * data.ids.length)];
    const res = http.get(`${TARGET_URL}${SLOTS.readPath.replace('{id}', id)}`);
    check(res, {
      'read status ok': (r) => r.status === SLOTS.readStatus,
    });
  }
}

export function handleSummary(data) {
  const filename = __ENV.K6_JSON_OUT || 'k6-summary.json';
  return {
    stdout: textSummary(data),
    [filename]: JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const m = data.metrics;
  // k6 nests metric aggregates under .values (counter: count/rate, trend:
  // avg/med/p(...), rate: rate).
  const reqs = (m.http_reqs || {}).values || {};
  const dur = (m.http_req_duration || {}).values || {};
  const fail = (m.http_req_failed || {}).values || {};
  const checks = (m.checks || {}).values || {};
  const f2 = (v) => (v != null ? v.toFixed(2) : 'N/A');

  let out = '';
  out += '\n  === h2 load run ===\n';
  out += `  Requests : ${reqs.count || 0} total @ ${f2(reqs.rate)} req/s\n`;
  out += `  Failed   : ${((fail.rate || 0) * 100).toFixed(2)}%\n`;
  out += `  Checks   : ${((checks.rate || 0) * 100).toFixed(2)}% passed\n`;
  out += `  Latency  : avg=${f2(dur.avg)}ms p50=${f2(dur.med)}ms`;
  out += ` p95=${f2(dur['p(95)'])}ms p99=${f2(dur['p(99)'])}ms max=${f2(dur.max)}ms\n`;
  return out;
}
