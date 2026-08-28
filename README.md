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

[Tech stack: e.g., Spring MVC + JPA + PostgreSQL.]

- `POST [ENDPOINT]` — [what it does]
- `GET [ENDPOINT]` — [what it does]

**Measured:** [RPS] req/s, p95 latency [X]ms, [Y]% errors.

The baseline is intentionally naive — it passes functional tests but makes no performance concessions. This is the control against which all experiments are judged.

---

## Advanced Solution

[Tech stack: e.g., WebFlux + R2DBC + Redis cache.]

**What changed:**
1. **[Change 1]:** [One sentence description.]
2. **[Change 2]:** [One sentence description.]
3. **[Change 3]:** [One sentence description.]

**Measured:** [RPS] req/s, p95 latency [X]ms, [key JFR metric delta].

> ⚠️ [Add any caveats about benchmark conditions here.]

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
- [ ] `evidence/` contains JFR recordings and k6 results for both baseline and advanced
- [ ] `REPRODUCTION.md` commands run successfully on a clean environment
- [ ] Trajectories exported for every major agent session in `trajectories/kimi-cli/`
- [ ] 5-minute video recorded and under 5 minutes
- [ ] Root README clearly states tools used and what was built during the event
