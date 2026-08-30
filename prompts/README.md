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

## 3. Current State (Aug 29 ~19:00 +07 — ALL EXPERIMENTS KEPT, PACKAGING DONE; next: refinement)

Branch: `advanced` (created at the `exp/h3-full-pipeline` tip — chained
KEPT branches, so it IS baseline + h1 + h2 + h3). **The project is
feature-complete: h1 KEPT (ρ 0.865), h2 KEPT (0.954), h3 KEPT (0.973 vs
v2; baseline 0.811 v1 / 0.850 v2).** Packaging complete: 4-stage eval
table + details in IMPROVEMENTS.md, README filled, REPRODUCTION final
(every command verified — `--resume` reproduces 0.973 in <10s), video
script filled, full unit suite green on `advanced`, trajectories 1–18
indexed. New artifact: `evidence/eval/baseline-v2/` (original baseline
scores re-ranked vs v2, no re-measurement: 0.850, still NOT ROBUST).

**Remaining (human):** record the video; set `advanced` as the default branch
when pushing (no remote yet; `master` renamed to `template/init` in the
refinement pass); final submission checklist at README bottom.

### NEXT SESSION — refinement (polish, no new capabilities)

The pipeline works end to end and all numbers are committed. Refinement =
making the tooling sharper WITHOUT invalidating committed evidence. Rule:
any change that alters measured numbers requires re-running affected
evidence on a new branch; pure tooling/UX/doc fixes can go on `advanced`.
Known rough edges, most valuable first:

1. **jfr-diagnose severity labels are too liberal** — p95-only thresholds
   mark 2 monitor events "CRITICAL" (webflux). h3 scoring had to reason
   around the labels (count × duration on the request path). Fix the
   thresholds/labels in `jfr-diagnose.sh` so reports read honest without
   interpretation; keep the committed h3 reports as-is (they're evidence,
   warts documented in trajectory 17).
2. **ThreadPark interpretation** — idle-pool parks (SynchronousQueue
   handoff, 30s+ waits) drown the request-path signal. Filter/classify
   parks by business frame (the `park_sorted.txt` machinery exists) so
   "request threads parked" is a first-class metric.
3. **k6 generator ceiling caveat** — k6 container has 1 CPU; caffeine's
   2168 rps may be generator-capped, compressing the top end. Either
   measure the generator's ceiling (hello-world target) or document the
   bound quantitatively in the reports.
4. **Giant JFR dump txts** — `locks.txt` hit 250 MB (71k events ×
   stack-depth 32). Cap stack depth or sample events in jfr-diagnose for
   high-count event types; diagnosis quality won't change.
5. **Mojibake in h2-committed score-sheet notes** — double-encoded
   em-dashes (`â€"`) from a Windows locale bug; cosmetic, fix in place
   (scores/structure untouched) or leave and document.
6. ~~**Hollow local clones**~~ DONE — `targets/spring-petclinic` and
   `targets/springboot-blog-rest-api` (empty git inits from failed clones)
   were deleted in the refinement pass; URL invocation remains the working
   path (and how all measured runs happened).
7. **Native-mode JFR** — `--jfr` is docker-only (orchestrate.js has no
   JAVA_OPTS wiring); either wire it or remove native mode from the docs.
8. **Dual-profile scoring** — h2 kept 50-VU + 200-VU reports, but the
   JFR item used only the 200-VU window. If refined, record BOTH profiles
   with JFR and grade efficiency vs stress separately.

Orientation for the session: sanity suite is the command block below;
state of every experiment is in `evidence/experiments/h[N]-*.md`; the
score-of-record per repo is `evidence/advanced/h1/*/score-sheet.json`;
eval history is `evidence/eval/{baseline,baseline-v2,h1,h1-v2,h2,h3}/`.
Working agreements in §6 still apply (trajectory per work block, tests
on every branch, no claim without evidence).

**h2 evidence (kept, see git log for full detail):**
- **Dual profile** (human decision): 50-VU efficiency runs preserved at
  `evidence/advanced/h2-50vus/<repo>/`; 200-VU stress runs at
  `evidence/advanced/h2/<repo>/`. 50 VUs kept every repo far from its
  saturation knee (vacuous thresholds), so the profile was raised BEFORE
  any evidence was committed. Otherwise identical fixed profile: 10s ramp
  + 60s hold, 10% creates / 90% reads of 50 seeded entities, thresholds
  p95<500ms / err<1% / checks>95%.
- 200-VU results: practice-mvc **FAIL** (p95 646ms — blocking stack chokes
  while its caffeine sibling PASSes at 2168 rps), webflux PASS (1031 rps),
  webflux-redis PASS (1448 rps, tightest tail max 382ms), module6 PASS
  (1288 rps), spring-petclinic **FAIL** (234 rps, p95 2191ms, max 8111ms —
  the baseline-100 repo saturating), petclinic-degraded **FAIL**
  (240 rps, p95 2105ms — statistically identical to petclinic, consistent
  with byte-identical runtime code). Checks 100% everywhere: differences
  are queueing/latency, not errors.
- NOT_TESTABLE findings (Runtime = 0 by policy §5): blog-rest-api (boot
  crash on stock MySQL 8.4 — "Public Key Retrieval is not allowed",
  `boot-diagnosis.log`; JWT wall beyond), gs-rest-service-complete (no
  create endpoint exists), spring-mvc-showcase (build fails on Java 21,
  javax.xml.bind; `build.log`).
- New generator capability: `scenario` slot — `form` variant
  (`template-form.js`: form POST → 302 → id from Location-header regex →
  HTML read) makes petclinic-class apps measurable; `jarGlob` slot pins
  the boot jar in multi-module repos (module6's largest jar was the wrong
  module). Pipeline fixes mid-pilot: `MSYS_NO_PATHCONV=1` on compose runs
  (third path-mangling instance), k6 `.values` summary nesting.
- Caveat for scoring: k6 container has 1 CPU; mvc-caffeine's 2168 rps may
  approach the generator's ceiling, compressing the top end.

Commits: `bc9212f` (form+jarGlob tooling), `e401654` (slots+scripts),
`402f6ac` (pilot fixes), `3f791ee` (trajectory); h3 commits `d16809e`
(tooling + hypothesis), `8124f93` (JFR fixes + petclinic evidence),
`d8656ac`/`094437b` (batches 1–2); scoring + eval + this state update
committed after this note — see git log.

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

**Environment notes:** `practice-postgres` + `practice-redis` containers are
currently RUNNING (started for the webflux-redis live verification; the h2/h3
docker pipeline binds no host ports so they cannot interfere with measured
runs — but remember the port-5432 incident before any NATIVE test/k6 run).
practice-mvc and
mvc-caffeine tests need Postgres on localhost:5432 (only their ITs use
Testcontainers). blog-rest-api crashes at boot on stock MySQL 8.4 (see its
h2 finding) in addition to needing an undeclared MySQL for tests.

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
     of the 4 controlled repos. **Measured runs DONE Aug 29 (dual 50/200-VU
     profile, see §3); Runtime scoring + eval pending in fresh session.**
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
| `00-git-workflow.md` | Branch/commit workflow | current |

The legacy practice-problem scaffolds (`00-scaffold-reactive-service.md`,
`01-scaffold-service.md`, `02–05-*.md`) were removed in the refinement pass;
they remain reachable via git history / the `template/init` snapshot.

The old "ceiling experiment" and perf-tuning workflow from the practice
problem do not apply here — JFR/k6 are analysis tools pointed at *target*
repos, not optimization loops on our own service.
