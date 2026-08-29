# Session: packaging — advanced branch, 4-stage eval table, README/IMPROVEMENTS/REPRODUCTION/video
- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k2
- Human Checkpoint: yes

## Prompt Given

"ookay what to do next" → packaging per README §4 item 6. Branch decision:
"next should be advanced branch right? what bout master? same copy from
advanced?" → answered from `prompts/00-git-workflow.md` (advanced = merge of
all KEPT experiments; master stays the scaffold snapshot). User's earlier
standing approval covers commits; session resumed once after a balance
reload ("reloading my balance please resume").

## Key Decisions Made

- **`advanced` created at the `exp/h3-full-pipeline` tip** (`cd10eb7`). The
  workflow doc's "every experiment branches from baseline" was deliberately
  deviated from (h1→h2→h3 chained, each adding one capability), so the h3
  tip already IS baseline + all KEPT work; a merge would only fast-forward.
  Experiment branches stay untouched as evidence. Master left as the
  scaffold snapshot per the workflow doc; fast-forwarding it for submission
  platforms that judge the default branch is parked as a human call.
- **Baseline re-ranked against v2 WITHOUT re-measuring.** First attempt
  re-ran the baseline analyzer with `--skip-build` (the README example
  command) — scores came out 40/30 instead of the committed 100/90: the
  original headline ran WITH build+tests. Caught the apples-to-oranges
  mismatch, deleted the bogus eval dir, and instead seeded
  `evidence/eval/baseline-v2/` with the ORIGINAL committed score files +
  `--resume` — pure re-ranking of existing scores against the v2 expert
  ranking, no new measurement. Result: baseline ρ 0.811 (v1) → 0.850 (v2),
  still NOT ROBUST (24% pairs unjudged). The advanced story holds either
  way: 0.973 vs both 0.811 and 0.850.
- **README eval-set table corrected to reality.** The template's planned
  set (iluwatar/java-design-patterns, gs-rest-service, practice-mvc-redis)
  was stale — the final set is the one in `service/targets.txt` (module6
  pinned clone, mvc-caffeine, gs-rest-service-complete). module6's origin
  verified against targets.txt (eugenp/REST-With-Spring @ 9c06a66) after
  the agent's first draft guessed the owner.
- **The rejected-experiment slot filled with a REAL rejection:** the 50-VU
  load profile (vacuous thresholds — every repo PASSed by 5x; rejected
  before any evidence was committed, reports preserved in h2-50vus/).
  Stronger than the by-design code-metrics rejection, which stays as the
  IMPROVEMENTS "removed experiment" entry.
- **Every documented command verified before committing REPRODUCTION.md:**
  `evaluate.py --label h3 --resume` re-run, reproduces ρ = 0.973 exactly
  (diff was note text only). Full unit suite re-run green on `advanced`.

## Agent Output Summary

- `IMPROVEMENTS.md` filled: iteration log (6 rows), full 4-stage eval table
  (per-repo scores baseline/h1/h2/h3 + ρ + tie bounds + pair counts),
  h2/h3 KEPT details, code-metrics REJECTED entry, What Mattered Most
  (measured runtime evidence), What Did Not Matter (GC — envelope-normal in
  all 7 recordings), 30-sec video changelog. Commit `2e6bee6`.
- `README.md` filled: measured headline (0.811→0.973 + caveats), corrected
  eval-set table + disclosure, JFR-on-Windows failure story, hot take,
  trade-offs, stale branch/evidence references. Commit `c7bea72`.
- `REPRODUCTION.md` final: branch table with real results, prerequisites
  (+Python/Node), k6/temurin versions, advanced workflow + eval commands
  (verified), measured runtimes (~6–9 min/repo, ~50–60 min full set),
  Windows troubleshooting (JFR mount, MSYS, env-sensitive baseline).
  Commit `cad0861`.
- `video/script.md` filled with verified numbers + recording tips (10-sec
  live demo = the --resume eval command). Commit `9b662b2`.
- `evidence/eval/baseline-v2/` committed (`2e6bee6`).
- Sanity: full unit suite green on `advanced` after all packaging edits.

## Human Checkpoint

- Human steered the branch model question (advanced vs master) and
  approved the plan; human's standing commit approval covered the five
  packaging commits. Human caught nothing to correct this session; the
  agent self-corrected the baseline re-run mismatch and the module6 owner.

## Retries / Corrections

- Retry: baseline-v2 first computed with fresh `--skip-build` runs → wrong
  scores (40/30 vs committed 100/90) → deleted, seeded original scores,
  `--resume` re-rank only.
- Correction: module6 GitHub owner guessed in first README draft → verified
  against `service/targets.txt` (eugenp/REST-With-Spring) before commit.
- Session interrupted once (balance reload); resumed mid-IMPROVEMENTS edit
  without state loss (todo list + git status re-established context).
