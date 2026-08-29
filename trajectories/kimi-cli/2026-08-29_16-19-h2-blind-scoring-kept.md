# Session: h2 blind Runtime scoring + eval — KEPT (ρ = 0.954)

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k2
- Human Checkpoint: pending (commit not yet approved)

## Prompt Given

"read the prompts/README.md and list all step we should do for this branch" →
"okay do it" (execute the NEXT list for `exp/h2-k6-generation`: blind Runtime
scoring + h2 eval + experiment record, per prompts/README.md §3).

## Key Decisions Made

- **Blind discipline kept:** scored Runtime reading only the rubric, the 15
  load reports (both profiles), and the 3 NOT_TESTABLE findings — never
  `service/eval/expert-ranking.txt`. The harness saw the v2 ranking only
  after all 10 score sheets were written.
- **JFR item = 0 for ALL repos** (10 of 25 runtime points stay dark until
  h3): same non-distortion rule as h1's Runtime=0, so h2's max achievable
  runtime is 15/25. Chosen over dropping the item or rescaling maxScore —
  keeps sheets comparable across h1/h2/h3.
- **Latency/throughput scored against the 200-VU stress profile, 50-VU as
  context:** full 10 only for repos passing thresholds at BOTH profiles
  (mvc-caffeine, webflux, webflux-redis, module6); half 5 for FAIL-at-200
  but functional (practice-mvc p95 646ms; spring-petclinic p95 2191ms;
  petclinic-degraded p95 2105ms — degraded, 0% errors, checks 100%).
- **NOT_TESTABLE = Runtime 0 by pre-committed policy** (prompts/README §5),
  applied even to gs-rest-service-complete which boots fine but has no
  create endpoint: absence of a load-testable API surface is itself the
  finding. Not re-litigated post-hoc.
- **Score sheets edited in place** at `evidence/advanced/h1/<repo>/` so the
  unchanged `analyze-h1.sh` wrapper serves the h2 eval — no new wrapper.

## Agent Output Summary

- Files modified: 10 score sheets (`evidence/advanced/h1/*/score-sheet.json`)
  — runtime block scored with per-item citations, totals updated, analyzer
  string updated to h1+h2. Totals verified against dimension sums (python
  check, 10/10 OK).
- Files created: `evidence/experiments/h2-k6-generation.md`;
  `evidence/eval/h2/` (eval-report.md, eval-results.json, per-repo outputs).
- Tests: session-start sanity suite green (55 bash + 53 python assertions
  across 7 test files) before any scoring.
- Harness numbers: **ρ = 0.954 vs v2** (h1: 0.939, baseline: 0.811), tie
  bounds [0.939, 0.964], pairs 41 concordant / 3 discordant / 1 unjudged.
  Validation bar met: the 4 controlled repos' ordering recovered from load
  reports (analyzer order redis 72 > webflux 71 > caffeine 70 > mvc 65
  matches expert order exactly).
- Verdict: KEPT — `evidence/experiments/h2-k6-generation.md`.

## Human Checkpoint

- Human reviewed the step list before execution ("okay do it").
- Commit of score sheets + eval artifacts + experiment record is PROPOSED,
  awaiting explicit approval (working agreement §6.2).

## Retries / Corrections

- No scoring retries. One deliberate non-action: blog-rest-api's 50-VU
  report has a stale "no pom.xml at repo root" note from an earlier pipeline
  state; used the authoritative 200-VU finding (boot-diagnosis.log) instead
  and documented the staleness in the experiment record rather than
  rewriting history.
