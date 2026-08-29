# Load report: spring-mvc-showcase

- Date (UTC): 2026-08-29T08:54:01Z
- Raw k6 JSON: `null`
- Threshold verdict: **NOT_TESTABLE**
- Note: could not generate a valid load scenario: mvn package fails on Java 21: 'package javax.xml.bind.annotation does not exist' (JavaBean.java, see build.log) — archived Spring 5 / Java 1.8 / javax-era WAR with no maintained upgrade path; cannot be built, booted, or load-tested. Runtime scores 0 by policy (prompts/README.md section 5). Consistent with baseline evidence (evidence/eval/baseline/spring-mvc-showcase/).

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
