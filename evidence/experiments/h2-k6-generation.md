# Experiment h2 — agent-generated k6 load testing

> Status: **hypothesis pre-registered** (written before any k6 script was
> generated or executed). Harness numbers and verdict are filled in after
> the eval run. Branch: `exp/h2-k6-generation` (from `exp/h1-rubric-scoring`
> at `68265e4`).

## Hypothesis

An agent that **generates and executes its own k6 load tests** against the
booted target repos — template + slots, fixed load profile across repos —
and scores the rubric's Runtime dimension (25 pts) from the measured
evidence will rank the 10-repo eval set **closer to the expert ranking
than h1 does** (h1 ρ = 0.865, `evidence/eval/h1/`).

Mechanism: h1 scored Runtime = 0 uniformly, leaving 25 rubric points dark.
That produced two known artifacts runtime evidence should resolve:

- The honest 3-way tie at 55 (practice-mvc / practice-mvc-caffeine /
  petclinic-degraded). mvc and caffeine are structurally near-identical —
  their real difference is runtime behavior (caching). Runtime scoring
  must separate them.
- The 4 controlled practice repos have a **known expert ordering by
  measured runtime**: webflux-redis (expert 2) > webflux (4) >
  mvc-caffeine (5) > mvc (7). These four were the ONLY repos ranked on
  measured runtime knowledge (`evidence/expert-ranking-notes.md`). h2 is
  the first capability that can check itself against ground truth.

## Design (per `prompts/README.md` §5 — k6 Generation Policy)

- Generated k6 scripts are **committed per repo as evidence**; re-runs use
  the committed script, never regeneration.
- Generation is **template + slots**: fixed scenario standard (mixed
  create→read from the actual API surface — OpenAPI/springdoc if present,
  controllers otherwise), fixed load profile (VUs/duration/ramp) across
  all repos for comparability.
- **Smoke gate:** a generated script must pass a short validation run
  (setup succeeds, response checks pass) before acceptance. We vouch by
  validation, not by trust.
- Per-repo load report, fixed shape across repos: RPS, latency percentiles
  (p50/p95/p99/max), fail rate, check pass rate, threshold verdict, raw
  k6 JSON path.
- Repo can't be load-tested → Runtime = 0 with an explicit "could not
  generate a valid load scenario" note. A finding, not a harness failure.
- Scoped out (documented limitation): multi-service architectures. The
  pipeline measures one deployable unit.
- Runtime scoring joins the h1 blind score sheets: Runtime replaces the
  uniform 0; the other four dimensions stay as committed in
  `evidence/advanced/h1/*/score-sheet.json` (no re-scoring — h1 results
  remain reproducible).

## Design update (2026-08-29, tooling built — pre-registration above unchanged)

- **Generator:** `service/advanced/k6/template.js` (fixed skeleton, SLOTS
  marker) + `service/advanced/gen-k6.py` (stdlib validator/renderer).
  Slots also carry the benchmark environment: `infra` (postgres/mysql/
  redis, from the target's architecture), `bootEnv` (target container
  overrides), `infraEnv` (infra container credentials).
- **Measured path is Docker** (human decision, for fairness): the
  pre-existing template's exact resource envelope (service 2 CPU/2 GB JVM-
  pinned, k6 1/512, postgres 1/512, mysql 1/512, redis 0.5/256) re-pointed
  at targets. Stack lives in `service/advanced/docker/h2-{target,postgres,
  mysql,redis}.yml` (addendums merged per slots.infra) + generic
  `Dockerfile.target` (identical for all repos). The pre-existing
  `docker-compose.benchmark.yml` stays untouched (working agreement #6).
- **Pipeline:** `run-experiment.sh <target> [--docker]` re-pointed —
  baseline/advanced MODE removed (the own-service it compared no longer
  exists; `service/` is analyzer tooling). Build target → boot → smoke
  gate → full k6 → `benchmarks/k6-report.js` (extended to the fixed
  report shape + NOT_TESTABLE finding mode). `benchmarks/orchestrate.js`
  re-pointed for native dev iteration; official runs are `--docker`.
  `benchmarks/k6.js` marked legacy (superseded by template+slots).
- **h3 seam:** `JFR_OPTS` in h2-target.yml + `jfr-diagnose.sh` (already
  path-agnostic — works on target recordings unchanged).
- Tests: `tests/unit/test_gen_k6.py` (16), `test-k6-report.sh` (16),
  `test-run-experiment.sh` (5); 77 total green.

## Explicit pre-registration of what would falsify it

- KEPT if **both**: (a) the generated+executed load tests recover the
  known ordering of the 4 controlled repos (webflux-redis > webflux >
  mvc-caffeine > mvc on the headline runtime metric), and (b) full-set
  h2 ρ ≥ h1 ρ (0.865) with no increase in unjudged pairs.
- MIXED if the controlled-repo ordering is recovered but full-set ρ drops
  — would mean runtime signal is real but the Runtime rubric scoring maps
  it onto the ranking badly; fix the scoring, not the measurement.
- REJECTED if the controlled-repo ordering is NOT recovered, or smoke
  gates fail on repos the expert ranked on runtime knowledge — the agent
  cannot yet be trusted to generate its own load tests.

## Open dependency (blocks h2 eval, not h2 build)

The human's **expert-ranking v2 ruling** on blog-rest-api (h1 9th vs
expert 6th) and petclinic-degraded (h1 5–7th vs expert 9th) is still open.
Pre-authorized policy: revise with justification and re-run the eval, or
keep v1 with a note. h2 was started without the ruling; it must be
recorded in this directory before the h2 eval numbers are interpreted.

## Environment record (fill in at eval time)

- `practice-postgres` container is STOPPED as of pre-registration. It must
  be UP (`docker compose up -d postgres` in `targets/practice-mvc/`) for
  practice-mvc / mvc-caffeine boot+load, and STOPPED for spring-petclinic
  / petclinic-degraded (port 5432 conflict — the Day-2 incident).
- blog-rest-api needs an undeclared MySQL (genuine repo finding). If it
  cannot boot for load, Runtime = 0 with the explicit note — that is the
  designed behavior, not a harness failure.
- Windows + Git Bash, Java 21.0.11, Maven 3.9.11, k6, Docker. No jq.

## Harness numbers

TBD — filled in after the h2 eval run
(`python service/eval/evaluate.py --label h2 ...`, artifacts under
`evidence/eval/h2/`).

## Verdict

TBD — KEPT / MIXED / REJECTED per the pre-registered criteria above.
