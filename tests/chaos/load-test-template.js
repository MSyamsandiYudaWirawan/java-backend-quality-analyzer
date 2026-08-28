// k6 load test template — adapt endpoints and assertions at kickoff
// Usage: k6 run load-test-template.js
// Output includes: http_reqs, http_req_duration (P50/P95/P99), checks

import http from 'k6/http';
import { check, sleep } from 'k6';

// --- Configuration (tune these based on the problem) ---
export const options = {
  stages: [
    { duration: '30s', target: 100 },   // ramp up
    { duration: '1m', target: 100 },    // sustained load
    { duration: '10s', target: 0 },     // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],   // 95% of requests under 200ms
    http_req_failed: ['rate<0.01'],     // error rate under 1%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

// --- Test logic (rewrite for actual endpoints at kickoff) ---
export default function () {
  const res = http.get(`${BASE_URL}/health`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);
}

// --- Output handling ---
// k6 outputs JSON summary to stdout. Redirect to file:
//   k6 run --out json=results.json load-test-template.js
// Or use the built-in summary with:
//   k6 run --summary-export=summary.json load-test-template.js
