# Session: refinement pass — k3 correction, script docs, Documentation.md, branch topology, per-branch docs
- Date: 2026-08-30
- Tool: Kimi Code CLI
- Model: kimi-k3
- Human Checkpoint: yes

## Prompt Given

Day-2 refinement list from the human (verbatim, lightly abridged): "Change
name master branch to template/init, change default branch to advanced /
replace name all kimi model k2 to k3 / add instruction template for generate
k6 + docker compose benchmark even tho we discourage to generate again /
refine codebase delete the unnecessary part (prompt scaffold etc.) / start
from baseline and reproduce till advanced, result must be same, AI-generated
artifacts (k6 load test etc.) not modified / IMPROVEMENT, README,
REPRODUCTION for branch baseline, exp1, etc still template form except
advanced." Agent was asked to re-order the list for efficiency before
executing. Mid-session steers (all human): drop the prompt-template file in
favor of header docs + a root `Documentation.md`; "should i takeout h1 in
baseline branch?" → discussion → Option C (delete the `baseline` branch);
"check prompts/ in all branch"; backport k3 to exp branches approved;
template/init explicitly off-limits.

## Key Decisions Made

- **Execution order: zero-risk text edits → cleanup + sanity gate → one
  chronological branch walk (docs + `--resume` fused) → branch rename last.**
  Rationale: nothing that can invalidate evidence goes before the sanity
  gate; one checkout per branch instead of two sweeps; the irreversible
  topology change waits until everything else is committed.
- **k2→k3 done as a scoped factual correction, not a blind sed.** Grep
  showed 3 of the k2 hits were `sort -k2` flags (`collect.sh`,
  `jfr-diagnose.sh`) — excluded. 17 files / 31 replacements on `advanced`,
  later backported to all three exp branches (10/14/16 files). `template/init`
  and committed evidence keep the old strings deliberately — they are the
  "before" record.
- **k6-generation prompt template written, then DELETED on human pushback.**
  The human's call was right: every word of it was derivable from
  `gen-k6.py`'s docstring/schema, README §5, and `run-experiment.sh` — a
  second source of truth that would drift. Replaced by (a) header doc blocks
  in every entry-point script and (b) a root `Documentation.md` (codebase
  map: branch map, directory map, pipeline flow, where-the-detail-lives
  table). Judges lacked a map, not a duplicate schema.
- **`baseline` branch deleted (Option C) after discovering it pointed at the
  h1 tip.** Yesterday's session created the label retroactively at `797d4de`
  (already contains all h1 work); there is NO commit with the final
  tie-aware baseline report but without h1 code, so re-pointing backward
  would make the published 0.811 unreproducible from that branch. Discussed
  three options with the human; chose C: the baseline is the control
  *analyzer* + committed evidence, runnable from any branch — REPRODUCTION,
  README checklist, and Documentation.md updated to say so. Fairness story
  ("same harness for baseline and solution") is strengthened, not weakened.
- **`--resume` verification, never re-measurement.** Reproducing each
  stage's headline from committed scores (0.811/0.865/0.939/0.850/0.954/
  0.973 — all reproduced exactly, on their own branches) avoids the
  environment sensitivity that once swung ρ 0.493 → 0.811 (port-5432
  incident). AI-generated artifacts (k6 scripts, slots, score sheets) were
  never modified — per-branch commits are docs-only, verified via
  `git show --stat`.
- **Harness quirk documented:** `evaluate.py --resume` regenerates
  `eval-report.md` and silently drops hand-written analyst notes / flips
  Note columns. Every verification run was followed by
  `git checkout -- evidence/` to keep commits docs-only.

## Agent Output Summary

- Commits on `advanced`: `43716c0` (k3 + script headers + Documentation.md),
  `6388e16` (scaffold/leftover cleanup, sanity suite green), `09ac2b4`
  (baseline branch dropped), `46288c2` (master→template/init recorded).
- Per-branch docs commits (README/IMPROVEMENTS/REPRODUCTION filled from each
  branch's own committed evidence): h1 `3a930c2`, h2 `a90c0e7`, h3 `a7ee593`;
  k3 backports `aa684c8`/`e030172`/`d847edd`; scaffold backports
  `23dd2b4`/`501bad9`/`8293585`.
- `master` renamed to `template/init` (no remote yet — default branch gets
  set on the platform at push time, human's task).
- Qualification checklist verified and ticked 6/8: unit suite all green
  (111 tests), `--resume` reproduces all four v2-era headlines on
  `advanced`, branches documented in IMPROVEMENTS.md, evidence complete
  (raw .jfr gitignored by design), REPRODUCTION commands verified, README
  states tools/event work. Open: video (human), this trajectory.
- Deletions: 6 legacy practice-problem scaffold prompts on all working
  branches, hollow failed clones `targets/spring-petclinic` and
  `targets/springboot-blog-rest-api` (verified zero commits first), stale
  tests READMEs rewritten.

## Human Checkpoint

- Human reviewed and steered at every phase boundary: approved the
  re-ordered plan, rejected the prompt-template artifact in favor of
  Documentation.md, chose Option C for the baseline branch after a full
  options discussion, personally inspected the baseline/h1 branch topology
  mid-session, ordered the prompts/ backport across branches, and declared
  `template/init` untouchable. All git mutations were proposed first and
  executed under standing approval.

## Retries / Corrections

- Retry 1: agent proposed writing `prompts/06-k6-benchmark-generation.md`
  (and a subagent wrote it, verified slot-for-slot against gen-k6.py) —
  human judged it redundant with the self-documenting generator; deleted
  uncommitted and replaced with header docs + Documentation.md. Lesson
  recorded: artifact that duplicates a source of truth is worse than a
  pointer to it.
- Retry 2: agent's initial framing "reproduce baseline → advanced" implied
  re-running k6/JFR; corrected to `--resume`-based verification against
  committed evidence before any branch walk started.
- Correction: first Phase-3 agent discovered `baseline` == h1 tip and
  reported it as a surprise instead of silently "fixing" it — that report
  triggered the human-led Option A/B/C discussion and the branch deletion.
- Correction: h2/h3 docs agent caught the Dockerfile pin drift between
  branches (`21-jre` vs `21-jre-jammy`) and documented each branch's actual
  pin rather than normalizing — evidence fidelity over tidiness.
