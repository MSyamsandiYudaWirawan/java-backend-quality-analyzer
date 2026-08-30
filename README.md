# Java Backend Code Quality Analyzer — Hackathon Submission

> **Context:** micro1 Frontier Engineering Challenge. This repo contains a baseline solution and an advanced solution, with measured evidence for every experiment.

> **Pre-existing:** This repo was initialized from a personal hackathon template (prompts, benchmark scripts, CI skeleton). All solution code, tests, experiments, and evidence were built during the August 2026 event.

> **Branch:** `exp/h3-full-pipeline` — iteration 3 (**KEPT**). Built on `exp/h2-k6-generation`; this is the last experiment — the final workflow (`advanced`) is this branch's pipeline packaged.

---

## Tools Used

- **Kimi Code CLI** — local terminal agent (model: kimi-k3)
- **JFR / JMH / k6** — measurement and load testing
- **Testcontainers** — integration test infrastructure

## What Existed Before the Competition

This repo was initialized from a personal hackathon template built before the event. The following were **pre-existing**:

- `benchmarks/` — k6 load test template, k6 report generator, native-mode orchestrator
- `run-experiment.sh` — 4-step pipeline (build → benchmark → report → JFR diagnose)
- `jfr-diagnose.sh` — JFR hypothesis-driven diagnosis script
- `docker-compose.yml` + `docker-compose.benchmark.yml` — infrastructure and isolated benchmark stack
- `prompts/` — agent prompt templates and coding style guide
- `evidence/` folder structure and experiment report templates
- `CHECKLIST.md`, `IMPROVEMENTS.md`, `REPRODUCTION.md` — documentation scaffolding with placeholders
- `trajectories/` — trajectory capture structure and `save-traj.sh`

**Everything below was built during the August 2026 event:**

- `service/` — the baseline analyzer, the h1 collector + scoring wrapper, the h2 k6 generator + docker target stack, the shared rubric, the eval harness
- All filled-in values in README, IMPROVEMENTS.md, REPRODUCTION.md
- All experiment branches (`exp/h1-rubric-scoring`, `exp/h2-k6-generation`, `exp/h3-full-pipeline`)
- All evidence files (`evidence/baseline/`, `evidence/eval/`, `evidence/advanced/h1|h2|h3/`, `evidence/experiments/`)
- All agent trajectories in `trajectories/kimi-cli/`
- The solution video

---

## Problem & User

**User:** An engineering team evaluating a Java backend repository before an acquisition or merge. They did not build the code and must decide what it is worth before committing to a price.

**Bottleneck:** A README or working demo reveals little about actual code quality. The buyer must understand an unfamiliar codebase, run its build and tests, inspect architecture and dependencies, and assess technical debt and runtime behavior. Manual review is slow, inconsistent between reviewers, and routinely misses runtime performance and structural problems. Without a repeatable method, the valuation rests on incomplete, biased judgment.

**Why it matters:** A bad repository decision costs real engineering time and acquisition money. An objective, evidence-backed quality score — where every point traces to a file, a test result, or a profiler recording — reduces reviewer bias and makes the assessment reproducible by a second person.

---

## Baseline Solution (the control)

A naive shell-script analyzer: `service/baseline/analyze.sh`. Five shallow yes/no checks (README 10 / `pom.xml` 10 / tests present 20 / `mvn package` 25 / `mvn test` 35) summed into a 0–100 score.

**Measured:** spring-petclinic @ `818c413` → 100/100 (`evidence/baseline/spring-petclinic/`); full eval set vs expert ranking v1 → **ρ = 0.811**, NOT ROBUST (5-way tie at 90 spanning expert ranks 2–8; 11 of 45 pairs unjudged; tie bounds [0.527, 0.915]; P(ρ ≥ 0.811 by luck) ≈ 29%) — `evidence/eval/baseline/eval-report.md`. The blindness is intentional: it is the control.

---

## This Branch: H3 — JFR Profiling During the Generated Load (KEPT)

The third capability completes the pipeline: k6 says *how fast*, not *why* — a service can post high RPS with a critical hotspot underneath. h3 records **JFR during the h2-generated load** and grades the rubric's Runtime dimension on **k6 + JFR together**.

The pipeline:

1. **Recording** — `./run-experiment.sh <target> --docker --jfr`: the service boots with `-XX:StartFlightRecording` (in-memory + `dumponexit=true`, via the compose `JFR_OPTS` seam), the same committed k6 script and 200-VU profile run against it, then the service is SIGTERMed so the JVM finalizes `profile.jfr` (the temurin JRE image has no `jcmd` — live dumps are not an option). `jfr-diagnose.sh` produces the hypothesis-driven report. All h3 outputs land in `evidence/advanced/h3/<repo>/`; the h2 scripts/slots are never rewritten.
2. **Blind JFR scoring** — a uniform **0–10 jfrProfile rubric pre-registered before applying it to any repo** (10 clean request path / 6 one concerning non-dominant mechanism / 4 one critical request-path mechanism / 2 multiple compounding critical mechanisms / 0 unmeasurable). Only the jfrProfile item is re-scored — everything else stays as committed in the h1 sheets + h2 runtime extension.
3. **The grading rule** — strong throughput with a critical JFR signal scores *lower* than modest throughput with a clean profile.
4. **NOT_TESTABLE repos get no h3 run** (human decision) — they stay Runtime = 0 citing the h2 findings.

**Measured (headline):** Spearman ρ vs. expert ranking v2 on the 10-repo eval set: **h2 0.954 → h3 0.973** (`evidence/eval/h3/eval-report.md`; full record: `evidence/experiments/h3-full-pipeline.md`). Both pre-registered KEPT criteria met — ρ did not degrade beyond tie-bound overlap, and the petclinic collapse carries a named JFR signal. All **4/4 pre-registered predictions confirmed**:

- **The petclinic collapse is explained.** spring-petclinic (baseline 100/100) collapses on ONE global monitor: the fat-jar classloader's `UrlJarFiles$Cache` — **71,193 of 71,738 monitor events, p95 407ms**; ThreadPark p95 1000ms; SocketRead ~9 events (H2 in-memory DB); GC 34 pauses p99 137ms (minor). Request threads serialize on nested-jar resource resolution (Thymeleaf) — exactly the queueing mechanism predicted from h2's checks-100% failure. petclinic-degraded replicates it exactly (74,682 events, p95 397ms) — byte-identical runtime code, control confirmed (`evidence/advanced/h3/spring-petclinic/`).
- **The caffeine gap is visible in DB SocketReads**: practice-mvc 6,859 reads for ~67k requests vs caffeine 5,524 for ~149k — ~2.7x fewer reads per request, per-read latency unchanged. Caching eliminates reads; it does not speed up the DB.
- **The webflux pair is clean of blocking** (2 and 4 monitor events, idle-pool parks only) → jfrProfile 10/10 each.
- **The grading rule earns its keep**: REST-module6 **PASSed k6** (1219 rps, p95 312ms) **with a CRITICAL JFR signal** (5,018 monitor events p95 1310ms — Tomcat RecycledProcessors + shared HashMap) → 4/10, held to a tie with clean-profiled webflux-redis instead of rising above it.

Harness-level: tie bounds [0.964, 0.976]; pairs **42 concordant / 2 discordant / 1 tied** (h2: 41/3/1); the h2 mvc/degraded tie broke in the expert's direction (69 > 67; expert 6 > 8).

> ⚠️ Caveats: n=10 makes ρ coarse — tie bounds are reported with every headline. **The diagnosis template's severity labels were NOT used as scores**: its p95-based thresholds mark even 2 monitor events "CRITICAL"; scoring weighed count × duration on the request path instead (webflux's 2 events = clean; petclinic's 71,738 = collapse). Envelope-normal GC (p99 87–137ms on the 2-CPU G1 envelope, all repos) carries no deduction. JFR overhead (~1–2% for settings=profile) means h3 k6 numbers may differ trivially from h2's; scoring cites the h3 run's own report.

### How to run

```bash
# Measured run with JFR (committed k6 script, fixed docker envelope):
./run-experiment.sh <repo-url-or-path> --docker --jfr
# → evidence/advanced/h3/<repo>/{profile.jfr, jfr/diagnosis-report.md, load-report.*}

# Reproduce the headline numbers from committed artifacts (seconds):
python service/eval/evaluate.py --label h3 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h3
# Expected: "Spearman rho vs expert ranking: 0.973 (n=10)"
```

Full setup, versions, and expected output: [`REPRODUCTION.md`](REPRODUCTION.md).

---

## The Failure That Shaped H3

**JFR recordings silently dying on Windows Docker Desktop.** The first h3 runs failed at container start: with `disk=true`, JFR streams recording chunks during the run, and that write mechanism fails on Docker Desktop's Windows bind mount — the JVM aborts at init. A second, subtler instance followed: Git Bash rewrote the exported `JFR_OPTS` POSIX path (`/jfr-repo/...`) into a Windows path when the pipeline spawned docker.exe — the fourth occurrence of this path-mangling bug class in the project.

**Fix:** in-memory recording + `dumponexit=true` (the finished file is written once, on graceful shutdown — a plain write the mount tolerates), and `MSYS_NO_PATHCONV=1` on every compose invocation. Also pinned: `Dockerfile.target` moved to `eclipse-temurin:21-jre-jammy` after the floating tag moved 21.0.11 → 21.0.12 between h2 and h3. Full story: `trajectories/kimi-cli/2026-08-29_17-10-h3-jfr-tooling.md`.

---

## Eval Set

The 10-repo evaluation set is composed of public repos, one synthetic degraded fork, and four self-authored controlled repos (`service/targets.txt` is the authoritative record, incl. validation results, pins, and dropped candidates). Scores below are committed in `evidence/eval/{baseline,h1,h2,h3}/eval-report.md`:

| # | Repo | Type | Expert (v2) | Baseline | h1 | h2 | h3 |
|---|------|------|:-----------:|:--------:|:--:|:--:|:--:|
| 1 | spring-projects/spring-petclinic | public good | 1 | 100 | 72 | 82 | 84 |
| 2 | practice-webflux-redis | self-authored controlled | 2 | 90 | 57 | 72 | 82 |
| 3 | eugenp/REST-With-Spring (module6, pinned clone @ `9c06a66`) | public multi-module | 3 | 100 | 63 | 78 | 82 |
| 4 | practice-webflux | self-authored controlled | 4 | 90 | 56 | 71 | 81 |
| 5 | practice-mvc-caffeine | self-authored controlled | 5 | 90 | 55 | 70 | 76 |
| 6 | practice-mvc | self-authored controlled | 6 | 90 | 55 | 65 | 69 |
| 7 | spring-guides/gs-rest-service-complete (pinned clone @ `2ef8e28`) | public weak skeleton | 7 | 90 | 50 | 50 | 50 |
| 8 | MSyamsandiYudaWirawan/petclinic-degraded | synthetic bottom (fork) | 8 | 55 | 55 | 65 | 67 |
| 9 | spring-projects/spring-mvc-showcase | public legacy, archived | 9 | 40 | 26 | 26 | 26 |
| 10 | RameshMF/springboot-blog-rest-api | public average, tutorial-grade | 10 | 65 | 42 | 42 | 42 |
| | **Spearman ρ** | | | **0.811** (v1) | **0.865** (v1) / **0.939** (v2) | **0.954** (v2) | **0.973** (v2) |
| | Tie bounds | | | [0.527, 0.915] | [0.835, 0.929] / [0.894, 0.965] | [0.939, 0.964] | [0.964, 0.976] |
| | Pairs (concord./discord./unjudged) | | | 31/3/11 | 37/5/3 / 39/3/3 | 41/3/1 | 42/2/1 |

Expert ranking v2 (`service/eval/expert-ranking.txt`, committed in place since the h2 stage): blog-rest-api moved 6th → 10th on the verified committed JWT secret; petclinic-degraded kept at its v1 relative position (its failures are intentionally injected — design intent is not a code property). Ruling: `evidence/experiments/expert-ranking-v2-decision.md`.

**Disclosure:** The four practice repos are self-authored services built before the event to test the benchmark pipeline, included because they provide a known ground-truth runtime ordering — the only repos the expert ranked on measured runtime knowledge. The analyzer recovered that ordering from its own measurements; the agent scored blind, from load reports and JFR diagnosis reports only, never the expert ranking (`evidence/experiments/h3-full-pipeline.md`). The expert ranking basis and justifications: `evidence/expert-ranking-notes.md`.

---

## Hot Take

> **Static review can't see the failures that matter.** The eval set's most polished repo — the one every structural check loves, the baseline's 100/100 — is its worst runtime performer, collapsing on a fat-jar classloader lock that only appears under real concurrency. And the signal everyone expects to find in a Java profile, GC, explained nothing in seven out of seven recordings. If your quality assessment doesn't boot the repo and put it under load, you're grading the README.

---

## Architecture Trade-offs

| What we gained | What we gave up |
|----------------|-----------------|
| Causal evidence, not just symptoms: the petclinic collapse has a named mechanism (fat-jar classloader lock), and the k6-vs-JFR grading rule held a k6-PASS repo (module6) down to its evidence | More moving parts: recording in-container, graceful-stop finalization (no `jcmd` in the JRE image), and a Windows-only failure mode (bind-mount chunk writes) that needed an in-memory workaround |
| One re-scored item (jfrProfile), pre-registered 0–10 rubric — h1/h2 sheets and evals stay reproducible in place | The diagnosis template's severity labels are uncalibrated defaults — usable as pointers, not as scores, so scoring re-weighs the raw events |
| The same committed load profile under JFR = the recording describes the exact window the k6 numbers came from | ~1–2% JFR overhead and environment-sensitive re-runs: measured numbers drift with host hardware (the committed artifacts are the record) |

---

## Reproduction

See [`REPRODUCTION.md`](REPRODUCTION.md) for exact setup commands, versions, and expected output.

## Improvement Changelog

See [`IMPROVEMENTS.md`](IMPROVEMENTS.md) for every meaningful iteration with evidence, measured deltas, and keep/reject decisions.

## Code Style

See [`prompts/TIGERSTYLE.md`](prompts/TIGERSTYLE.md) for the coding principles enforced on all generated code.

---

## Qualification Gate Checklist

A submission is scored only after it passes completeness, integrity, trace, and reproducibility checks. Before submitting, verify:

- [ ] `baseline` branch passes all unit and integration tests
- [ ] `advanced` branch passes all unit and integration tests
- [ ] Every experiment branch exists and is documented in `IMPROVEMENTS.md`
- [ ] `evidence/` contains analysis reports (markdown + JSON) for baseline and advanced across the eval repos, plus JFR/k6 recordings for repos where runtime profiling was used
- [ ] `REPRODUCTION.md` commands run successfully on a clean environment
- [ ] Trajectories exported for every major agent session in `trajectories/kimi-cli/`
- [ ] 5-minute video recorded and under 5 minutes
- [ ] Root README clearly states tools used and what was built during the event
