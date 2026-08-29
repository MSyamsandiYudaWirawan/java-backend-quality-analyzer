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

## 3. Current State (Aug 29 ~14:30 +07 — v2 ruled; h2 tooling built)

Branch: `exp/h2-k6-generation`. **h1 DONE, verdict KEPT.**
**Expert-ranking v2 RULED + applied this session** (human decision, memo:
`evidence/experiments/expert-ranking-v2-decision.md`): blog-rest-api
6th → **10th, scored 0/100** — undeclared-MySQL test failure + committed
JWT secret verified in `evidence/advanced/h1/springboot-blog-rest-api/`;
"a committed signing secret is unforgivable." petclinic-degraded **kept**
with an intentional-degradation note (its failures are injected by the
expert — design intent is not a code property). h1 re-eval vs v2:
**ρ = 0.939** (was 0.865 vs v1), tie bounds [0.894, 0.965], pairs
39/3/3 — `evidence/eval/h1-v2/`. Always cite ρ with its ranking version.

**h2 tooling BUILT (this session), not yet run on targets:**
- Generator: `service/advanced/k6/template.js` + `gen-k6.py` (template +
  slots; slots also carry `infra`/`bootEnv`/`infraEnv` for the benchmark
  environment). Scripts are committed per repo under
  `evidence/advanced/h2/<repo>/` before any measured run.
- Pipeline re-pointed at targets: `run-experiment.sh <target> [--docker]`
  (baseline/advanced MODE removed), `benchmarks/orchestrate.js` (native
  dev iteration), `benchmarks/k6-report.js` (fixed report shape +
  NOT_TESTABLE finding mode), `benchmarks/k6.js` marked legacy.
- Docker is the OFFICIAL measured path (human decision, fairness):
  template's exact resource envelope in
  `service/advanced/docker/h2-{target,postgres,mysql,redis}.yml`
  (addendums merged per slots.infra) + generic `Dockerfile.target`.
  Pre-existing `docker-compose.benchmark.yml` untouched.
- Smoke gate inside the pipeline: 2 VUs/5s, setup must seed + checks must
  pass, else NOT_TESTABLE finding (exit 3) — a finding, not a failure.
- h3 seam ready: `JFR_OPTS` in h2-target.yml; `jfr-diagnose.sh` already
  works on any .jfr path unchanged.
- Tests: +37 (test_gen_k6.py 16, test-k6-report.sh 16,
  test-run-experiment.sh 5) → **77 total green**.
- NEXT: generate slots+scripts per repo (inspect API surface), commit
  them, then the 10 measured docker runs, Runtime scoring, h2 eval.

Commits through `68265e4` (h1); this session's work (v2 ruling + h2
tooling) committed after this note as two commits — see git log.

**h1 context (from Day 3 morning):** h1 ρ = 0.865 vs v1 ranking
(baseline 0.811) — see `evidence/experiments/h1-rubric-scoring.md`.
Commits: `6bbabd9` (baseline analyzer), `b5eb30e` (reframe + rubric +
harness), `e3040f1` (controlled repos import), `1cfd7dd` (eval set + expert
ranking v1), `a39e072` (baseline ρ headline + harness fixes), `80adef9`
(h1 collector + tests), `a29e5e4` (h1 KEPT: scoring + tie-aware harness),
`68265e4` (inline NOT ROBUST ρ warning).

**Day 3 DONE (h1):**
- **Collector + wrapper:** `service/advanced/collect.sh` (mechanical
  evidence: build/test logs, census, package tree, largest classes,
  dependency:analyze/list, repo scan) and `service/advanced/analyze-h1.sh`
  (thin wrapper: committed score sheet → h1-score.json). 19 + 5 bash
  tests; `mvn -B -q` dependency-suppression bug fixed mid-run.
- **Blind rubric scoring:** 10 committed score sheets
  (`evidence/advanced/h1/*/score-sheet.json`), per-item citations,
  Runtime = 0 uniformly. Scored without reading the expert ranking.
- **h1 eval: ρ = 0.865, KEPT.** 90-tie broken (50–63 span); tie bounds
  [0.835, 0.929]; unjudged pairs 3/45. Honest 3-way tie at 55 kept
  (mvc/caffeine/degraded — real differences are runtime = h2/h3).
- **Harness tie-awareness:** `evaluate.py` reports ρ bounds over
  tie-breakings + tie share + pair counts, and stamps the headline
  `NOT ROBUST: tie-sensitive, range [...], N% of pairs unjudged` when
  >20% of pairs are unjudged (baseline: 24% → stamped; h1: 7% → clean).
  Baseline report regenerated with --resume (original scores kept) +
  analyst note: P(ρ ≥ 0.811 by luck) ≈ 29%. 22 python tests, 55 total.

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
tests/unit/test-baseline.sh && tests/unit/test-collect.sh \
  && tests/unit/test-analyze-h1.sh && python tests/unit/test_spearman.py \
  && python tests/unit/test_gen_k6.py \
  && tests/unit/test-k6-report.sh && tests/unit/test-run-experiment.sh
```

**Environment:** Windows + Git Bash, Java 21.0.11, Maven 3.9.11, k6, Docker,
Python 3.13. **No jq — do not depend on it.** Shell scripts are pinned to LF
via `.gitattributes`. Paths crossing Python→bash must go through
`bash_path()`-style handling (backslashes get eaten; see trajectory
2026-08-28_23-32 for the incident, and 2026-08-29_11-37 for the URL
variant of the same bug class).

## 4. Day 2 Plan (items 1–4 DONE; item 5 in progress — h2 next)

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
   - `exp/h1-rubric-scoring` — ~~branch created; design DECIDED (Option A)~~
     **DONE, KEPT: ρ = 0.865** (baseline 0.811). Built as designed: mechanical
     collector → blind agent scoring with per-item citations → committed
     score sheets → thin harness wrapper; Runtime = 0 uniformly. 90-tie
     broken (50–63 span); unjudged pairs 11 → 3. Full record:
     `evidence/experiments/h1-rubric-scoring.md`. Open follow-up: human's
     v2 ranking ruling on blog-rest-api / petclinic-degraded.
   - `exp/h2-k6-generation` — agent generates k6 load scripts for arbitrary
     repos (see §5), runs them against the booted target, and produces a
     per-repo load report as committed evidence: RPS, latency percentiles
     (p50/p95/p99/max), fail rate, check pass rate, threshold verdict, and
     the raw k6 JSON path — fixed report shape across repos for
     comparability. Question: can the agent generate *and execute* its own
     load tests? Validation: generated tests must recover the known ordering
     of the 4 controlled repos. **Tooling built Aug 29 (see §3); measured
     runs pending.**
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
| [`../run-experiment.sh`](../run-experiment.sh) | Build → k6 benchmark → report pipeline | **RE-POINTED (h2)**: `<target> [--docker]`; baseline/advanced MODE removed; JFR step joins in h3 |
| [`../jfr-diagnose.sh`](../jfr-diagnose.sh) | JFR hypothesis-driven diagnosis | current — h3; works on any .jfr path unchanged |
| `../benchmarks/k6.js`, `orchestrate.js`, `k6-report.js` | k6 template / native runner / reporter | k6.js **legacy** (superseded by `service/advanced/k6/template.js` + `gen-k6.py`); orchestrate + k6-report **re-pointed** at targets (h2) |
| `../docker-compose.benchmark.yml` | Original benchmark envelope | pre-existing, **untouched**; h2 stack lives in `service/advanced/docker/h2-*.yml` with the same limits |
| `01-scaffold-service.md`, `00-scaffold-reactive-service.md` | MVC / WebFlux+Redis scaffold references | legacy — from the practice problem; useful only as reference for the 4 controlled repos |
| `02–05-*.md` (CAS, idempotency, chaos, outbox) | Practice-problem patterns | legacy — out of scope (multi-service excluded) |
| `00-git-workflow.md` | Branch/commit workflow | current |

The old "ceiling experiment" and perf-tuning workflow from the practice
problem do not apply here — JFR/k6 are analysis tools pointed at *target*
repos, not optimization loops on our own service.
