# Load report: petclinic-degraded

- Date (UTC): 2026-08-29T08:43:40Z
- Raw k6 JSON: `C:/study/java-backend-quality-analyzer/evidence/advanced/h2/petclinic-degraded/k6-full.json`
- Threshold verdict: **FAIL**
  - breached: `http_req_duration: p(95)<500`

| Metric | Value |
|--------|-------|
| RPS | 240.43 req/s |
| Total requests | 18138 |
| Fail rate | 0.00% |
| Check pass rate | 100.00% |
| p50 latency | 598.22 ms |
| p95 latency | 2105.28 ms |
| p99 latency | 2993.44 ms |
| max latency | 6610.29 ms |
