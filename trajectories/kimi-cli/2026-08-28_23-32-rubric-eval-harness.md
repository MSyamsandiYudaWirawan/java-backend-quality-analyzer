# Session: Quality rubric + Python eval harness

- Date: 2026-08-28
- Tool: Kimi Code CLI
- Model: kimi-k2
- Branch: `baseline`
- Human Checkpoint: yes

---

## Prompt Given

- "Help me reframe this template and refine your log and paste it in
  trajectories. Any ideas for the top-10 repo eval set?"
- "Help me draft the rubric and the Python harness now so tomorrow starts
  with the ranking session."

Context from the plan: the advanced solution is measured by Spearman ρ between
analyzer score order and a human-expert ranking over a fixed ~10-repo eval set.
Two artifacts are prerequisites for that ranking session: a shared scoring
rubric (expert and agent both use it) and an eval harness (runs an analyzer
over the eval set, computes ρ).

## Key Decisions Made

- **Rubric as a shared contract, not an agent-only artifact.** 100 points over
  5 dimensions (Build & Test 25, Architecture 20, Dependencies 15, Runtime 25,
  Maintainability 15). Every item has explicit full/half/zero anchors and a
  required-evidence column, so the expert ranking and the agent scoring are
  the same act performed by two parties — that is what makes ρ meaningful.
- **Runtime dimension scores 0 for non-bootable repos, explicitly.** A library
  or broken service cannot produce k6/JFR evidence; the rubric treats that
  absence as a finding rather than a free pass or a silent skip.
- **Harness in stdlib-only Python, not bash.** Spearman with average ranks for
  ties is ~40 lines; no scipy dependency (TigerStyle §7). Python 3.13 already
  on the machine; the user is more comfortable outside bash.
- **Saturation is reported, not crashed on.** All-equal analyzer scores (the
  baseline's expected behavior) make ρ mathematically undefined; the harness
  returns "not computed" instead of raising, because a saturating control is
  a legitimate result.
- **Expert ranking file format = repo names, best-first.** Converted to
  descending quality values internally so "larger = better" holds everywhere;
  repos missing from the ranking are excluded from ρ with a loud warning
  rather than silently skewing it.

## Agent Output Summary

- Files created: `service/rubric/quality-rubric.md`,
  `service/eval/evaluate.py`, `service/eval/expert-ranking.txt` (placeholder
  for the Day-2 ranking session), `tests/unit/test_spearman.py` (12 tests).
- Tests added: ranks/ties/saturation/known-ρ cases plus helper tests — all
  passing in <5ms. Existing bash unit tests still pass (9 assertions).
- Verification: smoke run over the 3 fixture repos with the real baseline
  analyzer end-to-end through the harness — scores 40/20/0, analyzer order
  matched the mock expert order, ρ = 1.000.
- Bugs found: one real cross-platform bug (see Retries).

## Human Checkpoint

- Reviewed before accepting: yes.
- The human steered scope twice (reframe the docs; draft rubric + harness
  ahead of the ranking session) and approved committing the accumulated work.
- No manual changes were made to agent output after acceptance.

## Retries / Corrections

- **Retry 1 (smoke test caught a real bug):** first harness smoke run reported
  "no *-score.json produced" for every repo. Root cause: Python's
  `os.path.join` emits backslashes on Windows; substituted into the bash
  analyzer command they were consumed as escape characters, so the analyzer
  wrote its reports into a mangled relative directory (a literal `C:` folder
  in the repo). First fix (forward slashes) was insufficient — absolute
  drive-letter paths were still misinterpreted by the shell. Final fix:
  `bash_path()` passes repo-relative paths verbatim (mount-scheme independent)
  and routes absolute paths through `cygpath` with an MSYS-style fallback.
  Smoke run then passed with ρ = 1.000. The stray `C:` directory was removed.
  This is exactly the class of bug that would have silently corrupted
  evidence paths on a judge's machine — caught because the harness was
  smoke-tested before the real eval, not during it.
