# Java Backend Code Quality Analyzer — Hackathon Submission

> **Context:** micro1 Frontier Engineering Challenge. This repo contains a baseline solution and an advanced solution, with measured evidence for every experiment.

> **Pre-existing:** This repo was initialized from a personal hackathon template (prompts, benchmark scripts, CI skeleton). All solution code, tests, experiments, and evidence were built during the August 2026 event.

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

- `service/` — all solution code (baseline and advanced)
- All filled-in values in README, IMPROVEMENTS.md, REPRODUCTION.md
- All experiment branches (`exp/h1-rubric-scoring`, `exp/h2-k6-generation`, `exp/h3-full-pipeline`) and the `advanced` final branch
- All evidence files (`evidence/eval/`, `evidence/advanced/`, `evidence/experiments/`, `evidence/baseline/`)
- All agent trajectories in `trajectories/kimi-cli/`
- The solution video

---

## Problem & User

**User:** An engineering team evaluating a Java backend repository before an acquisition or merge. They did not build the code and must decide what it is worth before committing to a price.

**Bottleneck:** A README or working demo reveals little about actual code quality. The buyer must understand an unfamiliar codebase, run its build and tests, inspect architecture and dependencies, and assess technical debt and runtime behavior. Manual review is slow, inconsistent between reviewers, and routinely misses runtime performance and structural problems. Without a repeatable method, the valuation rests on incomplete, biased judgment.

**Why it matters:** A bad repository decision costs real engineering time and acquisition money. An objective, evidence-backed quality score — where every point traces to a file, a test result, or a profiler recording — reduces reviewer bias and makes the assessment reproducible by a second person.

---

## Baseline Solution

A naive shell-script analyzer: `service/baseline/analyze.sh`. No AI, no deep analysis. For a target Java repo it checks five shallow yes/no signals and sums them into a 0–100 score:

| Check | Weight |
|-------|--------|
| README present | 10 |
| Maven build file (`pom.xml`) | 10 |
| Tests present under `src/test` | 20 |
| `mvn package` succeeds | 25 |
| `mvn test` passes | 35 |

**Measured:** spring-petclinic @ `818c413` → **100/100** (`evidence/baseline/spring-petclinic/`).

The baseline is intentionally naive — it saturates on any well-formed repo and cannot distinguish "compiles and has tests" from "well-architected, low-debt, performant under load". This scoring ceiling is the control against which all experiments are judged.

---

## Advanced Solution

An agent workflow (Kimi Code CLI) that analyzes a target Java backend end to end:

1. **Clone + build** the target (Maven, Java 21; infra addendums for Postgres/MySQL/Redis where the repo needs them).
2. **Full test evidence** — parsed surefire results: counts, failures, not a pass/fail bit.
3. **Agent-generated load testing** — k6 scripts generated from the target's API surface (template+slots, fixed profile, smoke-gated), executed in a resource-limited docker envelope (`run-experiment.sh <target> --docker`).
4. **Runtime profiling** — JFR recording during the generated load (`--jfr`), diagnosed by `jfr-diagnose.sh`: lock contention, blocking I/O, GC, allocation.
5. **Architecture & dependency health** — layering, MVC vs WebFlux, outdated/risky dependencies.
6. **Evidence-linked report** — every score traces to a file, test result, or profiler recording; scored against a fixed rubric shared with the human expert.

**Measured:** Spearman ρ vs. human-expert ranking on the 10-repo eval set: **baseline ρ = 0.811 → advanced ρ = 0.973** (`evidence/eval/baseline/`, `evidence/eval/h3/`; same scores re-ranked against the v2 ranking: 0.850 → 0.973). Co-primary: findings the baseline missed — spring-petclinic (baseline 100/100) collapses at 200 VUs on a fat-jar classloader lock (`evidence/advanced/h3/spring-petclinic/`); blog-rest-api boot-crashes on stock MySQL 8.4. Secondary: unjudged ranking pairs 11 → 1 of 45; every score cites a file, load report, or JFR recording.

> ⚠️ Caveats: n=10 makes ρ coarse — one repo moving a rank swings it (tie bounds reported with every headline: h3 [0.964, 0.976]). The baseline's 0.811 is itself luck-sensitive (24% of pairs unjudged, NOT ROBUST stamp). The expert ranking is one senior reviewer using the same rubric; a v1→v2 revision was pre-authorized and executed once, with justification, when runtime evidence contradicted v1 (`evidence/expert-ranking-notes.md`).

### Scope & Limitations

- **Single deployable unit only.** The runtime pipeline (k6 + JFR) measures one bootable service — the target itself or its gateway. Multi-service architectures (Kafka topologies, outbox patterns, microservice meshes) are analyzed with static signals only; we deliberately do not spin up multi-service harnesses, and reports say so plainly rather than faking coverage.
- **Runtime evidence is bounded by deployability.** A repo that cannot be built and booted as a service (libraries, broken builds, ungeneratable load scenarios) scores 0 on the Runtime dimension with an explicit note — that absence is itself a finding for a backend being acquired, not a skipped checkbox.
- **Load scenarios are agent-generated, then frozen.** k6 scripts are generated from the target's API surface against a fixed scenario standard (mixed create→read, fixed VU/duration profile across all repos), smoke-validated, and committed as evidence. Re-runs use the committed artifact, so measurements are reproducible even though authoring is agentic.



**JFR recordings silently dying on Windows Docker Desktop.** The first h3 runs failed at container start: with `disk=true`, JFR streams recording chunks during the run, and that write mechanism fails on Docker Desktop's Windows bind mount — the JVM aborts at init ("not able to write to file"). A second, subtler instance followed: Git Bash rewrote the exported `JFR_OPTS` POSIX path (`/jfr-repo/...`) into a Windows path when the pipeline spawned docker.exe — the fourth occurrence of this path-mangling bug class in the project.

**Fix:** in-memory recording + `dumponexit=true` (the finished file is written once, on graceful shutdown — a plain write the mount tolerates), and `MSYS_NO_PATHCONV=1` on every compose invocation. Both verified by manual container repro before re-running; full story in `trajectories/kimi-cli/2026-08-29_17-10-h3-jfr-tooling.md`.

---

## Eval Set

The 10-repo evaluation set is composed of public repos, one synthetic degraded fork, and four self-authored controlled repos (`service/targets.txt` is the authoritative record, incl. pins):

| # | Repo | Type | Purpose |
|---|------|------|---------|
| 1 | spring-projects/spring-petclinic | public good | Boots with H2, scored 100/100 by baseline — saturation demo; h3's headline runtime finding |
| 2 | MSyamsandiYudaWirawan/petclinic-degraded | synthetic bottom | Ground-truth anchor; byte-identical runtime code to #1 — its identical JFR signature is a control |
| 3 | spring-guides/gs-rest-service-complete | public weak | Official skeleton; exposes only GET /greeting — NOT_TESTABLE finding (no create endpoint) |
| 4 | RameshMF/springboot-blog-rest-api | public average | Tutorial-grade full app; boot-crashes on stock MySQL 8.4 + committed JWT secret — bottom-ranked by v2 ruling |
| 5 | spring-projects/spring-mvc-showcase | public legacy | Archived XML config; build fails on Java 21 (javax.xml.bind) — NOT_TESTABLE finding |
| 6 | eugenp/REST-With-Spring (module6 branch) | public multi-module | javax-era course app @ 9c06a66; pinned local clone (default branch has no build file); jarGlob pins the boot module |
| 7 | practice-mvc | self-authored | Controlled baseline: plain Spring MVC + JPA, no cache |
| 8 | practice-mvc-caffeine | self-authored | Controlled mid: same MVC app + Caffeine cache — isolates caching at runtime |
| 9 | practice-webflux | self-authored | Controlled mid: WebFlux + R2DBC, no cache |
| 10 | practice-webflux-redis | self-authored | Controlled top: WebFlux + Redis — known best runtime |

**Disclosure:** Repos 7–10 are self-authored practice services built before the event to test the benchmark pipeline. They are included because they provide known ground-truth runtime rankings (mvc < mvc-caffeine at throughput, webflux stacks clean of blocking signals). The analyzer recovered this ordering from its own measurements only — the expert ranked these four on measured runtime knowledge, the agent scored them blind (`evidence/expert-ranking-notes.md`).

**Why 10 repos?** The brief's own bar is "ten or more cases... when the task allows it" — and this task's cases are expensive by design:

- **Each case is measured, not scanned.** Every repo costs a real boot + build + 70s load + JFR profile (~6–9 min machine time) plus blind agent scoring — and the ground truth itself (a qualified expert ranking per repo) scales linearly with n. Ten deeply-measured repos beat fifty shallowly-scanned ones for a quality metric.
- **The set is stratified, not sampled.** It deliberately covers the archetypes a buyer meets: a reference standard (petclinic), a synthetic bottom with a byte-identical runtime twin as control (degraded), a controlled ordering quartet for method validation (7–10), a legacy fail-fast (showcase), a multi-module repo (module6), and two NOT_TESTABLE cases. The required "one challenging case" is petclinic itself — the baseline's 100/100 that collapses under load.
- **ρ is coarse at n=10 — so it is never reported alone.** The harness emits tie bounds, unjudged-pair counts, and a NOT ROBUST stamp when >20% of pairs are ties (the baseline is stamped; the advanced workflow is not). The co-primary metric is per-repo findings traced to evidence, which does not depend on n.
- **Reproducibility is a feature of small n.** A judge can re-verify the full eval set in minutes with `--resume`; a 50-repo set would be its own barrier to checking our work.

---

## Hot Take

> **Static review can't see the failures that matter.** The eval set's most polished repo — the one every structural check loves — is its worst runtime performer, collapsing on a classloader lock that only appears under real concurrency. And the signal everyone expects to find in a Java profile (GC) explained nothing in seven out of seven recordings. If your quality assessment doesn't boot the repo and put it under load, you're grading the README.

---

## Architecture Trade-offs

| What we gained | What we gave up |
|----------------|-----------------|
| Measured runtime evidence (k6 + JFR) that breaks structural ties — ρ 0.811 → 0.973 | Wall-clock: a full advanced analysis is minutes per repo (build + 70s load + diagnosis), not the baseline's seconds |
| Reproducibility from committed artifacts (frozen k6 scripts, committed score sheets, fixed docker envelope) | Agent authoring is not reproducible — only its artifacts are; regeneration is forbidden, re-runs use committed scripts |
| Honest findings over coverage theater (NOT_TESTABLE = Runtime 0 with a root-cause note) | 3 of 10 repos get no runtime score at all — the report says "we could not measure this" instead of faking a number |
| One fixed load profile everywhere = fair cross-repo comparison | No per-repo tuning: some apps are measured away from their real saturation knee, and the 1-CPU k6 container may cap the top end |

---

## Reproduction

See [`REPRODUCTION.md`](REPRODUCTION.md) for exact setup commands, versions, and expected output. For a structural map of the repo itself, see [`Documentation.md`](Documentation.md).

## Improvement Changelog

See [`IMPROVEMENTS.md`](IMPROVEMENTS.md) for every meaningful iteration with evidence, measured deltas, and keep/reject decisions.

## Code Style

See [`prompts/TIGERSTYLE.md`](prompts/TIGERSTYLE.md) for the coding principles enforced on all generated code.

---

## Qualification Gate Checklist

A submission is scored only after it passes completeness, integrity, trace, and reproducibility checks. Before submitting, verify:

- [x] Baseline analyzer reproducible from `advanced` (committed evidence + `--resume` eval match; see REPRODUCTION.md) — verified: `--resume` reproduces baseline-v2 0.850, h1-v2 0.939, h2 0.954, h3 0.973 exactly
- [x] `advanced` branch passes the unit test suite (baseline 9, collect 19, analyze-h1 5, spearman 22, gen_k6 31, k6-report 16, run-experiment 9 — all green; no integration suite exists, `tests/integration/` is a documented placeholder)
- [x] Every experiment branch exists and is documented in `IMPROVEMENTS.md` (`exp/h1-rubric-scoring`, `exp/h2-k6-generation`, `exp/h3-full-pipeline`, `advanced`; the baseline control runs from any branch — no dedicated branch by design)
- [x] `evidence/` contains analysis reports (markdown + JSON) for baseline and advanced across the eval repos, plus committed k6 JSON/reports and JFR diagnosis reports for runtime-profiled repos (raw `.jfr` binaries are gitignored by design — they regenerate via `run-experiment.sh <target> --docker --jfr`)
- [x] `REPRODUCTION.md` commands run successfully on a clean environment (every command verified during packaging; `--resume` set re-verified on all branches in the refinement pass)
- [x] Trajectories exported for every major agent session in `trajectories/kimi-cli/` (1–19 indexed, incl. the Day-2 refinement session)
- [ ] 5-minute video recorded and under 5 minutes
- [x] Root README clearly states tools used and what was built during the event
