# Session: Controlled practice repos import + baseline blindness check

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k2
- Branch: `baseline`
- Human Checkpoint: yes

---

## Prompt Given

- "check my prompts/README.md for context — i already put my practice repo to
  github" (4 URLs: `practice-mvc`, `practice-mvc-caffeine`, `practice-webflux`,
  `practice-webflux-redis` under github.com/MSyamsandiYudaWirawan)

This is Day 2 plan item 2: import the 4 controlled practice repos as local
targets. They are the method-validation set — their quality ordering is known
from runtime measurements during practice, and the baseline is expected to
saturate (~100/100) on all four.

## Key Decisions Made

- **Local clones under `targets/`, not URLs in the eval set.** Runtime
  profiling (h2/h3) needs the repos on disk with their docker-compose files;
  cloning per analysis run would also make wall-clock times incomparable.
  `targets/` is gitignored — they are external inputs, not project artifacts.
  `service/targets.txt` records them as local paths with their role documented.
- **Validation = clone + Java 21 `mvn -DskipTests package`, per the Day 2
  plan.** All four pass (Spring Boot 4.1.1, Java 21, 3–4 test files each).
- **Full-mode baseline over all four as the blindness check.** This doubles as
  the "tests pass" validation (Testcontainers-based integration tests need
  Docker; Docker 29.4.3 confirmed running).

## Agent Output Summary

- Files modified: `service/targets.txt` (4 controlled targets added with role
  notes), `.gitignore` (`targets/` excluded).
- Directories created: `targets/practice-{mvc,mvc-caffeine,webflux,webflux-redis}`
  (shallow clones), `evidence/baseline/practice-*/` (report + score JSON +
  maven logs per repo).
- Result: **baseline scores all four repos 90/100 — a flat tie.** The
  known-different runtime quality ordering is invisible to the baseline.
  Blindness demo confirmed. (90 not 100 because none of the repos has a root
  README — a shallow-check artifact, identical across all four, so it does not
  break the tie.)

## Human Checkpoint

- Reviewed before accepting: yes (human provided the repo locations and the
  import approach follows the Day 2 plan agreed earlier).
- No manual changes to agent output.

## Retries / Corrections

- **Retry 1 (MVC test failures were environmental, not repo defects):** first
  baseline run scored the two MVC repos 55/100 — `mvn test` failed with
  "Connection to localhost:5432 refused". Root cause: their plain
  `@SpringBootTest` context tests connect to a live Postgres from
  `application.properties`; only the integration tests use Testcontainers. The
  WebFlux repos passed (90/100) because all their DB-touching tests are
  Testcontainers-based. Fix: `docker compose up -d postgres` from the
  practice-mvc compose file (shared `practice-postgres` container), then
  re-run — both MVC repos scored 90/100. Evidence files reflect the final
  passing state; the failed first-run logs were overwritten by the re-run.
- **Lesson recorded for the rubric/h1 work:** the baseline's "tests pass"
  check is environment-sensitive, not repo-intrinsic. The same repo scores 55
  or 90 depending on whether an undocumented external service happens to be
  running. The advanced analyzer must treat "tests require undeclared
  localhost infrastructure" as a finding about the repo, not a silent
  pass/fail of the harness.
