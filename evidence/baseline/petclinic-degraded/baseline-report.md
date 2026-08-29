# Baseline Quality Report (naive)

- Target: https://github.com/MSyamsandiYudaWirawan/petclinic-degraded
- Commit: 307e5fd
- Date (UTC): 2026-08-29T03:30:36Z
- Analyzer: service/baseline/analyze.sh (no AI, shallow checks only)

| Check | Weight | Result | Points |
|-------|--------|--------|--------|
| README present | 10 | FAIL | 0 |
| Maven build file (pom.xml) | 10 | PASS | 10 |
| Tests present (20 test files) | 20 | PASS | 20 |
| Build passes (mvn package) | 25 | PASS | 25 |
| Tests pass (mvn test) | 35 | FAIL | 0 |

**Score: 55/100**
