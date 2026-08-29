# Load report: springboot-blog-rest-api

- Date (UTC): 2026-08-29T08:53:20Z
- Raw k6 JSON: `null`
- Threshold verdict: **NOT_TESTABLE**
- Note: could not generate a valid load scenario: target crashes at boot in a clean environment: HikariPool init fails with 'Public Key Retrieval is not allowed' against stock MySQL 8.4 (see boot-diagnosis.log) — the hardcoded datasource URL in application.properties assumes the author's local MySQL auth setup (no allowPublicKeyRetrieval, no migrations, undeclared DB dependency). Even if booted, all create endpoints require an ADMIN JWT with manual roles-table bootstrap SQL, so no valid load scenario can be authored. Runtime scores 0 by policy (prompts/README.md section 5).

| Metric | Value |
|--------|-------|
| RPS | N/A req/s |
| Total requests | 0 |
| Fail rate | N/A |
| Check pass rate | N/A |
| p50 latency | N/A ms |
| p95 latency | N/A ms |
| p99 latency | N/A ms |
| max latency | N/A ms |
