# Session: Expert ranking v1 + baseline ρ headline

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k3
- Branch: `baseline`
- Human Checkpoint: yes

---

## Prompt Given

- "okay create the expert-ranking.txt ill grade it give me template for grading
  it"
- "damn how do i grade it by check 1 by 1 and run it in my local and test it
  thats take too much time ... can i grade it by only check the structure and
  pom.xml ... if i get mistake then when we prove it in h3 that my grading
  actually wrong"
- (human produced the full 10-repo ranking table with scores + verdicts)
- "just rerun the remaining one" / "just add flag which one is already done"
- "can you check every 3 min? if i forgot and there is bug ill waste so many
  token"

Day 2 plan items 3–4: expert ranking session, then the baseline ρ headline.

## Key Decisions Made

- **Expert grades on structure + pom.xml + collected facts, with declared
  uncertainty — and a pre-authorized v2 revision path.** The human cannot
  run 10 repos locally in the timebox. Agreement recorded in
  `evidence/expert-ranking-notes.md`: v1 is structure-graded EXCEPT the 4
  practice repos, which must be ranked by the expert's measured runtime
  knowledge (they are the method-validation set). If h3 k6/JFR evidence
  contradicts v1, the fix is a documented v2 ranking + eval re-run — never
  treating low ρ as an analyzer failure. Measuring the agent against known-
  stale ground truth would corrupt the metric.
- **Holistic totals recorded, no fabricated subscores.** The expert graded
  with rubric anchors but produced totals only; the notes say so rather than
  inventing per-dimension numbers. ρ consumes order only.
- **Human tie at the bottom resolved by stated principle, then re-scored.**
  petclinic-degraded vs gs-rest-service-complete were tied at 50; the expert's
  own verdict ("a broken fork is worse than a simple green project") implied
  degraded BELOW, contradicting the table order. Flagged by the agent; the
  human swapped them and later re-scored (degraded 30, showcase 15). The
  notes preserve the history.
- **`--resume` flag on the harness (human's suggestion).** Repos with an
  existing `*-score.json` are reused; a crashed 1-hour eval becomes
  resumable. Better than the agent's one-off remaining-targets-file plan.
- **Watchdog cron during long runs (human's request).** A recurring 3-minute
  check distinguished harness bugs from genuine repo failures; auto-deleted
  on completion. Cheap insurance against token-wasting silent failures.

## Agent Output Summary

- Filled: `service/eval/expert-ranking.txt` (v1 order),
  `evidence/expert-ranking-notes.md` (scores, verdicts, v2 policy).
- Fixed: `evaluate.py` URL-mangling bug + `--resume` flag;
  `tests/unit/test_spearman.py` now 14 tests, all green.
- Ran: full baseline eval over 10 repos → `evidence/eval/baseline/`.
- Recorded: IMPROVEMENTS.md iteration-row #2 (baseline headline).
- **Headline: baseline ρ = 0.811 (n=10)** — with a 5-way tie at score 90
  spanning expert ranks 2–8 (gs-rest-service skeleton rated equal to the
  expert's #2 reactive+Redis service). ρ is carried by 3 anchors
  (petclinic top; degraded + showcase bottom).

## Human Checkpoint

- Reviewed before accepting: yes. The ranking is entirely the human's; the
  agent only templated, flagged the #8/#9 contradiction, and mechanized
  evidence collection. Human steered twice mid-run ("just rerun the
  remaining one" → became --resume; "check every 3 min" → watchdog cron).
- No manual changes to agent output beyond the expert's own score edits.

## Retries / Corrections

- **Retry 1 (URL targets failed to clone — real harness bug):** first full
  eval run failed every URL target with "ssh: Could not resolve hostname
  https". Root cause: `bash_path()` in evaluate.py piped targets through
  `os.path.abspath`/`relpath`, mangling `https://github.com/...` into
  `https:/github.com/...`; git parsed the single-slash form as scp syntax
  (host "https", path "/github.com/...") and tried ssh. Day 1's smoke test
  only used local fixture paths, so it never surfaced. Fix: URLs pass
  through unchanged; two regression tests added. Same Windows-path bug
  class as the Day-1 incident — second occurrence, now covered by tests.
- **Retry 2 (petclinic scored 65, not 100 — environment, not repo):** its
  PostgresIntegrationTests spin up their own Postgres via
  spring.docker.compose and could not bind 5432 because the
  `practice-postgres` container (started for the practice-mvc tests) held
  the port. Fix: stop the container, delete the petclinic out-dir, re-run
  via --resume → 100. **ρ swung 0.493 → 0.811 from one stray container** —
  the baseline's environment sensitivity is now a documented headline
  finding, and it validates the plan's rule to never report ρ alone.
- **Blog 65 kept as-is:** its only test needs an undeclared localhost MySQL
  (no Testcontainers, no compose). Genuine repo finding, consistent with
  the expert's "terrible repo hygiene" verdict — not harness-inflicted.
