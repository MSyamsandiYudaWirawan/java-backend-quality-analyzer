# Java Backend Code Quality Analyzer — Hackathon Submission

> **Context:** micro1 Frontier Engineering Challenge. This repo contains a baseline solution and an advanced solution, with measured evidence for every experiment.

> **Pre-existing:** This repo was initialized from a personal hackathon template (prompts, benchmark scripts, CI skeleton). All solution code, tests, experiments, and evidence were built during the August 2026 event.

> **Branch:** `exp/h2-k6-generation` — iteration 2 (**KEPT**). Built on `exp/h1-rubric-scoring`; the final experiment (`exp/h3-*`) and the final workflow (`advanced`) build on this one.

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
- All experiment branches (`exp/h1-rubric-scoring`, `exp/h2-k6-generation`, …)
- All evidence files (`evidence/baseline/`, `evidence/eval/`, `evidence/advanced/h1/`, `evidence/advanced/h2*/`, `evidence/experiments/`)
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

## This Branch: H2 — Agent-Generated k6 Load Testing (KEPT)

The second capability: the agent **generates and executes its own k6 load tests** against the booted targets and scores the rubric's Runtime dimension (25 pts) from the measured evidence — the dimension h1 deliberately left dark (Runtime = 0 uniformly).

The pipeline:

1. **Template + slots generation** (`prompts/README.md` §5 policy) — the agent inspects the target's API surface (OpenAPI/springdoc if present, controllers otherwise) and fills a slots JSON; `service/advanced/gen-k6.py` validates it against a fixed schema and renders the fixed skeleton (`service/advanced/k6/template.js`, plus a `template-form.js` variant for server-rendered apps). No free-form scripts. The rendered `load-test.js` + `slots.json` are **committed per repo as evidence** (`evidence/advanced/h2/<repo>/`); re-runs use the committed script, never regeneration.
2. **Smoke gate** — a generated script must pass a short validation run (setup succeeds, response checks pass) before acceptance. We vouch by validation, not by trust.
3. **Measured runs in a fixed docker envelope** — `./run-experiment.sh <target> --docker`: generic `Dockerfile.target` + `service/advanced/docker/h2-*.yml` give every repo the identical resource envelope (service 2 CPU/2 GB, k6 1 CPU/512 MB, infra addendums per `slots.infra`). **Dual fixed profile** (decided before any evidence was committed, because 50 VUs kept every repo far from its saturation knee): 50-VU efficiency runs at `evidence/advanced/h2-50vus/<repo>/`, 200-VU stress runs at `evidence/advanced/h2/<repo>/` — otherwise identical (10s ramp + 60s hold, 10% creates / 90% reads of 50 seeded entities, thresholds p95<500ms / err<1% / checks>95%).
4. **Blind Runtime scoring** — boots (5) + latency/throughput (10) scored from the load reports; **JFR item = 0 for all repos** (h3 capability — same non-distortion rule as h1's Runtime = 0), so h2 max runtime is 15/25. The other four dimensions stay as committed in `evidence/advanced/h1/*/score-sheet.json` — no re-scoring, h1 results remain reproducible. Full latency credit only for PASS at **both** profiles; half credit for FAIL-at-200 but functional.
5. **NOT_TESTABLE is a finding, not a failure** — a repo that cannot be built/booted/load-tested gets Runtime = 0 with an explicit root-cause note (pipeline exits 3).

**Measured (headline):** Spearman ρ vs. expert ranking v2 on the 10-repo eval set: **h1 0.939 → h2 0.954** (`evidence/eval/h2/eval-report.md`; full record: `evidence/experiments/h2-k6-generation.md`). The substance, per the pre-registered falsification criteria:

- **The controlled-repo ordering is recovered exactly.** The four practice repos were the only ones the expert ranked on measured runtime knowledge (webflux-redis > webflux > mvc-caffeine > mvc); the analyzer's final order matches — and practice-mvc, the only FAIL @200 of the four, lands last on the runtime evidence alone.
- **The honest h1 tie at 55 breaks on exactly the pre-registered mechanism**: practice-mvc-caffeine separates from practice-mvc (70 vs 65) — same code minus a cache: 2168 rps PASS vs FAIL @200.
- **Unjudged pairs 3 → 1** of 45 (41 concordant / 3 discordant); tie bounds [0.939, 0.964].
- **spring-petclinic — baseline 100/100 — saturates at ~234 rps with p95 2191ms / max 8111ms under 200 VUs, checks 100%**: pure queueing collapse, invisible to every static check (`evidence/advanced/h2/spring-petclinic/load-report.md`).
- **3 NOT_TESTABLE findings with cited evidence**: blog-rest-api boot-crashes on stock MySQL 8.4 ("Public Key Retrieval is not allowed"), gs-rest-service-complete exposes no create endpoint, spring-mvc-showcase's build fails on Java 21 — each a real acquisition-relevant defect.

> ⚠️ Caveats: the ρ gain over h1 (+0.015) is small at n=10 — the strong claim is the evidence and the pair check, not the headline. Raw RPS ranks mvc-caffeine first (2168 > 1448 > 1031), so the order *among the three PASS controlled repos* comes from the other rubric dimensions; the **k6 container has 1 CPU**, so 2168 rps may approach the generator's ceiling and compress the top end — threshold verdicts are the robust signal. JFR is still dark (10 of 25 runtime points): a service can post high RPS with a critical hotspot underneath — that is h3's question.

### How to run

```bash
# Generate + validate a load test for a repo (agent fills slots; mechanical render):
python service/advanced/gen-k6.py --slots evidence/advanced/h2/<repo>/slots.json \
  --out evidence/advanced/h2/<repo>/load-test.js

# Measured run (committed script, fixed docker envelope, smoke gate + full load):
./run-experiment.sh <repo-url-or-path> --docker

# Reproduce the headline numbers from committed artifacts (seconds):
python service/eval/evaluate.py --label h2 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h2
# Expected: "Spearman rho vs expert ranking: 0.954 (n=10)"
```

Full setup, versions, and expected output: [`REPRODUCTION.md`](REPRODUCTION.md).

---

## Eval Set

The 10-repo evaluation set is composed of public repos, one synthetic degraded fork, and four self-authored controlled repos (`service/targets.txt` is the authoritative record, incl. validation results, pins, and dropped candidates). Scores below are committed in `evidence/eval/baseline/eval-report.md`, `evidence/eval/h1/eval-report.md`, and `evidence/eval/h2/eval-report.md`:

| # | Repo | Type | Expert (v2) | Baseline | h1 | h2 |
|---|------|------|:-----------:|:--------:|:--:|:--:|
| 1 | spring-projects/spring-petclinic | public good | 1 | 100 | 72 | 82 |
| 2 | practice-webflux-redis | self-authored controlled | 2 | 90 | 57 | 72 |
| 3 | eugenp/REST-With-Spring (module6, pinned clone @ `9c06a66`) | public multi-module | 3 | 100 | 63 | 78 |
| 4 | practice-webflux | self-authored controlled | 4 | 90 | 56 | 71 |
| 5 | practice-mvc-caffeine | self-authored controlled | 5 | 90 | 55 | 70 |
| 6 | practice-mvc | self-authored controlled | 6 | 90 | 55 | 65 |
| 7 | spring-guides/gs-rest-service-complete (pinned clone @ `2ef8e28`) | public weak skeleton | 7 | 90 | 50 | 50 |
| 8 | MSyamsandiYudaWirawan/petclinic-degraded | synthetic bottom (fork) | 8 | 55 | 55 | 65 |
| 9 | spring-projects/spring-mvc-showcase | public legacy, archived | 9 | 40 | 26 | 26 |
| 10 | RameshMF/springboot-blog-rest-api | public average, tutorial-grade | 10 | 65 | 42 | 42 |
| | **Spearman ρ** | | | **0.811** (v1) | **0.865** (v1) / **0.939** (v2) | **0.954** (v2) |
| | Tie bounds | | | [0.527, 0.915] | [0.835, 0.929] / [0.894, 0.965] | [0.939, 0.964] |
| | Pairs (concord./discord./unjudged) | | | 31/3/11 | 37/5/3 / 39/3/3 | 41/3/1 |

Expert ranking v2 (`service/eval/expert-ranking.txt`, committed in place at this stage): blog-rest-api moved 6th → 10th on the verified committed JWT secret; petclinic-degraded kept at its v1 relative position (its failures are intentionally injected — design intent is not a code property). Ruling: `evidence/experiments/expert-ranking-v2-decision.md`.

**Disclosure:** The four practice repos are self-authored services built before the event to test the benchmark pipeline, included because they provide a known ground-truth runtime ordering. They are the only repos the expert ranked on measured runtime knowledge — which makes them h2's built-in ground-truth check, recovered exactly. The agent scored blind: it read the rubric, load reports, and findings only, never the expert ranking (`evidence/experiments/h2-k6-generation.md`). The expert ranking basis and justifications: `evidence/expert-ranking-notes.md`.

---

## Hot Take

> **The honest tie was hiding a cache.** h1 left practice-mvc and practice-mvc-caffeine tied at 55 and called it honest — structurally near-identical repos. h2 put them under identical load and the tie broke on exactly the difference the structure couldn't show: 2168 rps PASS vs FAIL at 200 VUs, same code minus a cache. If your quality score can't boot the repo, it is grading the shape of the source tree, not the software.

---

## Architecture Trade-offs

| What we gained | What we gave up |
|----------------|-----------------|
| Measured runtime discrimination: the controlled-repo ordering recovered exactly, the honest h1 tie broken on its real mechanism, unjudged pairs 3 → 1 | Wall-clock and environment sensitivity: a measured run is a docker build + boot + 70s load per repo per profile, and the port-5432 dance (practice-postgres up for the mvc pair, down for the petclinics) must be right |
| Reproducible measurement from committed artifacts (frozen scripts, fixed envelope, fixed dual profile) | Agent authoring is not reproducible — only its artifacts are; regeneration is forbidden, re-runs use the committed scripts |
| One fixed profile everywhere = fair cross-repo comparison; NOT_TESTABLE = honest 0 with a root-cause note | No per-repo tuning: some apps are measured away from their real saturation knee, the 1-CPU k6 container may cap the top end, and 3 of 10 repos get no runtime score at all |

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
