#!/bin/bash
set -uo pipefail

# ============================================================================
# Experiment Pipeline: Build TARGET → Benchmark → Report → (h3: Diagnose)
# ============================================================================
# h2 re-point (2026-08-29, exp/h2-k6-generation): the measured subject is a
# TARGET repo. The old `baseline|advanced` MODE (two variants of our own
# service) is gone — that service no longer exists in this repo.
#
# Usage:
#   ./run-experiment.sh <git-url|local-path> [--docker] [--skip-build]
#
# Prereq: a committed k6 script + slots for the target must exist at
#   evidence/advanced/h2/<repo>/{load-test.js,slots.json}
# (generated via service/advanced/gen-k6.py — generation is a separate,
# earlier step and is never part of this pipeline).
#
# Native mode (default, dev iteration):
#   1. mvn package at the target's root
#   2. node benchmarks/orchestrate.js  (boot target jar, smoke gate, k6 full)
#   3. node benchmarks/k6-report.js    (fixed-shape load report)
#
# Docker mode (--docker, OFFICIAL measured runs — identical resource envelope
# for every target, see service/advanced/docker/h2-target.yml):
#   1. mvn package at the target's root
#   2. docker build (generic Dockerfile.target) + compose up service + the
#      infra addendums from the target's slots.json ("infra": mysql/postgres/redis)
#   3. smoke gate (2 VUs/5s) → full k6 run, both in the k6 container
#   4. node benchmarks/k6-report.js
#
# Findings: a target that cannot be built/booted/load-tested is NOT a harness
# failure — the pipeline writes a NOT_TESTABLE load report and exits 3.
#
# h3 seam: JFR_OPTS (compose) + jfr-diagnose.sh join here in exp/h3.
#
# Exit codes: 0 measured (any threshold verdict), 2 usage/environment error,
#             3 could not load-test (a finding).
# ============================================================================

SMOKE_VUS=2
SMOKE_DURATION=5s
SMOKE_RAMP=1s
SMOKE_ENTITY_COUNT=3

TARGET=""
DOCKER_MODE=false
SKIP_BUILD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --docker) DOCKER_MODE=true; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    -h|--help) sed -n '2,37p' "$0"; exit 0 ;;
    -*) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
    *)
      if [ -z "$TARGET" ]; then TARGET="$1"
      else echo "ERROR: unexpected extra argument: $1" >&2; exit 2; fi
      shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <git-url|local-path> [--docker] [--skip-build]"
  exit 2
fi

for tool in git python node curl; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: required tool missing: $tool" >&2; exit 2; }
done

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$TARGET" .git)"
EVIDENCE_DIR="$PROJECT_ROOT/evidence/advanced/h2/$NAME"
SLOTS="$EVIDENCE_DIR/slots.json"
K6_SCRIPT="$EVIDENCE_DIR/load-test.js"

if [ ! -f "$K6_SCRIPT" ] || [ ! -f "$SLOTS" ]; then
  echo "ERROR: no committed k6 script/slots for '$NAME' under $EVIDENCE_DIR" >&2
  echo "Generate + commit them first (service/advanced/gen-k6.py)." >&2
  exit 2
fi

finding() { # <reason> — record a could-not-load-test finding and exit 3
  echo ">> FINDING: $1"
  node "$PROJECT_ROOT/benchmarks/k6-report.js" --finding "$1" \
    --repo "$NAME" --out "$EVIDENCE_DIR" || true
  exit 3
}

# --- resolve the repository directory ----------------------------------------

WORK_DIR=""
if [ -d "$TARGET" ]; then
  REPO_DIR="$(cd "$TARGET" && pwd)"
else
  WORK_DIR="$(mktemp -d)"
  echo ">> Cloning $TARGET"
  git clone --depth 1 --quiet "$TARGET" "$WORK_DIR/repo" || {
    echo "ERROR: clone failed" >&2; exit 2; }
  REPO_DIR="$WORK_DIR/repo"
fi

COMPOSE_FILES=()
cleanup() {
  if [ "$DOCKER_MODE" = true ] && [ ${#COMPOSE_FILES[@]} -gt 0 ]; then
    docker compose "${COMPOSE_FILES[@]}" down -v >/dev/null 2>&1 || true
  fi
  [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# --- Step 1: build the target -------------------------------------------------

JAR=""
if [ "$SKIP_BUILD" -eq 0 ]; then
  [ -f "$REPO_DIR/pom.xml" ] || finding "no pom.xml at repo root"
  command -v mvn >/dev/null 2>&1 || { echo "ERROR: mvn not found" >&2; exit 2; }
  echo "[1/3] Building target $NAME (mvn package, log: $EVIDENCE_DIR/build.log) ..."
  if ! (cd "$REPO_DIR" && timeout "${BUILD_TIMEOUT_SECONDS:-900}" mvn -B -q -DskipTests package) \
      >"$EVIDENCE_DIR/build.log" 2>&1; then
    finding "mvn package failed (see build.log)"
  fi
else
  echo "[1/3] --skip-build: reusing existing jar"
fi

# Bootable jar heuristic: largest jar under target/ (boot jars bundle deps).
JAR="$(find "$REPO_DIR" -path '*/target/*.jar' -type f \
  ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' \
  -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
[ -n "$JAR" ] || finding "no jar under target/ after build"

if [ "$DOCKER_MODE" = true ]; then
  # --- Step 2 (docker): image + stack + smoke gate + full run ----------------
  echo "[2/3] Docker benchmark for $NAME (resource-limited envelope) ..."

  TARGET_ENV_FILE="$EVIDENCE_DIR/target.env"
  # Writes target.env (SERVER_PORT + slots.bootEnv) and prints shell setup:
  # COMPOSE_FILES (h2-target.yml + one addendum per slots.infra entry),
  # plus slots.infraEnv entries as exports.
  eval "$(python - "$SLOTS" "$TARGET_ENV_FILE" "$PROJECT_ROOT" <<'PY'
import json, shlex, sys
slots = json.load(open(sys.argv[1]))
env = {"SERVER_PORT": "8080", **slots.get("bootEnv", {})}
with open(sys.argv[2], "w", newline="\n") as f:
    f.write("\n".join(f"{k}={v}" for k, v in env.items()) + "\n")
docker_dir = f"{sys.argv[3]}/service/advanced/docker"
files = [f"{docker_dir}/h2-target.yml"] + [
    f"{docker_dir}/h2-{i}.yml" for i in slots.get("infra", [])]
print("COMPOSE_FILES=(" + " ".join(
    shlex.quote("-f") + " " + shlex.quote(p) for p in files) + ")")
for k, v in slots.get("infraEnv", {}).items():
    print(f"export {k}={shlex.quote(str(v))}")
PY
)"

  export REPO="$NAME"
  export JAR_FILE="${JAR#"$REPO_DIR"/}"
  # Docker on Windows needs Windows-style host paths; Git Bash uses /c/...
  export REPO_DIR="$(cygpath -w "$REPO_DIR" 2>/dev/null || echo "$REPO_DIR")"
  export PROJECT_ROOT_WIN="$(cygpath -w "$PROJECT_ROOT" 2>/dev/null || echo "$PROJECT_ROOT")"
  export DOCKERFILE_TARGET="$(cygpath -w "$PROJECT_ROOT/service/advanced/docker/Dockerfile.target" 2>/dev/null || echo "$PROJECT_ROOT/service/advanced/docker/Dockerfile.target")"
  export TARGET_ENV_FILE="$(cygpath -w "$TARGET_ENV_FILE" 2>/dev/null || echo "$TARGET_ENV_FILE")"
  for i in "${!COMPOSE_FILES[@]}"; do
    case "${COMPOSE_FILES[$i]}" in
      /*) COMPOSE_FILES[$i]="$(cygpath -w "${COMPOSE_FILES[$i]}" 2>/dev/null || echo "${COMPOSE_FILES[$i]}")" ;;
    esac
  done

  COMPOSE=(docker compose "${COMPOSE_FILES[@]}")

  "${COMPOSE[@]}" build service || finding "docker image build failed"
  "${COMPOSE[@]}" up -d --wait --wait-timeout 240 service \
    || finding "target did not become healthy in docker"

  echo ">> Smoke gate (${SMOKE_VUS} VUs, ${SMOKE_DURATION}; validates the committed script)"
  "${COMPOSE[@]}" run --rm \
    -e K6_VUS=$SMOKE_VUS -e K6_DURATION=$SMOKE_DURATION -e K6_RAMP=$SMOKE_RAMP \
    -e K6_ENTITY_COUNT=$SMOKE_ENTITY_COUNT \
    -e K6_JSON_OUT="/hackathon/evidence/advanced/h2/$NAME/k6-smoke.json" \
    k6 || true
  if ! python - "$EVIDENCE_DIR/k6-smoke.json" <<'PY'
import json, sys
try:
    m = json.load(open(sys.argv[1])).get("metrics", {})
except Exception:
    sys.exit(1)
reqs = (m.get("http_reqs") or {}).get("values", {}).get("count", 0)
checks = (m.get("checks") or {}).get("values", {}).get("rate", 0)
sys.exit(0 if reqs > 0 and checks > 0 else 1)
PY
  then
    finding "smoke gate failed: setup did not complete; the scenario is not valid for this repo"
  fi

  echo ">> Full run (fixed profile from committed script)"
  "${COMPOSE[@]}" run --rm \
    -e K6_JSON_OUT="/hackathon/evidence/advanced/h2/$NAME/k6-full.json" \
    k6
  K6_RC=$?
else
  # --- Step 2 (native): boot target jar + smoke gate + full run --------------
  echo "[2/3] Native benchmark for $NAME (dev iteration; official runs use --docker) ..."
  REPO_DIR="$REPO_DIR" TARGET_JAR="$JAR" K6_SCRIPT="$K6_SCRIPT" \
  EVIDENCE_DIR="$EVIDENCE_DIR" REPO="$NAME" \
    node "$PROJECT_ROOT/benchmarks/orchestrate.js"
  K6_RC=$?
fi

# k6 exits 99 when thresholds are breached: a measured FAIL verdict, still a
# successful measurement. Any other non-zero is a pipeline error.
if [ "$K6_RC" -ne 0 ] && [ "$K6_RC" -ne 99 ]; then
  echo "ERROR: benchmark failed (exit $K6_RC)." >&2
  exit 2
fi

# --- Step 3: fixed-shape load report -------------------------------------------
echo "[3/3] Generating load report ..."
node "$PROJECT_ROOT/benchmarks/k6-report.js" \
  "$EVIDENCE_DIR/k6-full.json" --repo "$NAME" --out "$EVIDENCE_DIR" \
  || { echo "ERROR: report generation failed." >&2; exit 2; }

echo ""
echo "Pipeline complete: $NAME (k6 exit $K6_RC)"
echo "Artifacts: $EVIDENCE_DIR/{k6-smoke.json,k6-full.json,load-report.json,load-report.md}"
