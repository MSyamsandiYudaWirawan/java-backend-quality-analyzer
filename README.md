# Java Backend Code Quality Analyzer — Hackathon Submission

> **Context:** micro1 Frontier Engineering Challenge. This repo contains a baseline solution and an advanced solution, with measured evidence for every experiment.

> **Pre-existing:** This repo was initialized from a personal hackathon template (prompts, benchmark scripts, CI skeleton). All solution code, tests, experiments, and evidence were built during the August 2026 event.

> **Branch:** `exp/h1-rubric-scoring` — iteration 1 (**KEPT**). Built on the `baseline` stage; later experiments (`exp/h2-*`, …) and the final workflow (`advanced`) build on this one.

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

- `service/` — the baseline analyzer, the h1 collector + scoring wrapper, the shared rubric, the eval harness
- All filled-in values in README, IMPROVEMENTS.md, REPRODUCTION.md
- All experiment branches (`exp/h1-rubric-scoring`, …)
- All evidence files (`evidence/baseline/`, `evidence/eval/`, `evidence/advanced/h1/`, `evidence/experiments/`)
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

## This Branch: H1 — Agent Rubric Scoring on Collected Evidence (KEPT)

The first capability added on top of the baseline: replace binary checks with agent judgment over mechanically-collected facts, scored against the shared rubric (`service/rubric/quality-rubric.md`, 100 pts: Build & Test 25, Architecture 20, Dependencies 15, Runtime 25, Maintainability 15).

The pipeline:

1. **Mechanical collection** — `service/advanced/collect.sh` gathers facts only, no judgments: build/test logs, parsed surefire summary, test census (files/LOC/assertions), package tree, top-20 classes by LOC, `dependency:analyze` + `dependency:list`, repo scan (README/license/config/binaries/secrets).
2. **Blind agent scoring** — the agent reads only the collected evidence (never the expert ranking) and scores each rubric item **with per-item citations** to the evidence files. Score sheets are committed: `evidence/advanced/h1/<repo>/score-sheet.json`.
3. **Thin harness wrapper** — `service/advanced/analyze-h1.sh` validates the committed sheet and emits `h1-score.json`. No re-scoring at eval time: eval runs are fast and reproducible.
4. **Runtime = 0 uniformly** for all repos (a uniform "not yet measured" rule) so the missing capability cannot distort ρ — 25 rubric points deliberately left dark for later experiments.

**Measured (headline):** Spearman ρ vs. expert ranking v1 on the 10-repo eval set: **baseline 0.811 → h1 0.865** (`evidence/eval/h1/eval-report.md`; full record: `evidence/experiments/h1-rubric-scoring.md`). The substance is in the checks the harness reports alongside ρ:

- The baseline's **5-way tie at 90 is broken** — those repos now span 50–63, each point cited to collector artifacts.
- **Unjudged pairs 11 → 3** of 45 (37 concordant / 5 discordant); tie bounds tighten [0.527, 0.915] → **[0.835, 0.929]** — no NOT ROBUST stamp.
- The remaining 3-way tie at 55 (practice-mvc / mvc-caffeine / petclinic-degraded) is **honest**: structurally near-identical repos whose real differences are runtime — out of h1 scope by design.

> ⚠️ Caveats: the ρ gain (+0.054) is modest at n=10 and sits inside the baseline's own luck envelope — the strong claim is the pair check and the tie bounds, not the headline. Scoring is agent judgment: re-deriving score sheets is an agent session, only *consuming* them is mechanical. h1 disagrees with expert ranking v1 on two repos (blog-rest-api: h1 9th vs expert 6th — genuine undeclared-MySQL test failure + committed JWT secret; petclinic-degraded: h1 5–7th vs expert 9th — petclinic-grade architecture credits on a synthetic-bottom repo). This triggers the v2 ranking-revision policy; the human's call is recorded before the next experiment (`evidence/experiments/h1-rubric-scoring.md`).

### How to run

```bash
# Collect mechanical evidence for a repo:
bash service/advanced/collect.sh <repo-url-or-path> --out evidence/advanced/h1/<repo>

# Score-to-harness path (uses the COMMITTED score sheet; does not re-score):
bash service/advanced/analyze-h1.sh <repo-url-or-path> --out <out-dir>

# Reproduce the headline numbers from committed artifacts (seconds):
python service/eval/evaluate.py --label h1 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h1
# Expected: "Spearman rho vs expert ranking: 0.865 (n=10)"
```

Full setup, versions, and expected output: [`REPRODUCTION.md`](REPRODUCTION.md).

---

## Eval Set

The 10-repo evaluation set is composed of public repos, one synthetic degraded fork, and four self-authored controlled repos (`service/targets.txt` is the authoritative record, incl. validation results, pins, and dropped candidates). Scores below are committed in `evidence/eval/baseline/eval-report.md` and `evidence/eval/h1/eval-report.md`:

| # | Repo | Type | Expert (v1) | Baseline | h1 |
|---|------|------|:-----------:|:--------:|:--:|
| 1 | spring-projects/spring-petclinic | public good | 1 | 100 | 72 |
| 2 | practice-webflux-redis | self-authored controlled | 2 | 90 | 57 |
| 3 | eugenp/REST-With-Spring (module6, pinned clone @ `9c06a66`) | public multi-module | 3 | 100 | 63 |
| 4 | practice-webflux | self-authored controlled | 4 | 90 | 56 |
| 5 | practice-mvc-caffeine | self-authored controlled | 5 | 90 | 55 |
| 6 | RameshMF/springboot-blog-rest-api | public average, tutorial-grade | 6 | 65 | 42 |
| 7 | practice-mvc | self-authored controlled | 7 | 90 | 55 |
| 8 | spring-guides/gs-rest-service-complete (pinned clone @ `2ef8e28`) | public weak skeleton | 8 | 90 | 50 |
| 9 | MSyamsandiYudaWirawan/petclinic-degraded | synthetic bottom (fork) | 9 | 55 | 55 |
| 10 | spring-projects/spring-mvc-showcase | public legacy, archived | 10 | 40 | 26 |
| | **Spearman ρ vs v1** | | | **0.811** | **0.865** |
| | Tie bounds | | | [0.527, 0.915] | [0.835, 0.929] |
| | Pairs (concord./discord./unjudged) | | | 31/3/11 | 37/5/3 |

**Disclosure:** The four practice repos are self-authored services built before the event to test the benchmark pipeline, included because they provide a known ground-truth ordering. The agent scored blind — it read only collected evidence, never the expert ranking (`evidence/experiments/h1-rubric-scoring.md`). The expert ranking basis and justifications: `evidence/expert-ranking-notes.md`.

---

## Hot Take

> **The ties are where the information is.** The baseline's 0.811 and h1's 0.865 are almost the same number — what changed is that the analyzer now has an *opinion* about the middle of the ranking, with receipts: 11 unjudged pairs became 3, and every point in the 50–63 span cites a build log, a test census, or a dependency analysis. A quality score that can't order the middle isn't scoring quality; it's checking boxes.

---

## Architecture Trade-offs

| What we gained | What we gave up |
|----------------|-----------------|
| Discrimination with receipts: the 90-tie broke into a cited, defensible 50–63 span; unjudged pairs 11 → 3 | Authoring is agentic: score sheets are agent judgment — only consuming them is mechanical, so reproducibility lives in the committed artifact |
| A uniform Runtime = 0 rule that keeps an unmeasured dimension from distorting ρ | 25 of 100 rubric points still dark — the practice-repo runtime ordering remains untested (later experiments' territory) |
| Mechanical collection is repeatable (`collect.sh`, facts only) | Collection is environment-sensitive like the baseline: the port-5432 incident reproduced during collection and petclinic had to be re-collected with the container stopped (`evidence/experiments/h1-rubric-scoring.md`) |

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
