# Session: h1 implementation — collector, scoring, tie-aware harness, KEPT verdict

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k3
- Branch: `exp/h1-rubric-scoring`
- Human Checkpoint: yes

---

## Prompt Given

- "first check context prompts/README.md and list what to do next"
- "good start step 1" (h1 collector)
- "help me commit now then do ext step"
- "btw i for got we should weite our hipotheis right in evidence/experiments"
- "i think you can highlight that its have many same score and the ordering
  is just random by luck" (re baseline ρ = 0.811)
- "iam referencing evidence/eval/baseline/eval-report.md"
- "or maybe add different weight when they have same score for calculating
  Spearman rho ... so it doesnt score too high just by random luck ordering"
- "make sense but I'd push back on the specific mechanism — a custom
  'weighted Spearman' is a non-standard metric judges will pick apart, any
  sugestion?"
- "okay follow you sugestion Tie bounds (best/worst ρ) + tie share"
- "and 2 implement 1 + 2 in evaluate.p" (tie bounds + pair counts)
- "btw just calculate final score ρ ... no need recalculate Score for each
  service in evidence/eval/baseline/eval-report.md"

## Key Decisions Made

- **No custom metric.** The human proposed weighting Spearman ρ to punish
  tie-luck; agent pushed back (non-standard metric, judges would object,
  and we benefit from making the baseline look bad). Adopted instead:
  standard ρ stays primary + exact best/worst ρ bounds over tie-breakings
  + tie share + pair counts (concordant/discordant/unjudged). Sensitivity
  analysis on the standard statistic, not a new statistic.
- **Blind scoring honored.** All 10 score sheets were written from
  collector evidence only; `service/eval/expert-ranking.txt` was never
  read during scoring. Disagreements (blog 9th vs expert 6th; degraded
  5–7th vs expert 9th) surfaced only at eval time and are routed to the
  human via the pre-authorized v2 ranking-revision policy.
- **Environment attribution before scoring.** spring-petclinic's test
  failure during collection was identified as the Day-2 port-5432
  incident reproduced (agent itself had started practice-postgres for the
  practice repos), NOT a genuine regression: both petclinics re-collected
  with the container stopped. petclinic → 76/76 green; degraded → only
  its injected failures remain. Container left stopped.
- **Honest ties kept.** practice-mvc / mvc-caffeine / petclinic-degraded
  tie at 55 — scored what the evidence shows instead of manufacturing
  separation. Their real differences are runtime behavior = h2/h3 scope.
- **Baseline report regenerated with --resume** (human's instruction):
  original per-repo scores reused, only statistics recomputed; the
  tie/pair checks now appear natively in every eval report.

## Agent Output Summary

- Created: `service/advanced/collect.sh` (h1 mechanical collector),
  `service/advanced/analyze-h1.sh` (thin harness wrapper over committed
  score sheets), `tests/unit/test-collect.sh` (19 assertions),
  `tests/unit/test-analyze-h1.sh` (5), fixture
  `tests/unit/fixtures/h1-evidence/fake-repo/score-sheet.json`.
- Modified: `service/eval/evaluate.py` (+`tie_groups`,
  +`spearman_tie_bounds`, +`pair_counts`; report + JSON emit tie bounds,
  tie share, pair check), `tests/unit/test_spearman.py` (14 → 22 tests),
  `evidence/eval/baseline/eval-report.md` (analyst note: ρ=0.811
  overstated; Monte Carlo P(ρ≥0.811 by luck) ≈ 29%).
- Evidence: `evidence/advanced/h1/<repo>/` × 10 (collector artifacts +
  committed `score-sheet.json` with per-item rubric citations);
  `evidence/eval/h1/` (eval run); `evidence/experiments/h1-rubric-scoring.md`
  (hypothesis pre-registered before scoring, verdict KEPT).
- Result: **h1 ρ = 0.865** (baseline 0.811); tie bounds [0.835, 0.929]
  vs baseline [0.527, 0.915]; unjudged pairs 3 vs baseline 11.
- Tests: all suites green (9 bash baseline + 19 bash collector + 5 bash
  wrapper + 22 python).

## Human Checkpoint

- yes — human approved the h1 design (Option A) in the prior session,
  approved the step-1 commit explicitly, redirected the metric work from
  a custom weighted ρ to standard statistics, and ordered the baseline
  report to keep original per-repo scores (--resume, no re-analysis).
- Manual changes by human after agent output: none so far; v2
  ranking-revision decision (blog / petclinic-degraded disagreement) is
  explicitly parked for the human before h2.

## Retries / Corrections

- **set -e + pipefail vs grep:** collector aborted (exit 123) on repos
  with no assertion matches — grep exits 1, xargs maps to 123. Fixed by
  wrapping the three grep pipelines with `|| true`; regression test
  ("zero assertions, no grep abort") added.
- **`mvn -B -q` ate the dependency evidence:** all `dependency-*.log`
  files came out empty. Fixed collect.sh (dependency goals run without
  `-q`); dep evidence re-collected for all 9 build-pass repos. A later
  background re-run of the 3 URL repos again produced empty logs despite
  exit 0 (unexplained; foreground reproduction worked and is what shipped).
- **Self-inflicted environment contamination:** agent started
  practice-postgres for the practice repos, which broke spring-petclinic's
  PostgresIntegrationTests — the same port-5432 sensitivity from Day 2.
  Attributed correctly, both petclinics re-collected with the port free.
- **Hand-computed test value wrong:** first tie-bounds unit test asserted
  ρ = 1/√3 where the correct value is 1.5/√3 (covariance arithmetic
  slip). Caught by the test itself, fixed, suite green.
