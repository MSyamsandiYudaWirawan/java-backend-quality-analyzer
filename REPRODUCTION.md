# Reproduction Guide

> **Branch:** `exp/h1-rubric-scoring` — this guide reproduces the baseline stage and iteration 1 (h1). Later stages (`exp/h2-*`, …, `advanced`) have their own guides on their own branches.

## What This Stage Is

| Branch | What it is | Key result |
|--------|------------|------------|
| `baseline` | Naive shell-script analyzer: 5 shallow checks → 0–100 score. Control for all experiments. | spring-petclinic → 100/100 (saturates); eval ρ = 0.811 vs v1, NOT ROBUST |
| `exp/h1-rubric-scoring` (this one) | + agent rubric scoring on collected mechanical evidence; Runtime = 0 uniformly. **KEPT** — broke the baseline's 5-way tie at 90. | ρ = 0.865 vs v1; unjudged pairs 11 → 3 |

```bash
git checkout exp/h1-rubric-scoring
```

---

## Prerequisites

- Git
- Java 21 (`java -version`)
- Maven 3.9+ (`mvn -version`)
- Python 3.10+ (`python --version` — eval harness, stdlib only)
- bash (Linux/macOS native; on Windows use Git Bash)

No other dependencies. Docker and k6 are **not** needed at this stage (no runtime measurement yet — Runtime scores 0 uniformly). `jq` is **not** required.

## Versions Used

| Component | Version |
|-----------|---------|
| Java | 21.0.11 |
| Maven | 3.9.11 |
| Python | 3.13 |
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
  && tests/unit/test-analyze-h1.sh && python tests/unit/test_spearman.py
# Expected: "All unit tests passed." / "OK" from every suite
```

---

## Running the H1 Workflow

The h1 pipeline is: **collect** mechanical facts → **agent scores** the rubric blind, with citations → committed score sheets → **thin wrapper** feeds the harness.

**1. Mechanical evidence collection** (repeatable, facts only):

```bash
bash service/advanced/collect.sh <repo-url-or-path> --out evidence/advanced/h1/<repo>
# Writes: build.log, test.log, surefire-summary.txt, test-census.txt,
# package-tree.txt, largest-classes.txt, dependency-analyze.log,
# dependency-list.txt, repo-scan.txt, collect-manifest.json
```

⚠️ Collection runs the target's real build + tests, so it is environment-sensitive like the baseline: with a Postgres container on port 5432, spring-petclinic's `PostgresIntegrationTests` fail (the Day-2 incident reproduced during the h1 collection run; petclinic was re-collected with the container stopped — `evidence/experiments/h1-rubric-scoring.md`, Environment record).

**2. Scoring** is agent judgment against the rubric (`service/rubric/quality-rubric.md`), blind (the agent reads only the collected evidence, never `service/eval/expert-ranking.txt`), with per-item citations. The committed score sheets (`evidence/advanced/h1/<repo>/score-sheet.json`) are the artifact of record. Re-deriving them is an agent session; *consuming* them is mechanical (next step).

**3. Harness wrapper** (no re-scoring — validates the committed sheet, emits `h1-score.json`):

```bash
bash service/advanced/analyze-h1.sh <repo-url-or-path> --out <out-dir>
```

---

## Reproducing the Headline Numbers (eval harness)

The eval harness (`service/eval/evaluate.py`) runs an analyzer over the fixed eval set (`service/targets.txt`) and compares the score order against the human-expert ranking (`service/eval/expert-ranking.txt`, v1). Primary metric: Spearman ρ, with tie bounds + pair counts; the harness stamps NOT ROBUST when >20% of pairs are unjudged.

**h1 — from committed score sheets (fast, deterministic):**

```bash
python service/eval/evaluate.py --label h1 --resume \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h1
```

**Expected output:**

```
**Spearman rho vs expert ranking: 0.865** (n=10)
```

plus the per-repo table (72/63/57/56/55×3/50/42/26), the tie check (3 of 10 repos in 1 tie group, bounds [0.835, 0.929]), and the pair check (37 concordant / 5 discordant / 3 tied of 45). `--resume` reuses each repo's committed `h1-score.json`; even without it the wrapper only reads committed score sheets, so h1 eval runs are always reproducible.

**baseline — from committed scores (fast, deterministic):**

```bash
python service/eval/evaluate.py --label baseline --resume \
  --analyzer "bash service/baseline/analyze.sh {target} --skip-build --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/baseline
```

**Expected output:**

```
**Spearman rho vs expert ranking: 0.811** (n=10) — NOT ROBUST: tie-sensitive, range [0.527, 0.915], 24% of pairs unjudged
```

The committed baseline report additionally carries a hand-written analyst note (Monte Carlo P(ρ ≥ 0.811 by luck) ≈ 29%; the port-5432 incident) that a regenerated report does not reproduce — the numbers above are what must match.

**Baseline, fully measured (environment-sensitive — re-verifies the measurement, not the headline):**

```bash
python service/eval/evaluate.py --label baseline \
  --analyzer "bash service/baseline/analyze.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/baseline-fresh
```

(No `--skip-build`: the committed scores come from full runs — e.g. `springboot-blog-rest-api`'s 65 includes a real `mvn test` FAILURE.) Quiesce Docker first — a stray container on port 5432 once swung this exact run from 0.811 to 0.493 — and write to a fresh out dir so committed evidence is never overwritten.

---

## Approximate Runtime & Cost

| Step | Time |
|------|------|
| Unit tests (full suite) | < 30 seconds |
| Baseline on spring-petclinic (cold / warm Maven cache) | ~5–10 / ~2–3 minutes |
| h1 collection per repo (`collect.sh`, with build) | minutes per repo (10 repos ≈ 15 minutes total, per the h1 environment record) |
| Eval harness over 10 repos (`--resume`, h1 or baseline) | < 10 seconds |
| Full baseline eval, measured (10 repos × real mvn build + test) | tens of minutes, sequential |

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

The baseline is environment-sensitive by design (it runs the target's real build + tests). A stray Docker container holding port 5432 once swung its ρ from 0.811 to 0.493 by breaking petclinic's tests — and the same sensitivity bit the h1 collection run. Use `--resume` to reuse committed scores when reproducing headline numbers; re-measure only to re-verify the measurement itself, into a fresh out dir.

### `dependency-analyze.log` / `dependency-list.txt` come out empty from `collect.sh`

That was a real bug: `mvn -B -q` suppresses dependency-plugin output. Fixed in `collect.sh` during the h1 run (dependency goals run without `-q`) — if you see empty files you are on an old checkout; the current script does not have this bug.
