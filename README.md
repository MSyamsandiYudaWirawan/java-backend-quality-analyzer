# Java Backend Code Quality Analyzer — Hackathon Submission

> **Context:** micro1 Frontier Engineering Challenge. This repo contains a baseline solution and an advanced solution, with measured evidence for every experiment.

> **Pre-existing:** This repo was initialized from a personal hackathon template (prompts, benchmark scripts, CI skeleton). All solution code, tests, experiments, and evidence were built during the August 2026 event.

---

## Tools Used

- **Kimi Code CLI** — local terminal agent (model: kimi-k2-0711)
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
- All experiment branches (`experiment/h*`)
- All evidence files (`evidence/*.jfr`, `evidence/k6-*.json`, `evidence/*/diagnosis-report-*.md`)
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

1. **Clone + build** the target (Testcontainers for isolated infra where needed).
2. **Full test evidence** — parsed surefire results: counts, failures, coverage trend, not a pass/fail bit.
3. **Runtime profiling** — k6 load test + JFR recording of the *target* repo, via the pre-existing `run-experiment.sh` / `jfr-diagnose.sh` pipeline.
4. **Architecture & dependency health** — layering, MVC vs WebFlux, outdated/risky dependencies.
5. **Evidence-linked report** — every score traces to a file, test result, or profiler recording; scored against a fixed rubric shared with the human expert.

**Measured:** [Spearman ρ vs. human-expert ranking on the 10-repo eval set: baseline ρ = X → advanced ρ = Y. Secondary: findings per repo, evidence traceability, wall-clock time per analysis.]

> ⚠️ [Add caveats about eval-set size and ranking methodology here.]

---

## Key Failure Mode

**[Failure name].** [Describe the subtle failure you encountered and how you fixed it. Be specific about the root cause and the solution.]

**Fix:** [Describe the fix.]

---

## Hot Take

> **[Your opinionated conclusion about what actually mattered.]** [e.g., "Micro-optimizations are a trap. The real bottleneck was 6 orders of magnitude larger — DB round-trips. If your optimization target isn't visible in the JFR flame graph, you're optimizing noise. Measure first, benchmark second."]

---

## Architecture Trade-offs

| What we gained | What we gave up |
|----------------|-----------------|
| [Gain 1] | [Cost 1] |
| [Gain 2] | [Cost 2] |
| [Gain 3] | [Cost 3] |

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
