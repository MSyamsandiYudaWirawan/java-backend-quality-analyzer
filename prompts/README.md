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

## 3. Current State (end of Day 2, Aug 29 ~11:45)

Branch: `exp/h1-rubric-scoring` (created from `baseline` at `a39e072`; h1
design DECIDED — Option A, agent judgment + committed artifacts; see §4
item 5. Scoring work starts in the next session).
Commits: `6bbabd9` (baseline analyzer), `b5eb30e` (reframe + rubric +
harness), `e3040f1` (controlled repos import), `1cfd7dd` (eval set + expert
ranking v1), `a39e072` (baseline ρ headline + harness fixes).

**Day 2 DONE (items 1–4):**
- **Eval set finalized, n=10, all validated** (clone + Java 21 build).
  `service/targets.txt` is the record, incl. drops and pins. 4 controlled
  practice repos + petclinic + blog-rest-api + spring-mvc-showcase as URLs/
  local clones; 2 non-root-buildable repos pinned as local clones
  (`targets/REST-With-Spring-module6` @9c06a66, `targets/gs-rest-service-complete`
  @2ef8e28); `petclinic-degraded` fork created by the human.
- **Expert ranking v1 complete** (`service/eval/expert-ranking.txt`,
  notes in `evidence/expert-ranking-notes.md`). Graded on structure +
  pom.xml + collected facts; ONLY the 4 practice repos were ranked on
  measured runtime knowledge. **v2 policy:** if h3 runtime evidence
  contradicts v1, revise the ranking with justification and re-run the
  eval — never blame ρ on the analyzer.
- **Baseline ρ headline: 0.811 (n=10)** (`evidence/eval/baseline/`).
  Carried by 3 anchors; the story is the **5-way tie at 90 spanning expert
  ranks 2–8** (gs-rest-service skeleton = practice-webflux-redis).
  **Environment sensitivity is a headline finding:** ρ swung 0.493 → 0.811
  because a stray `practice-postgres` container held port 5432 during
  petclinic's tests. Never report ρ without the per-repo table.
- **Harness hardened:** `bash_path()` URL-mangling fixed (URLs were
  rewritten to `https:/...` → git scp-parse → ssh fail; 2 regression
  tests), `--resume` flag added (reuses existing `*-score.json` per repo;
  crashed runs are resumable). 14 Python unit tests + 9 bash tests green.

**Environment notes:** `practice-postgres` container is currently STOPPED
(restart with `docker compose up -d postgres` in `targets/practice-mvc/`
before running practice-mvc/mvc-caffeine tests or k6). practice-mvc and
mvc-caffeine tests need Postgres on localhost:5432 (only their ITs use
Testcontainers). blog-rest-api tests need an undeclared MySQL (genuine
repo finding — baseline 65 stands).

**Session-start sanity check (run these):**
```bash
tests/unit/test-baseline.sh && python tests/unit/test_spearman.py
```

**Environment:** Windows + Git Bash, Java 21.0.11, Maven 3.9.11, k6, Docker,
Python 3.13. **No jq — do not depend on it.** Shell scripts are pinned to LF
via `.gitattributes`. Paths crossing Python→bash must go through
`bash_path()`-style handling (backslashes get eaten; see trajectory
2026-08-28_23-32 for the incident, and 2026-08-29_11-37 for the URL
variant of the same bug class).

## 4. Day 2 Plan (items 1–4 DONE; item 5 in progress — h1 next)

1. ~~**Validate public targets.**~~ DONE — 10-repo set validated, drops/pins
   recorded in `service/targets.txt`.
2. ~~**Import the 4 controlled practice repos.**~~ DONE — local clones under
   `targets/`; baseline ties all four at 90/100 (blindness evidence in
   `evidence/baseline/practice-*`).
3. ~~**Expert ranking session.**~~ DONE — v1 in
   `service/eval/expert-ranking.txt` + `evidence/expert-ranking-notes.md`
   (v2 revision policy pre-authorized).
4. ~~**Baseline ρ headline.**~~ DONE — **ρ = 0.811** with a 5-way tie at 90
   spanning expert ranks 2–8; recorded in IMPROVEMENTS.md.
5. **Experiments** (one branch each, `exp/<name>`, each measured through the
   harness on the full eval set). Each adds one capability on top of the
   previous; h3 is the everything-working-together payoff:
   - `exp/h1-rubric-scoring` — **branch created; design DECIDED (Option A):**
     agent judgment with committed artifacts. Per repo: mechanical collectors
     (build+test logs, test census, package tree, `dependency:analyze`,
     README/license scan) → agent reads evidence → scores the rubric with
     per-item citations → score sheet committed as evidence. Harness command
     = thin wrapper (collector + read committed scores). Runtime dimension
     scores 0 for ALL repos in h1 ("not yet measured", uniform rule so it
     cannot distort ρ). Question: can the agent score repos at all? Expected
     largest Δρ — judgment must break the 90-tie on Architecture /
     Dependencies / Maintainability, which a script cannot see.
     (Rejected designs: B pure-scripted proxies — shallow package-name
     heuristics, the failure mode we are trying to beat; C hybrid — less
     agent surface.)
   - `exp/h2-k6-generation` — agent generates k6 load scripts for arbitrary
     repos (see §5), runs them against the booted target, and produces a
     per-repo load report as committed evidence: RPS, latency percentiles
     (p50/p95/p99/max), fail rate, check pass rate, threshold verdict, and
     the raw k6 JSON path — fixed report shape across repos for
     comparability. Question: can the agent generate *and execute* its own
     load tests? Validation: generated tests must recover the known ordering
     of the 4 controlled repos.
   - `exp/h3-full-pipeline` — k6 alone only says *how fast*, not *why*: a
     service can post high RPS with a critical hotspot underneath. h3 adds
     JFR profiling during the generated load (`run-experiment.sh` /
     `jfr-diagnose.sh`) and produces a diagnosis report (GC pauses, blocking
     socket reads on request threads, lock contention) alongside the k6
     report. The Runtime dimension grades on both: strong throughput with a
     critical JFR signal scores *lower* than modest throughput with a clean
     profile. Question: does the full pipeline — score, load, profile, grade —
     hold together end to end?
   - REJECTED candidate: pure code-metrics scoring (LOC/complexity) — cheap,
     likely no Δρ, good "what did not matter" entry.
6. **Package:** full baseline-vs-advanced eval table, IMPROVEMENTS/README
   numbers, REPRODUCTION final, video script, trajectories. **No new
   experiments in the final 4 hours.**

## 5. k6 Generation Policy (for h2)

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
