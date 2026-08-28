#!/bin/bash
set -uo pipefail

# ============================================================================
# Full Experiment Pipeline: Build → Benchmark → Report → Diagnose
# ============================================================================
# Usage:
#   ./run-experiment.sh baseline
#   ./run-experiment.sh advanced
#   ./run-experiment.sh baseline --docker
#   ./run-experiment.sh advanced --docker
#
# Native mode (default):
#   1. cd service && mvn clean package
#   2. node benchmarks/orchestrate.js <mode>  (start app, run k6, collect JFR)
#   3. node benchmarks/k6-report.js <mode>
#   4. ./jfr-diagnose.sh <mode>
#
# Docker mode (--docker):
#   1. cd service && mvn clean package
#   2. docker compose -f docker-compose.benchmark.yml up -d  (isolated + limited)
#   3. JFR flushed on graceful stop via dumponexit=true
#   4. node benchmarks/k6-report.js <mode>
#   5. ./jfr-diagnose.sh <mode>
# ============================================================================
# --- Tunable Parameters (edit here) ------------------------------------------
# ============================================================================

# Load shape
VUS="${VUS:-150}"
DURATION="${DURATION:-60s}"
RAMP="${RAMP:-10s}"
WRITE_RATIO="${WRITE_RATIO:-0.1}"
ENTITY_COUNT="${ENTITY_COUNT:-100}"

# SLO thresholds — set from problem PDF requirements
P95_THRESHOLD_MS="${P95_THRESHOLD_MS:-500}"
ERROR_RATE_THRESHOLD="${ERROR_RATE_THRESHOLD:-0.01}"
CHECK_RATE_THRESHOLD="${CHECK_RATE_THRESHOLD:-0.95}"

# Resource limits are in docker-compose.benchmark.yml:
#   Service:  2 CPU / 2 GB  (JVM: -XX:ActiveProcessorCount=2 -Xmx1536m)
#   k6:       1 CPU / 512 MB
#   Postgres: 1 CPU / 512 MB
#   Redis:    0.5 CPU / 256 MB  (uncomment in compose if needed)
# If you raise resources, also raise VUS/DURATION above to actually stress them.

MODE="${1:-}"
DOCKER_MODE=false

if [ -z "$MODE" ] || ! echo "$MODE" | grep -Eq '^(baseline|advanced)$'; then
  echo "Usage: $0 <baseline|advanced> [--docker]"
  exit 1
fi

if [ "${2:-}" = "--docker" ]; then
  DOCKER_MODE=true
fi

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Experiment Pipeline: ${MODE}                              ║"
if [ "$DOCKER_MODE" = true ]; then
  echo "║  Runtime: Docker (isolated + resource-limited)             ║"
fi
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# --- Step 1: Build the service -----------------------------------------------
echo "[1/4] Building service (mvn clean package) ..."
echo ""
cd "$PROJECT_ROOT/service"
if ! mvn clean package -DskipTests; then
  echo ""
  echo "ERROR: Maven build failed. Aborting."
  exit 1
fi
echo ""
echo "Build complete."
echo ""

if [ "$DOCKER_MODE" = true ]; then
  # --- Step 2: Docker benchmark --------------------------------------------
  echo "[2/4] Running benchmark in isolated Docker containers ..."
  echo ""
  echo "  Service:  2 CPU / 2 GB"
  echo "  k6:       1 CPU / 512 MB"
  echo "  Postgres: 1 CPU / 512 MB"
  echo ""

  cd "$PROJECT_ROOT"

  # Tear down any previous stack and wipe volumes — ensures clean state
  docker compose -f docker-compose.benchmark.yml down -v >/dev/null 2>&1 || true

  # Ensure evidence directory exists (JFR lands here via volume mount)
  mkdir -p "$PROJECT_ROOT/evidence"
  rm -f "$PROJECT_ROOT/evidence/${MODE}.jfr"

  # Rebuild service image every time — Maven JAR changes but Dockerfile doesn't,
  # so Docker cache would reuse the old layer without --build.
  echo "Building Docker images ..."
  if ! docker compose -f docker-compose.benchmark.yml build service; then
    echo ""
    echo "ERROR: Docker image build failed. Aborting."
    exit 1
  fi

  # Start stack in detached mode, then wait for k6 to finish.
  export MODE VUS DURATION RAMP WRITE_RATIO ENTITY_COUNT P95_THRESHOLD_MS ERROR_RATE_THRESHOLD CHECK_RATE_THRESHOLD
  echo "Starting benchmark stack ..."
  docker compose -f docker-compose.benchmark.yml up -d

  echo "Waiting for k6 to finish ..."
  K6_EXIT=$(docker wait hackathon-k6-bench)

  echo "k6 exited with code ${K6_EXIT}. Stopping service to flush JFR ..."
  # dumponexit=true in JAVA_OPTS flushes the recording on graceful shutdown.
  docker stop --timeout=15 hackathon-service-bench >/dev/null 2>&1 || true

  # Tear down remaining infrastructure and wipe volumes
  docker compose -f docker-compose.benchmark.yml down -v >/dev/null 2>&1 || true

  if [ ! -f "$PROJECT_ROOT/evidence/${MODE}.jfr" ]; then
    echo "ERROR: JFR file not found at evidence/${MODE}.jfr"
    exit 1
  fi

  if [ "$K6_EXIT" -eq 99 ]; then
    echo ""
    echo "WARNING: k6 thresholds breached (exit 99) — SLO violation recorded as evidence."
  elif [ "$K6_EXIT" -ne 0 ]; then
    echo ""
    echo "ERROR: k6 benchmark failed (exit ${K6_EXIT})."
    exit 1
  fi

  echo "JFR file size: $(ls -lh "$PROJECT_ROOT/evidence/${MODE}.jfr" 2>/dev/null || echo 'File not found')"

  echo ""
  echo "Benchmark complete."
  echo ""
else
  # --- Step 2: Native benchmark --------------------------------------------
  echo "[2/4] Running benchmark orchestrator (k6 + JFR) ..."
  echo ""
  cd "$PROJECT_ROOT"
  if ! node benchmarks/orchestrate.js "$MODE"; then
    echo ""
    echo "ERROR: Benchmark orchestrator failed. Aborting."
    exit 1
  fi
  echo ""
  echo "Benchmark complete."
  echo ""
fi

# --- Step 3: Generate k6 report ---------------------------------------------
echo "[3/4] Generating k6 report ..."
echo ""
cd "$PROJECT_ROOT"
if ! node benchmarks/k6-report.js "$MODE"; then
  echo ""
  echo "ERROR: k6 report generation failed."
  exit 1
fi
echo ""

# --- Step 4: Diagnose JFR recording ------------------------------------------
echo "[4/4] Diagnosing JFR recording ..."
echo ""
cd "$PROJECT_ROOT"

if ! ./jfr-diagnose.sh "$MODE"; then
  echo ""
  echo "ERROR: JFR diagnosis failed."
  exit 1
fi

# --- Summary -----------------------------------------------------------------
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Experiment Pipeline Complete: ${MODE}                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Artifacts:"
echo "  JFR file:    evidence/${MODE}.jfr"
echo "  k6 JSON:     evidence/k6-${MODE}.json"
echo "  k6 report:   evidence/k6-${MODE}.md"
echo "  JFR report:  evidence/${MODE}/diagnosis-report-${MODE}.md"
echo "  Raw dumps:   evidence/${MODE}/"
echo ""
