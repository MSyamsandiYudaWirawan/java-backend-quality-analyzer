# Reproduction Guide

## Which Branch to Reproduce?

Every experiment lives on its own branch. Pick the one you want to verify:

| Branch | What it is | Key result |
|--------|------------|------------|
| `baseline` | [Tech stack]. Naive CRUD, no cache. Control for all experiments. | [X] req/s, p95=[X]ms |
| `experiment/[NAME]` | [Hypothesis]. **[KEPT/REJECTED]** — [one-line reason]. | [delta] |
| `advanced` | Final submission. [Tech stack]. | [X] req/s, p95=[X]ms |

```bash
git checkout baseline
# or
git checkout experiment/[NAME]
# or
git checkout advanced
```

---

## Prerequisites

- Docker + Docker Compose
- Java 21
- Maven (wrapper included: `./mvnw`)
- k6 (for load testing)
- OS: [your OS]

## Versions Used

| Component | Version |
|-----------|---------|
| Java | 21 |
| Spring Boot | [e.g., 4.1.1] |
| PostgreSQL | [e.g., 16-alpine] |
| Redis | [e.g., 7-alpine] — only if used |

## Setup

```bash
# 1. Start infrastructure
docker compose up -d

# 2. Verify health
docker compose ps

# 3. Build
cd service && ./mvnw clean package -DskipTests

# 4. Run
cd service && ./mvnw spring-boot:run
# or: java -jar target/service-0.0.1-SNAPSHOT.jar
```

The service starts on `http://localhost:8080`.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `[ENDPOINT]` | [Description] |
| GET | `[ENDPOINT]` | [Description] |

## Health Check

```bash
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}
```

## Running Tests

```bash
# Unit + integration tests
cd service && ./mvnw test

# Compile only (faster)
cd service && ./mvnw test-compile
```

## Load Test

### Automated Pipeline (recommended)

`run-experiment.sh` is a full 4-step pipeline — build, benchmark, report, diagnose — in one command:

```bash
# Native mode (uses your local JVM + k6)
./run-experiment.sh baseline
./run-experiment.sh advanced

# Docker mode (isolated, resource-limited — apples-to-apples across machines)
./run-experiment.sh baseline --docker
./run-experiment.sh advanced --docker
```

**What it does under the hood:**

| Step | What happens |
|------|--------------|
| `[1/4]` Build | `mvn clean package -DskipTests` |
| `[2/4]` Benchmark | Native: `node benchmarks/orchestrate.js` starts app, runs k6, records JFR. Docker: spins up isolated stack (service 2CPU/2GB, k6 1CPU/512MB, Postgres 1CPU/512MB), waits for k6 to finish, gracefully stops service to flush JFR via `dumponexit=true` |
| `[3/4]` k6 report | `node benchmarks/k6-report.js` parses k6 JSON → markdown summary |
| `[4/4]` JFR diagnosis | `./jfr-diagnose.sh` dumps events, computes percentiles, classifies severity, generates hypothesis-driven report |

**Tunable load parameters (env vars):**

```bash
VUS=300 DURATION=60s RAMP=10s ENTITY_COUNT=100 ./run-experiment.sh baseline --docker
```

**Artifacts produced:**

```
evidence/
├── {mode}.jfr                          # raw JFR recording
├── k6-{mode}.json                      # raw k6 output
├── k6-{mode}.md                        # k6 summary report
└── {mode}/diagnosis-report-{mode}.md   # JFR diagnosis report
```

### Manual k6 run

```bash
# Requires service running on localhost:8080
k6 run --env MODE=baseline benchmarks/k6.js

# Generate / regenerate report from existing JSON (no re-run needed)
node benchmarks/k6-report.js advanced
node benchmarks/k6-report.js evidence/k6-advanced.json --baseline evidence/k6-baseline.json
```

> ⚠️ `benchmarks/k6.js` is a template — replace `[ENDPOINT]` placeholders in `setup()` and `default()` before running. See [`benchmarks/README.md`](benchmarks/README.md).

### Expected output (advanced branch)

```
RPS: ~[X] req/s
p50 latency: ~[X]ms
p95 latency: ~[X]ms
p99 latency: ~[X]ms
errors: [X]%
```

> **Note:** Numbers vary by hardware. The delta (baseline → advanced) matters more than absolute values.

## Reproducing Individual Iterations

Every experiment lives on its own branch. To reproduce any iteration:

```bash
# List all experiment branches
git branch -a

# Reproduce baseline
git checkout baseline
cd service && ./mvnw clean package
# Run load test: ./run-experiment.sh baseline

# Reproduce a kept experiment
git checkout experiment/[NAME]
cd service && ./mvnw clean package
# Run load test: ./run-experiment.sh advanced
```

Compare `evidence/k6-baseline.json` and `evidence/k6-advanced.json` to verify the measured improvement.

## JFR Analysis

```bash
# Analyze any JFR recording
./jfr-diagnose.sh evidence/baseline.jfr
./jfr-diagnose.sh evidence/advanced.jfr

# Override thresholds
SEV_IO_CONCERNING_MS=30 ./jfr-diagnose.sh evidence/advanced.jfr
```

Output: `evidence/baseline/diagnosis-report-baseline.md` or `evidence/advanced/diagnosis-report-advanced.md`

## Approximate Runtime & Cost

| Step | Time |
|------|------|
| `docker compose up -d` | ~15 seconds |
| `./mvnw clean package` | ~30–60 seconds |
| `./run-experiment.sh baseline` | ~2 minutes |
| `./run-experiment.sh advanced` | ~2 minutes |
| Full test suite | ~1 minute |

**Cost:** Zero. All infrastructure runs locally in Docker. No cloud resources.

## Troubleshooting

### `localhost` connection refused during k6 / orchestrator

`localhost` can resolve to `127.0.0.1` (IPv4) or `::1` (IPv6) depending on your OS hosts file and JVM binding preferences. If the health poll or k6 setup fails with `connection refused`, the client and server may be on different loopback families.

**Quick fix — override the URL:**

```bash
# Orchestrator (Node health poll + k6)
SERVICE_URL=http://127.0.0.1:8080 ./run-experiment.sh baseline

# Manual k6 only
k6 run --env TARGET_URL=http://127.0.0.1:8080 benchmarks/k6.js

# If IPv4 still fails, try forcing IPv6
k6 run --env TARGET_URL=http://[::1]:8080 benchmarks/k6.js
```

**Verify which address the JVM bound to:**

```bash
# macOS / Linux
lsof -i :8080

# Windows (PowerShell)
Get-NetTCPConnection -LocalPort 8080
```
