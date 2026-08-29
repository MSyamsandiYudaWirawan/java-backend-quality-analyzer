# Expert Ranking Worksheet — Day 2 scoring session (timebox 1–2h)

How to use: for each repo below, score every rubric cell
(`service/rubric/quality-rubric.md`), total → rank. Ties broken by Runtime
subtotal, then Build & Test. Write 2–3 sentences of justification per repo
into `evidence/expert-ranking-notes.md`, then record the final order (best
first, repo names only) in `service/eval/expert-ranking.txt`.

Repo names (as the harness sees them — last path segment):
`practice-mvc`, `practice-mvc-caffeine`, `practice-webflux`,
`practice-webflux-redis`, `spring-petclinic`, `springboot-blog-rest-api`,
`REST-With-Spring-module6`, `gs-rest-service-complete`,
`spring-mvc-showcase`, `petclinic-degraded`.

Score sheet per repo — copy per target:

```
## <repo-name>
| Dimension              | Score | Max | Evidence pointer |
|------------------------|-------|-----|------------------|
| 1. Build & Test        |       | 25  |                  |
| 2. Architecture        |       | 20  |                  |
| 3. Dependencies        |       | 15  |                  |
| 4. Runtime             |       | 25  |                  |
| 5. Maintainability     |       | 15  |                  |
| TOTAL                  |       | 100 |                  |
Justification (2-3 sentences, goes to evidence/expert-ranking-notes.md):
```

## Pre-filled facts (from the Day 2 validation pass — verify, don't trust)

| Repo | Build on Java 21 | Notes for scoring |
|------|------------------|-------------------|
| practice-mvc | PASS | Tests need live Postgres on :5432 (only ITs use Testcontainers); no root README |
| practice-mvc-caffeine | PASS | Same Postgres caveat; no root README |
| practice-webflux | PASS | Tests self-contained (Testcontainers); no root README |
| practice-webflux-redis | PASS | Same; no root README |
| spring-petclinic | PASS | Baseline 100/100 (saturated) |
| springboot-blog-rest-api | PASS | Tutorial-grade single service |
| REST-With-Spring-module6 | PASS (module6 branch) | Default branch is a landing page; pinned local clone of module6 @ 9c06a66. Multi-lesson layout; bootable unit = one -end lesson dir |
| gs-rest-service-complete | PASS (complete/ only) | Repo root is guide scaffolding, not buildable; local clone of complete/ @ 2ef8e28 (no .git). Near-zero tests |
| spring-mvc-showcase | FAIL (fast) | `javax.xml.bind` removed post-Java 8; archived pre-Boot — legit bottom-tier evidence |
| petclinic-degraded | PASS (skipTests) | Fork confirmed: README gone, 20 test files present but `mvn test` fails by construction; baseline 55/100 vs petclinic's 100 |

## Sanity expectations (hypotheses, not ground truth)

- Top: spring-petclinic. Bottom: petclinic-degraded (by construction).
- Controlled four should rank by their known runtime ordering — if they
  don't, that is a finding about the rubric, record it.
- spring-mvc-showcase vs petclinic-degraded at the bottom: degraded is
  intentionally broken, showcase is honestly obsolete — your call, write the
  justification either way.
