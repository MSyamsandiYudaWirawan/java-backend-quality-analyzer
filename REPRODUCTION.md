# Reproduction Guide

## Which Branch to Reproduce?

Every experiment lives on its own branch. Pick the one you want to verify:

| Branch | What it is | Key result |
|--------|------------|------------|
| `baseline` | Naive shell-script analyzer: 5 shallow checks → 0–100 score. Control for all experiments. | spring-petclinic → 100/100 (saturates) |
| `exp/[name]` | [Hypothesis / capability added]. **[KEPT/REJECTED]** — [one-line reason]. | [Δρ / findings delta] |
| `advanced` | Final agent workflow: build + test evidence + JFR/k6 runtime profiling + rubric-scored report. | [baseline ρ → advanced ρ] |

```bash
git checkout baseline
# or
git checkout exp/[name]
# or
git checkout advanced
```

---

## Prerequisites

- Git
- Java 21 (`java -version`)
- Maven 3.9+ (`mvn -version`)
- bash (Linux/macOS native; on Windows use Git Bash)
- **Advanced workflow only:** Docker + Docker Compose, k6, `jfr` CLI (ships with the JDK)

No other dependencies. `jq` is **not** required.

## Versions Used

| Component | Version |
|-----------|---------|
| Java | 21.0.11 |
| Maven | 3.9.11 |
| k6 | [fill when advanced lands] |
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

**What it does:** clones the target (shallow), checks for README / `pom.xml` / test sources, runs `mvn package` and `mvn test` (15-minute timeout each, override with `BUILD_TIMEOUT_SECONDS`), then writes:

```
<out>/
├── baseline-report.md    # human-readable score table
├── baseline-score.json   # machine-readable score
├── build.log             # full mvn package output (evidence)
└── test.log              # full mvn test output (evidence)
```

**Expected output for spring-petclinic:** `Score: 100/100` — all five checks pass. This saturation is intentional; it is the control the advanced workflow is measured against.

## Running the Unit Tests

Fast, offline, no Maven or network needed:

```bash
tests/unit/test-baseline.sh
# Expected: "All unit tests passed." (9 assertions against fixture repos)
```

---

## Running the Advanced Workflow

[Day 2–3. The advanced workflow is an agent-driven analysis: clone → build → parsed test evidence → k6 + JFR runtime profile of the target (`run-experiment.sh`, `jfr-diagnose.sh`) → rubric-scored report. Exact commands and the eval harness over `service/targets.txt` will be documented here when the `advanced` branch lands.]

## Running the Evaluation (baseline vs. advanced)

[Day 2–3. Both analyzers run over the same fixed eval set in `service/targets.txt`; scores are compared against the human-expert ranking. Primary metric: Spearman ρ. Per-repo score table and methodology will be documented here.]

---

## Approximate Runtime & Cost

| Step | Time |
|------|------|
| Unit tests | < 5 seconds |
| Baseline on spring-petclinic (first run, cold Maven cache) | ~5–10 minutes |
| Baseline on spring-petclinic (warm Maven cache) | ~2–3 minutes |
| Advanced workflow per repo | [TBD] |
| Full eval set | [TBD] |

**Cost:** Zero. Everything runs locally; Docker is used only for isolated target infra in the advanced workflow.

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
