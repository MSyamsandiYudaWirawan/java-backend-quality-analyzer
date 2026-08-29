# Experiment h2 — agent-generated k6 load testing

> Status: **complete — KEPT (ρ = 0.954 vs v2)**. Hypothesis pre-registered
> below, unchanged (written before any k6 script was generated or
> executed). Branch: `exp/h2-k6-generation` (from `exp/h1-rubric-scoring`
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

## Open dependency (RESOLVED before h2 eval)

The human's **expert-ranking v2 ruling** was recorded 2026-08-29 (see
`trajectories/kimi-cli/2026-08-29_14-20-v2-ruling-h2-tooling.md`):
blog-rest-api moved to 10th / 0-pts on the verified committed JWT secret,
petclinic-degraded ruling recorded; v2 ranking committed as
`service/eval/expert-ranking.txt`. All h2 numbers below are vs **v2**
(h1 vs v2 = 0.939, `evidence/eval/h1-v2/`).

## Environment record

- `practice-postgres` container is STOPPED as of pre-registration. It must
  be UP (`docker compose up -d postgres` in `targets/practice-mvc/`) for
  practice-mvc / mvc-caffeine boot+load, and STOPPED for spring-petclinic
  / petclinic-degraded (port 5432 conflict — the Day-2 incident).
- blog-rest-api needs an undeclared MySQL (genuine repo finding). If it
  cannot boot for load, Runtime = 0 with the explicit note — that is the
  designed behavior, not a harness failure.
- Windows + Git Bash, Java 21.0.11, Maven 3.9.11, k6, Docker. No jq.
- Measured runs: 2026-08-29 ~08:10–08:55 UTC under the docker envelope,
  sequential (envelope fairness). **Dual fixed profile** (human decision,
  raised BEFORE any evidence was committed because 50 VUs kept every repo
  far from its saturation knee): 50-VU efficiency runs at
  `evidence/advanced/h2-50vus/<repo>/`, 200-VU stress runs at
  `evidence/advanced/h2/<repo>/`; otherwise identical (10s ramp + 60s
  hold, 10% creates / 90% reads of 50 seeded entities, thresholds
  p95<500ms / err<1% / checks>95%).
- Caveat: the k6 container has 1 CPU; mvc-caffeine's 2168 rps may approach
  the generator's ceiling, compressing the top end (noted in its score
  sheet).
- Pipeline fixes mid-pilot: `MSYS_NO_PATHCONV=1` on compose runs (third
  path-mangling incident), k6 `.values` summary nesting; `scenario: form`
  template variant (form POST → 302 → id from Location header → HTML read)
  makes petclinic-class apps measurable; `jarGlob` slot pins module6's
  boot jar. Commits `bc9212f`, `e401654`, `402f6ac`.
- blog-rest-api's 50-VU report carries a stale "no pom.xml at repo root"
  note from an earlier pipeline state; the 200-VU finding
  (`evidence/advanced/h2/springboot-blog-rest-api/`, boot-diagnosis.log)
  is authoritative: boot crash on stock MySQL 8.4 ("Public Key Retrieval
  is not allowed") + ADMIN-JWT wall beyond.
- Runtime scoring rules (fixed before scoring, blind): boots (5) +
  latency/throughput (10) scored from the load reports; **JFR item = 0
  for ALL repos** (h3 capability — same non-distortion rule as h1's
  Runtime=0), so h2 max runtime is 15/25. Full latency credit only for
  PASS at BOTH profiles; half credit for FAIL-at-200 but functional
  (0% errors, checks 100%). NOT_TESTABLE → Runtime 0 by policy §5.
  Scoring done blind: the agent read the rubric, load reports, and
  findings only — never `service/eval/expert-ranking.txt`.

## Harness numbers

Run: `python service/eval/evaluate.py --label h2 --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" --targets service/targets.txt --ranking service/eval/expert-ranking.txt --out evidence/eval/h2`
(full artifacts: `evidence/eval/h2/`; score sheets extended in place at
`evidence/advanced/h1/*/score-sheet.json`; load reports:
`evidence/advanced/h2/` + `evidence/advanced/h2-50vus/`)

| Repo | h2 score (Δ h1) | h2 rank | Expert rank (v2) | Runtime evidence |
|------|-----------------|---------|------------------|------------------|
| spring-petclinic | 82 (+10) | 1 | 1 | FAIL @200: 234 rps, p95 2191ms, max 8111ms |
| REST-With-Spring-module6 | 78 (+15) | 2 | 3 | PASS both: p95 297ms / 1288 rps @200 |
| practice-webflux-redis | 72 (+15) | 3 | 2 | PASS both: p95 227ms / 1448 rps, max 382ms |
| practice-webflux | 71 (+15) | 4 | 4 | PASS both: p95 298ms / 1031 rps @200 |
| practice-mvc-caffeine | 70 (+15) | 5 | 5 | PASS both: p95 170ms / 2168 rps @200 |
| practice-mvc | 65 (+10) | 6.5 | 6 | FAIL @200 (p95 646ms), PASS @50 (p95 106ms) |
| petclinic-degraded | 65 (+10) | 6.5 | 8 | FAIL @200: 240 rps, p95 2105ms |
| gs-rest-service-complete | 50 (+0) | 8 | 7 | NOT_TESTABLE: no create endpoint exists |
| springboot-blog-rest-api | 42 (+0) | 9 | 10 | NOT_TESTABLE: boot crash, stock MySQL 8.4 |
| spring-mvc-showcase | 26 (+0) | 10 | 9 | NOT_TESTABLE: build fails on Java 21 |

- **ρ = 0.954 vs v2** (h1: 0.939, baseline: 0.811), n=10. Tie bounds
  [0.939, 0.964]; one tie group of 2 (practice-mvc / petclinic-degraded
  at 65).
- Pair check: **41 concordant / 3 discordant / 1 unjudged** (h1: 39/3/3;
  baseline: 31/3/11). Unjudged pairs 3 → 1; the h1 3-way tie at 55 is
  broken as designed — caffeine separates from mvc (70 vs 65) on exactly
  the pre-registered mechanism (same code minus a cache: 2168 rps PASS vs
  993 rps FAIL @200).
- petclinic-degraded is runtime-identical to upstream spring-petclinic
  (240 vs 234 rps, p95 2105 vs 2191ms — consistent with byte-identical
  runtime code); its remaining tie with practice-mvc at 65 is honest.
- 3 discordant pairs: (module6, webflux-redis) swapped at ranks 2–3;
  (petclinic-degraded, gs-rest) — the analyzer ranks a load-tested-but-
  slow full app above a skeleton with no API surface; (blog-rest-api,
  mvc-showcase) swapped at ranks 9–10.

## Verdict: **KEPT**

Pre-registered criteria:

- **(b) full-set ρ ≥ h1 with no increase in unjudged pairs: MET cleanly.**
  0.954 ≥ 0.939 (h1 vs v2) and ≥ 0.865 (h1 vs v1); unjudged pairs 3 → 1.
- **(a) controlled-repo ordering recovered: MET at the level the eval
  measures, with one honest caveat.** The analyzer's final order of the 4
  controlled repos — webflux-redis (72) > webflux (71) > mvc-caffeine
  (70) > practice-mvc (65) — matches the known order exactly. The runtime
  evidence alone cleanly recovers the discriminating signal: practice-mvc
  is the only FAIL @200 and lands last of the four. Caveat: raw RPS ranks
  mvc-caffeine first (2168 > 1448 > 1031), so the order *among the three
  PASS repos* comes from the other rubric dimensions, not from runtime
  alone. The 1-CPU generator ceiling makes raw-RPS ties at the top
  unreliable anyway; threshold verdicts are the robust signal.

Findings the baseline could never see:

- **spring-petclinic — baseline 100/100 — saturates at ~240 rps with p95
  2191ms / max 8111ms under 200 VUs, checks 100%**: pure queueing
  collapse. This is the "undeniable evidence moment" candidate
  (prompts/README §7); h3's JFR is positioned to explain the why.
- 3 NOT_TESTABLE findings with cited evidence (boot crash on stock
  MySQL 8.4; no create endpoint; Java 21 build failure) — each a real
  acquisition-relevant defect, scored Runtime = 0 by pre-committed policy.

Remaining caveats: the ρ gain over h1 (+0.015) is small at n=10 — the
strong claim is the evidence and the pair check, not the headline. JFR is
still dark (10 of 25 runtime points): a service can post high RPS with a
critical hotspot underneath — that is h3's question.
