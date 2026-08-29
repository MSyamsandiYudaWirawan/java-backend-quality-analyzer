# Reproduction Guide

## Which Branch to Reproduce?

Every experiment lives on its own branch. Pick the one you want to verify:

| Branch | What it is | Key result |
|--------|------------|------------|
| `baseline` | Naive shell-script analyzer: 5 shallow checks → 0–100 score. Control for all experiments. | spring-petclinic → 100/100 (saturates) |
| `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence; Runtime = 0 uniformly. **KEPT** — broke the baseline's 5-way tie at 90. | ρ = 0.865 vs v1 (0.939 vs v2) |
| `exp/h2-k6-generation` | + agent-generated k6 load tests (template+slots, smoke gate, docker envelope); Runtime scored from measured load. **KEPT** — controlled-repo ordering recovered exactly. | ρ = 0.954 vs v2 |
| `exp/h3-full-pipeline` | + JFR profiling during the generated load (`--jfr`); Runtime grades on k6 + JFR. **KEPT** — petclinic collapse explained (fat-jar classloader lock). | ρ = 0.973 vs v2 |
| `advanced` | Final agent workflow = baseline + h1 + h2 + h3 (all KEPT). | ρ 0.811 → 0.973 |

```bash
git checkout baseline
# or
git checkout exp/h3-full-pipeline
# or
git checkout advanced
```

---

## Prerequisites

- Git
- Java 21 (`java -version`; the `jfr` CLI ships with the JDK)
- Maven 3.9+ (`mvn -version`)
- Python 3.10+ (`python --version` — eval harness, stdlib only)
- Node.js 18+ (`node --version` — k6 report/orchestrator scripts)
- bash (Linux/macOS native; on Windows use Git Bash)
- **Advanced workflow only:** Docker + Docker Compose (k6 runs in the `grafana/k6:0.57.0` container; no local k6 install needed for docker mode)

No other dependencies. `jq` is **not** required.

## Versions Used

| Component | Version |
|-----------|---------|
| Java | 21.0.11 |
| Maven | 3.9.11 |
| Python | 3.13 |
| k6 | 0.57.0 (docker image `grafana/k6:0.57.0`) |
| Target image | `eclipse-temurin:21-jre-jammy` (pinned) |
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

Fast, offline, no Maven or network needed (the full session-start suite):

```bash
tests/unit/test-baseline.sh && tests/unit/test-collect.sh \
  && tests/unit/test-analyze-h1.sh && python tests/unit/test_spearman.py \
  && python tests/unit/test_gen_k6.py \
  && tests/unit/test-k6-report.sh && tests/unit/test-run-experiment.sh
# Expected: "All unit tests passed." / "OK" from every suite
```

---

## Running the Advanced Workflow

The advanced workflow is an agent-driven analysis, but every mechanical step
is reproducible from committed artifacts:

**1. Mechanical evidence collection** (build/test logs, census, package tree,
dependency analysis):

```bash
bash service/advanced/collect.sh <repo-url-or-path> --out evidence/advanced/h1/<repo>
```

**2. Runtime measurement** (k6 load + JFR profile, docker envelope). The
committed k6 script + slots for each eval repo are reused, never regenerated:

```bash
./run-experiment.sh <repo-url-or-path> --docker          # h2: k6 only
./run-experiment.sh <repo-url-or-path> --docker --jfr    # h3: k6 + JFR + diagnosis
# Outputs: evidence/advanced/h2|h3/<repo>/{load-report.md,k6-full.json,
#          profile.jfr (gitignored, regenerates), jfr/diagnosis-report.md}
```

A repo that cannot be built/booted/load-tested writes a NOT_TESTABLE load
report and exits 3 — a finding, not a harness failure.

**3. Scoring** is agent judgment against the rubric
(`service/rubric/quality-rubric.md`) with per-item citations; the committed
score sheets (`evidence/advanced/h1/*/score-sheet.json`) are the artifact of
record. Re-deriving scores is an agent session; *consuming* them is
mechanical (next section).

## Running the Evaluation (baseline vs. advanced)

Both analyzers run over the same fixed eval set (`service/targets.txt`);
scores are compared against the human-expert ranking
(`service/eval/expert-ranking.txt`, v2). Primary metric: Spearman ρ, with
tie bounds + pair counts (the harness stamps NOT ROBUST when >20% of pairs
are unjudged).

```bash
# Advanced (h3) — reuses committed score sheets via the thin wrapper:
python service/eval/evaluate.py --label h3 \
  --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/h3 --resume
# Expected: "Spearman rho vs expert ranking: 0.973 (n=10)"

# Baseline — reuses committed scores; without --resume it re-measures
# (environment-sensitive: see the port-5432 incident in prompts/README.md):
python service/eval/evaluate.py --label baseline-v2 \
  --analyzer "bash service/baseline/analyze.sh {target} --skip-build --out {out}" \
  --targets service/targets.txt --ranking service/eval/expert-ranking.txt \
  --out evidence/eval/baseline-v2 --resume
# Expected: "Spearman rho ... 0.850 (n=10) — NOT ROBUST ..." (0.811 vs v1)
```

h1/h2 equivalents live at `evidence/eval/h1/` (0.865 vs v1),
`evidence/eval/h1-v2/` (0.939), `evidence/eval/h2/` (0.954). Per-repo tables
are in each dir's `eval-report.md`; the 4-stage comparison is in
`IMPROVEMENTS.md`.

---

## Approximate Runtime & Cost

| Step | Time |
|------|------|
| Unit tests (full suite) | < 30 seconds |
| Baseline on spring-petclinic (first run, cold Maven cache) | ~5–10 minutes |
| Baseline on spring-petclinic (warm Maven cache) | ~2–3 minutes |
| Advanced runtime measurement per repo (`--docker --jfr`) | ~6–9 minutes (mvn build + docker build + 70s load + JFR diagnosis) |
| Eval harness over 10 repos (`--resume`) | < 10 seconds |
| Full eval set, measured runs (7 testable repos, sequential) | ~50–60 minutes |

**Cost:** Zero. Everything runs locally; Docker is used only for isolated
target infra and the k6/JFR envelope in the advanced workflow.

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

### Docker benchmark: container exits immediately / "not able to write to file" (Windows)

Two Windows-specific failure classes, both fixed in the pipeline and
documented here for anyone modifying it:

- **JFR `disk=true` chunk writes fail on Docker Desktop bind mounts.** The
  pipeline uses in-memory recording + `dumponexit=true` instead; do not
  re-add `disk=true` to `JFR_OPTS`.
- **Git Bash rewrites POSIX-looking env values when spawning docker.exe**
  (`/jfr-repo/...` → `C:/Program Files/Git/...`). All compose calls in
  `run-experiment.sh` run under `MSYS_NO_PATHCONV=1` — keep it that way.

### Baseline eval scores don't match the committed evidence

The baseline is environment-sensitive by design (it runs the target's real
build + tests). A stray Docker container holding port 5432 once swung its ρ
from 0.811 to 0.493 by breaking petclinic's tests. Use `--resume` to reuse
committed scores when reproducing headline numbers; re-measure only to
re-verify the measurement itself.
