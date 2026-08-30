# Reproduction Guide

## Which Branch to Reproduce?

Every experiment lives on its own branch. Pick the one you want to verify:

| Branch | What it is | Key result |
|--------|------------|------------|
| `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence; Runtime = 0 uniformly. **KEPT** — broke the baseline's 5-way tie at 90. | ρ = 0.865 vs v1 (0.939 vs v2) |
| `exp/h2-k6-generation` (this one) | + agent-generated k6 load tests (template+slots, smoke gate, docker envelope); Runtime scored from measured load. **KEPT** — controlled-repo ordering recovered exactly. | ρ = 0.954 vs v2 |

The **baseline has no dedicated branch** — it is the control *analyzer*
(`service/baseline/analyze.sh`) plus its committed evidence
(`evidence/eval/baseline*/`), both present on every branch above, so the
baseline is reproduced from whichever branch you checked out (see
[Running the Baseline Analyzer](#running-the-baseline-analyzer) and the
`--resume` eval commands below).

```bash
git checkout exp/h2-k6-generation
# or
git checkout exp/h1-rubric-scoring
```

---

## Prerequisites

- Git
- Java 21 (`java -version`)
- Maven 3.9+ (`mvn -version`)
- Python 3.10+ (`python --version` — eval harness + k6 generator, stdlib only)
- Node.js 18+ (`node --version` — `benchmarks/k6-report.js` / `orchestrate.js`)
- bash (Linux/macOS native; on Windows use Git Bash)
- **H2 measured runs only:** Docker + Docker Compose (k6 runs in the `grafana/k6:0.57.0` container; no local k6 install needed for docker mode)

No other dependencies. JFR is **not** needed at this stage (JFR rubric item scores 0 uniformly — h3 territory). `jq` is **not** required.

## Versions Used

| Component | Version |
|-----------|---------|
| Java | 21.0.11 |
| Maven | 3.9.11 |
| Python | 3.13 |
| k6 | 0.57.0 (docker image `grafana/k6:0.57.0`) |
| Target image | `eclipse-temurin:21-jre` (per `service/advanced/docker/Dockerfile.target`) |
| OS | Windows 11 + Git Bash (also runs on Linux/macOS bash) |

---

## Running the Baseline Analyzer

```bash
# Analyze any public Java repo (or a local path):
./service/baseline/analyze.sh https://github.com/spring-projects/spring-petclinic \
  --out evidence/baseline/spring-petclinic

# Structural checks only, no Maven run (fast, offline):
./service/baseline/analyze.sh <repo-url-or-path> --skip-build
```

**What it does:** clones the target (shallow), checks for README / `pom.xml` / test sources, runs `mvn package` and `mvn test` (15-minute timeout each, override with `BUILD_TIMEOUT_SECONDS`), then writes `baseline-report.md` and `baseline-score.json` into the out dir.

**Expected output for spring-petclinic:** `Score: 100/100` (committed reference: `evidence/baseline/spring-petclinic/baseline-report.md`, commit `818c413`). The saturation is intentional — the control.

## Running the Unit Tests

Fast, offline, no Maven or network needed:

```bash
tests/unit/test-baseline.sh && tests/unit/test-collect.sh \
  && tests/unit/test-analyze-h1.sh && tests/unit/test-k6-report.sh \
  && tests/unit/test-run-experiment.sh \
  && python tests/unit/test_spearman.py && python tests/unit/test_gen_k6.py
# Expected: "All unit tests passed." / "OK" from every suite (77 assertions total)
```

---

## Running the H1 Workflow

The h1 pipeline is: **collect** mechanical facts → **agent scores** the rubric blind, with citations → committed score sheets → **thin wrapper** feeds the harness.

```bash
# 1. Mechanical evidence collection (repeatable, facts only):
bash service/advanced/collect.sh <repo-url-or-path> --out evidence/advanced/h1/<repo>

# 2. Scoring is agent judgment, blind, cited — committed score sheets
#    (evidence/advanced/h1/<repo>/score-sheet.json) are the artifact of record.

# 3. Harness wrapper (no re-scoring — validates the committed sheet):
bash service/advanced/analyze-h1.sh <repo-url-or-path> --out <out-dir>
```

## Running the H2 Workflow

The h2 pipeline is: **agent generates** a load test (template + slots) → script **committed** → **measured run** in the fixed docker envelope → load report → **blind Runtime scoring** on the extended h1 score sheet.

**1. Generation** (agentic: the agent inspects the target's API surface and fills a slots JSON; the render is mechanical):

```bash
python service/advanced/gen-k6.py --slots evidence/advanced/h2/<repo>/slots.json \
  --out evidence/advanced/h2/<repo>/load-test.js
# Exit 0 = slots valid + rendered. The committed script is the artifact of record;
# re-runs NEVER regenerate (prompts/README.md §5).
```

**2. Measured run** (committed script, identical resource envelope for every repo):

```bash
./run-experiment.sh <repo-url-or-path> --docker
# Boot target → smoke gate (2 VUs/5s) → full k6 → fixed-shape load report.
# Exit 0 measured (any threshold verdict); exit 3 = NOT_TESTABLE (a finding —
# the pipeline writes a root-cause load report, not a harness failure).
```

The committed evidence holds a **dual fixed profile**: 200-VU stress runs at `evidence/advanced/h2/<repo>/`, 50-VU efficiency runs at `evidence/advanced/h2-50vus/<repo>/` (10s ramp + 60s hold; thresholds p95<500ms / err<1% / checks>95%).

⚠️ Environment record (from `evidence/experiments/h2-k6-generation.md`): the `practice-postgres` container must be **UP** (`docker compose up -d postgres` in `targets/practice-mvc/`) for practice-mvc / mvc-caffeine boot+load, and **STOPPED** for spring-petclinic / petclinic-degraded (port-5432 conflict — the Day-2 incident). blog-rest-api needs an undeclared MySQL and boot-crashes on stock MySQL 8.4 — that NOT_TESTABLE outcome is the designed behavior, not a setup error.

**3. Runtime scoring** is blind agent judgment on the load reports, extending the committed h1 score sheets in place (boots 5 + latency/throughput 10; JFR item = 0 for all repos — h3 capability). Consuming the sheets stays mechanical via `analyze-h1.sh`.

---

## Reproducing the Headline Numbers (eval harness)

The eval harness (`service/eval/evaluate.py`) runs an analyzer over the fixed eval set (`service/targets.txt`) and compares the score order against the human-expert ranking (`service/eval/expert-ranking.txt` — **v2, committed in place at this stage**). Primary metric: Spearman ρ, with tie bounds + pair counts.

**h2 — from committed score sheets (fast, deterministic):**

```bash
python service/eval/evaluate.py --label h2 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h2
```

**Expected output:**

```
**Spearman rho vs expert ranking: 0.954** (n=10)
```

plus the per-repo table (82/78/72/71/70/65×2/50/42/26), the tie check (2 of 10 repos in 1 tie group, bounds [0.939, 0.964]), and the pair check (41 concordant / 3 discordant / 1 tied of 45). Verified 2026-08-30: regenerated headline matches the committed report exactly. (h2 eval uses the h1 wrapper because the h2 Runtime scores were committed into the h1 score sheets in place.)

**h1 vs v2 — from committed score sheets (fast, deterministic):**

```bash
python service/eval/evaluate.py --label h1-v2 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h1-v2
```

**Expected output:**

```
**Spearman rho vs expert ranking: 0.939** (n=10)
```

⚠️ **Do not re-run `--label h1` or `--label baseline` on this branch.** Their committed reports (`evidence/eval/h1/`, `evidence/eval/baseline/`) were computed against ranking **v1**, which was replaced in place by v2 at this stage — re-running here would regenerate them against v2 and clobber the v1 artifacts of record. To reproduce h1's 0.865 vs v1 and the baseline's 0.811 vs v1, check out `exp/h1-rubric-scoring` and follow its REPRODUCTION.md. The harness also rewrites the report's Note column on `--resume` ("reused from previous run") — after any verification run, restore with `git checkout -- evidence/` so committed evidence is never dirtied.

**h2, fully measured (environment-sensitive — re-verifies the measurement, not the headline):**

```bash
# Per repo (7 load-testable of 10), sequential — envelope fairness:
./run-experiment.sh <target> --docker     # 200-VU profile → evidence/advanced/h2/<repo>/
# + the same at 50 VUs → evidence/advanced/h2-50vus/<repo>/
# Committed measured runs: 2026-08-29 ~08:10–08:55 UTC, sequential.
```

Re-running measured runs overwrites committed evidence — copy the repo's `evidence/advanced/h2*/<repo>/` aside first, or measure into a scratch checkout. Observe the port-5432 dance above and expect numbers to drift with host hardware; the *verdicts* (PASS/FAIL per profile) are the reproducible part.

---

## Approximate Runtime & Cost

| Step | Time |
|------|------|
| Unit tests (full suite) | < 30 seconds |
| Baseline on spring-petclinic (cold / warm Maven cache) | ~5–10 / ~2–3 minutes |
| h1 collection per repo (`collect.sh`, with build) | minutes per repo (10 repos ≈ 15 minutes total, per the h1 environment record) |
| h2 measured run per repo per profile (docker build + boot + 70s load) | minutes (7 repos × 2 profiles ≈ 45 minutes total, per the h2 environment record) |
| Eval harness over 10 repos (`--resume`, h2 or h1-v2) | < 10 seconds |

**Cost:** Zero. Everything runs locally.

## Troubleshooting

### `mvn` times out on a large target repo

```bash
BUILD_TIMEOUT_SECONDS=1800 ./service/baseline/analyze.sh <repo-url>
```

### Shell script fails with `\r` errors after checkout on Windows

Line endings were normalized by Git. `.gitattributes` pins `*.sh` to LF — re-checkout with:

```bash
git rm --cached -r . && git reset --hard
```

### Baseline eval scores don't match the committed evidence

The baseline is environment-sensitive by design (it runs the target's real build + tests). A stray Docker container holding port 5432 once swung its ρ from 0.811 to 0.493 by breaking petclinic's tests. Use `--resume` to reuse committed scores when reproducing headline numbers — on the branch where the matching ranking version is committed (v1 → `exp/h1-rubric-scoring`, v2 → this branch).

### Docker compose runs fail or mangle paths on Windows / Git Bash

Git Bash rewrites POSIX paths into Windows paths when spawning docker.exe — three incidents of this bug class were hit during h2. Every compose invocation in the pipeline carries `MSYS_NO_PATHCONV=1`; if you drive the compose files by hand, export it first.

### practice-mvc / mvc-caffeine fail to boot for load, or petclinic's tests fail

The port-5432 dance: `practice-postgres` must be UP for the mvc pair (`docker compose up -d postgres` in `targets/practice-mvc/`) and STOPPED for the petclinics. This is recorded in the h2 environment record and bit the project on Day 2, during h1 collection, and again during h2.

### blog-rest-api reports NOT_TESTABLE

Designed behavior, not a setup error: the repo needs an undeclared MySQL and boot-crashes on stock MySQL 8.4 ("Public Key Retrieval is not allowed"), with an ADMIN-JWT wall beyond. The finding and its root cause are the evidence (`evidence/advanced/h2/springboot-blog-rest-api/`, boot-diagnosis.log).

### Top-end RPS numbers look compressed

The k6 container has 1 CPU / 512 MB by design (envelope fairness). mvc-caffeine's 2168 rps may approach the generator's ceiling — compare threshold verdicts, not raw RPS, at the top end (noted in the h2 experiment record).
