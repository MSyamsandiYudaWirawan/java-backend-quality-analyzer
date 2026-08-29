# Session: Expert-ranking v2 ruling + h2 tooling build (k6 generation + pipeline re-point)

- Date: 2026-08-29 (~06:00–14:20 UTC, human local +07)
- Tool: Kimi Code CLI
- Model: kimi-k2
- Human Checkpoint: yes (repeated, decision-driving)

## Prompt Given

Session opened from `prompts/README.md` (onboarding brief): run the
session-start sanity check, pre-register the h2 hypothesis, then proceed
with h2 (`exp/h2-k6-generation`). Mid-session the human steered repeatedly:
rule on expert-ranking v2 (blog-rest-api, petclinic-degraded); reframe the
benchmark pipeline because "there should be no baseline and advanced option
— what we benchmark is the target repo"; "keep use my pipeline because it's
fair — it uses docker limited resource when testing"; "use the existing
files, I want to stay familiar with my codebase"; finally "split the infra"
into `service/advanced/docker/h2-*.yml`.

## Key Decisions Made

- **Expert-ranking v2 (human ruled, agent prepared evidence):**
  blog-rest-api 6th → 10th, scored 0/100 — verified undeclared-MySQL test
  failure + committed JWT secret (`application.properties:11`) + DB
  passwords in 4 files. Ruling grounded in the expert's OWN red-build
  principle, not in ρ-chasing (circularity warning written into the memo).
  petclinic-degraded kept with an intentional-degradation note: its
  failures are injected by the expert; design intent is not a code property
  an analyzer can see. h1 re-eval vs v2: ρ = 0.939.
- **"baseline for all" rejected with evidence:** the template's
  `run-experiment.sh` cannot execute here even once — `service/` is no
  longer a Maven project (verified: no pom.xml anywhere under `service/`),
  and "baseline" now collides with the baseline *analyzer* in the evidence
  trail. Refactor-now-but-small chosen over disguised hacks.
- **Docker is the official measured path** (human's call, for the
  resource-limited fairness): template's exact envelope (service 2 CPU/2GB
  JVM-pinned, k6 1/512, postgres 1/512, mysql 1/512, redis 0.5/256)
  re-pointed at targets. Native kept only as dev iteration.
- **Generation = template + slots, standalone:** `gen-k6.py` only authors
  committed scripts; it is never invoked by the pipeline. Slots carry the
  infra choice (`infra`/`bootEnv`/`infraEnv`) derived from the target's
  architecture — validated indirectly by the smoke gate (wrong infra → app
  never boots → NOT_TESTABLE finding).
- **Infra split into `service/advanced/docker/h2-*.yml` addendums** merged
  with `-f` (final form after two reversals, see Retries): pre-existing
  `docker-compose.benchmark.yml` reverted to untouched (working agreement
  #6), compose stack validated with `docker compose config`.
- **Pipeline re-point in place:** `run-experiment.sh <target> [--docker]`
  (MODE gone), `benchmarks/orchestrate.js` boot target jar + smoke gate,
  `benchmarks/k6-report.js` fixed report shape + `--finding` NOT_TESTABLE
  mode; `benchmarks/k6.js` marked legacy. Smoke gate (2 VUs/5s, setup must
  seed + checks must pass) is a new step inside the pipeline.

## Agent Output Summary

- Files created: `service/advanced/k6/template.js`,
  `service/advanced/gen-k6.py`, `service/advanced/docker/Dockerfile.target`,
  `service/advanced/docker/h2-{target,postgres,mysql,redis}.yml`,
  `evidence/experiments/h2-k6-generation.md` (pre-registered),
  `evidence/experiments/expert-ranking-v2-decision.md`,
  `tests/unit/test_gen_k6.py` (16), `test-k6-report.sh` (16),
  `test-run-experiment.sh` (5), `tests/unit/fixtures/k6-report/*.json`.
- Files modified: `run-experiment.sh`, `benchmarks/orchestrate.js`,
  `benchmarks/k6-report.js`, `benchmarks/k6.js` (legacy header),
  `service/eval/expert-ranking.txt` (v2), `evidence/expert-ranking-notes.md`
  (v2 section), `prompts/README.md` (state §3, sanity check, reference
  table), `evidence/eval/h1-v2/` (re-run artifacts).
- Files removed (draft superseded by the split design):
  `service/advanced/run-load.sh`, `service/advanced/load-report.py`.
- Tests: 55 pre-existing green at session start; **77 green** at close.
- Verified claims before the v2 ruling against collected evidence
  (repo-scan.txt, dependency-list.txt, test.log) — JWT secret verbatim,
  MySQL driver declared but no server provisioned, contextLoads failure.

## Human Checkpoint

- Human ruled v2 personally (blog → 10th, "the crime is too heavy";
  degraded kept at 8) after reviewing the evidence memo and predicted-ρ
  table. Agent did not touch the ranking until the ruling arrived.
- Human redirected the architecture three times (see Retries); each
  reversal was adopted and the previous form cleaned up.
- No commits without explicit human instruction (commits made at close on
  the human's request).

## Retries / Corrections

- Retry 1 (human): "maybe just baseline option for all" → agent showed the
  baseline path is physically broken here + naming collision; human
  accepted refactor-now-but-small.
- Retry 2 (human): "keep my pipeline — docker limited resources are the
  point" → native-first plan replaced with docker-as-official-path;
  per-repo infra (mysql/postgres/redis) from the target's architecture.
- Retry 3 (human): "use the existing files, familiarity" → consolidated
  into `docker-compose.benchmark.yml` with profiles.
- Retry 4 (human): "split the infra after all" → reverted
  `docker-compose.benchmark.yml` via git checkout, restored split
  `h2-*.yml` addendums. Final form.
- Bug found pre-test by review: curl ready-check could yield `000000`
  (curl prints `000` on failure AND `|| echo 000` appended) — removed the
  fallback echo before it ever ran. Same pass: `JAR_FILE` relative path
  must be computed BEFORE `REPO_DIR` is cygpath-converted to Windows form.
