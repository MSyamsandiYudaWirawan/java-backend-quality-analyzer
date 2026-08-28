# Agent Onboarding Brief — READ THIS FIRST EVERY SESSION

> You are the coding agent for the micro1 Frontier Engineering Challenge
> (Aug 28–31, 2026). This file is the single source of truth for the project
> state. Read it fully before doing anything. Skim sections 1–3 every session;
> the rest is reference.

---

## 1. The Problem

**Code Quality Analyzer for Java backends.** User: a team evaluating a Java
backend repo before acquisition/merge. Manual review is inconsistent and
misses runtime/structural issues. We build an evidence-based quality
assessment where every score traces to a file, test result, or profiler
recording.

- **Baseline** (done): naive shell script, 5 shallow checks → 0–100 score.
  Saturates on any well-formed repo (spring-petclinic = 100/100). This
  blindness is intentional — it is the control.
- **Advanced** (to build): agent workflow — clone → build → parsed test
  evidence → k6+JFR runtime profile of the *target* repo → rubric-scored,
  evidence-linked report.

## 2. The Metric (this replaced the template's throughput framing)

Unit of improvement = **agent capability**, measured on a fixed ~10-repo eval
set (`service/targets.txt`):

- **Primary:** Spearman ρ between analyzer score order and the human-expert
  ranking (`service/eval/expert-ranking.txt`).
- **Co-primary:** per-repo findings the baseline missed, each traced to
  evidence. ρ is coarse at n=10 — never report it alone.
- **Secondary:** evidence traceability, wall-clock time per analysis.

The **rubric** (`service/rubric/quality-rubric.md`) is the shared contract:
the expert ranks with it, the agent scores with it. 100 pts: Build & Test 25,
Architecture 20, Dependencies 15, Runtime 25, Maintainability 15.

The **harness** (`service/eval/evaluate.py`, stdlib-only Python) runs any
analyzer over the eval set and computes ρ:

```bash
python service/eval/evaluate.py --label <name> \
  --analyzer "bash service/baseline/analyze.sh {target} --skip-build --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/<name>
```

## 3. Current State (end of Day 1, Aug 28)

Branch: `baseline`. Clean tree. Commits: `6bbabd9` (baseline analyzer),
`b5eb30e` (reframe + rubric + harness + evidence).

**Built and tested:**
- `service/baseline/analyze.sh` — naive analyzer. 9 bash unit tests pass.
- `service/eval/evaluate.py` — eval harness. 12 Python unit tests pass
  (`python tests/unit/test_spearman.py`). Smoke-verified end-to-end.
- `service/rubric/quality-rubric.md` — scoring contract v1.
- Docs reframed to the eval metric: README, IMPROVEMENTS, REPRODUCTION,
  CHECKLIST. Trajectories started: `trajectories/kimi-cli/` (2 sessions) +
  `index.md`.
- Evidence: `evidence/baseline/spring-petclinic/` (100/100, saturated).

**Session-start sanity check (run these):**
```bash
tests/unit/test-baseline.sh && python tests/unit/test_spearman.py
```

**Environment:** Windows + Git Bash, Java 21.0.11, Maven 3.9.11, k6, Docker,
Python 3.13. **No jq — do not depend on it.** Shell scripts are pinned to LF
via `.gitattributes`. Paths crossing Python→bash must go through
`bash_path()`-style handling (backslashes get eaten; see trajectory
2026-08-28_23-32 for the incident).

## 4. Day 2 Plan (in order — do not skip ahead)

1. **Validate public targets.** Clone + Java 21 build pass over
   `service/targets.txt` candidates; drop/replace failures, record drops.
2. **Import the 4 controlled practice repos** (MVC / MVC+Redis / WebFlux /
   WebFlux+Redis — product create + get-by-id service the human built to test
   the benchmark pipeline). TODO: human provides location; import as local
   targets. Their quality ordering is *known* (runtime-measured during
   practice) — they are the method-validation set, and the baseline
   scores all four ~100/100 (baseline-blindness demo for the video).
3. **Expert ranking session (human, 1–2h timeboxed).** Score every validated
   target with the rubric → `service/eval/expert-ranking.txt` + per-repo
   justifications in `evidence/expert-ranking-notes.md`.
4. **Baseline ρ headline.** Run harness (baseline, full build mode) over the
   eval set → `evidence/eval/baseline/`. Record in IMPROVEMENTS.md.
5. **Experiments** (one branch each, `exp/<name>`, each measured through the
   harness on the full eval set):
   - `exp/h1-rubric-scoring` — agent scores repos against the rubric with
     build+test evidence. Expected largest Δρ; becomes the advanced spine.
   - `exp/h2-runtime-profiling` — k6+JFR of *target* services via
     `run-experiment.sh` / `jfr-diagnose.sh`. Start with the 4 controlled
     repos (k6 already exists there).
   - `exp/h3-k6-generation` — agent generates k6 scripts for arbitrary repos
     (see §5). Validation: generated tests must recover the known ordering of
     the 4 controlled repos.
   - REJECTED candidate: pure code-metrics scoring (LOC/complexity) — cheap,
     likely no Δρ, good "what did not matter" entry.
6. **Package:** full baseline-vs-advanced eval table, IMPROVEMENTS/README
   numbers, REPRODUCTION final, video script, trajectories. **No new
   experiments in the final 4 hours.**

## 5. k6 Generation Policy (for h3)

Reproducibility lives in the **artifact**, not the authoring:

- Generated k6 scripts are **committed per repo as evidence**; re-runs use
  the committed script, never regeneration.
- Generation is **template + slots**, not free-form: fixed scenario standard
  (mixed create→read from the actual API surface — OpenAPI/springdoc if
  present, controllers otherwise), fixed load profile (VUs/duration/ramp)
  across all repos for comparability.
- **Smoke gate:** a generated script must pass a short validation run (setup
  succeeds, response checks pass) before acceptance. We vouch by validation,
  not by trust.
- Repo can't be load-tested → Runtime dimension scores 0 with an explicit
  "could not generate a valid load scenario" note. That is a finding, not a
  harness failure.

**Scoped out (documented limitation):** multi-service architectures (Kafka /
outbox / microservice meshes). The pipeline measures one deployable unit —
the bootable service or its gateway. Say so plainly in reports; do not build
a multi-service harness.

## 6. Working Agreements (the human holds you to these)

1. **Trajectories are curated, not raw dumps.** After each meaningful work
   block, write/update a file in `trajectories/kimi-cli/YYYY-MM-DD_HH-MM-{topic}.md`
   using the format in `trajectories/README.md` (prompt, key decisions,
   output summary, human checkpoint, retries) and add a row to
   `trajectories/index.md`. **Engineering content only** — no personal chat,
   no motivation talk. Include genuine retries/corrections; judges want them.
2. **Git mutations need explicit confirmation each time** (commit, branch,
   tag). Propose, wait for approval.
3. **One experiment per branch** (`exp/<name>`); every branch has tests;
   every experiment gets `evidence/experiments/h[N]-[name].md` with
   hypothesis → harness numbers → KEPT/REJECTED before the next one starts.
4. **No claim without evidence.** Every number in README/IMPROVEMENTS links
   to a file under `evidence/`.
5. **TIGERSTYLE** (`prompts/TIGERSTYLE.md`) applies to all generated code.
   Python harness stays stdlib-only.
6. **Pre-existing vs new:** prompts/, benchmarks/, run-experiment.sh,
   jfr-diagnose.sh, docker-compose*.yml, doc scaffolding are pre-existing
   template. Only service/, tests/, evidence/, filled docs, and trajectories
   are event work. Never blur this.
7. **Stop on deadline.** Final 4 hours: docs, video, verification only.

## 7. Scoring Reality Check

Tie-break order: Agent Solution & Engineering (30) > Reproducibility (15) >
Measured Improvement (15) > End-to-End Quality (20). 80/100 points are
execution, not idea. The single most valuable artifact to aim for: **one
undeniable evidence moment** — a repo the baseline scored 100/100 that the
advanced workflow catches failing under load, with the JFR to prove it.

---

## Reference (pre-existing template material)

| File | What it is | Status |
|------|-----------|--------|
| [`post.txt`](post.txt) | Event rules, timeline, judging criteria | current |
| [`problem.txt`](problem.txt) | Full problem statement incl. the code-analysis example (appendix 01) | current |
| [`TIGERSTYLE.md`](TIGERSTYLE.md) | Coding principles for all generated code | current |
| [`../run-experiment.sh`](../run-experiment.sh) | Build → k6 benchmark → report → JFR diagnose pipeline | current — re-pointed at *target* repos in h2/h3 |
| [`../jfr-diagnose.sh`](../jfr-diagnose.sh) | JFR hypothesis-driven diagnosis | current — same |
| `01-scaffold-service.md`, `00-scaffold-reactive-service.md` | MVC / WebFlux+Redis scaffold references | legacy — from the practice problem; useful only as reference for the 4 controlled repos |
| `02–05-*.md` (CAS, idempotency, chaos, outbox) | Practice-problem patterns | legacy — out of scope (multi-service excluded) |
| `00-git-workflow.md` | Branch/commit workflow | current |

The old "ceiling experiment" and perf-tuning workflow from the practice
problem do not apply here — JFR/k6 are analysis tools pointed at *target*
repos, not optimization loops on our own service.
