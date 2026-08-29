#!/bin/bash
set -uo pipefail

# ============================================================================
# Experiment Pipeline: Build TARGET → Benchmark → Report → (h3: JFR Diagnose)
# ============================================================================
# h2 re-point (2026-08-29, exp/h2-k6-generation): the measured subject is a
# TARGET repo. The old `baseline|advanced` MODE (two variants of our own
# service) is gone — that service no longer exists in this repo.
#
# Usage:
#   ./run-experiment.sh <git-url|local-path> [--docker] [--skip-build] [--jfr]
#
# Prereq: a committed k6 script + slots for the target must exist at
#   evidence/advanced/h2/<repo>/{load-test.js,slots.json}
# (generated via service/advanced/gen-k6.py — generation is a separate,
# earlier step and is never part of this pipeline). Committed inputs stay in
# h2/ and are never rewritten; --jfr writes all run outputs to h3/<repo>/.
#
# Boot jar selection: an optional "jarGlob" in slots.json pins the boot jar
# as */target/<jarGlob> — needed for multi-module repos where the largest
# jar is the wrong module. Without it, the largest jar under target/ boots.
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
# h3 (--jfr, docker mode only): the service boots with an in-memory JFR
# recording (settings=profile, dumponexit) flushed to
# evidence/advanced/h3/<repo>/profile.jfr on graceful stop. After the full k6
# run the service is stopped and jfr-diagnose.sh produces the hypothesis
# report at h3/<repo>/jfr/diagnosis-report.md. k6 outputs also land in
# h3/<repo>/ so the h2 evidence stays immutable. Runtime scoring grades on
# k6 + JFR together.
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
JFR_MODE=false
SKIP_BUILD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --docker) DOCKER_MODE=true; shift ;;
    --jfr) JFR_MODE=true; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    -h|--help) sed -n '2,43p' "$0"; exit 0 ;;
    -*) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
    *)
      if [ -z "$TARGET" ]; then TARGET="$1"
      else echo "ERROR: unexpected extra argument: $1" >&2; exit 2; fi
      shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <git-url|local-path> [--docker] [--skip-build] [--jfr]"
  exit 2
fi

# JFR profiling rides on the docker resource envelope; native mode has no
# JAVA_OPTS wiring into orchestrate.js.
if [ "$JFR_MODE" = true ] && [ "$DOCKER_MODE" = false ]; then
  echo "ERROR: --jfr requires --docker (h3 measured runs use the docker envelope)" >&2
  exit 2
fi

for tool in git python node curl; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: required tool missing: $tool" >&2; exit 2; }
done

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$TARGET" .git)"
# Committed k6 script + slots always live in h2/ (immutable evidence); --jfr
# only changes where run OUTPUTS land (h3/), never the inputs.
SCRIPT_DIR="$PROJECT_ROOT/evidence/advanced/h2/$NAME"
SLOTS="$SCRIPT_DIR/slots.json"
K6_SCRIPT="$SCRIPT_DIR/load-test.js"

if [ "$JFR_MODE" = true ]; then
  PROFILE=h3
else
  PROFILE=h2
fi
EVIDENCE_DIR="$PROJECT_ROOT/evidence/advanced/$PROFILE/$NAME"

if [ ! -f "$K6_SCRIPT" ] || [ ! -f "$SLOTS" ]; then
  echo "ERROR: no committed k6 script/slots for '$NAME' under $SCRIPT_DIR" >&2
  echo "Generate + commit them first (service/advanced/gen-k6.py)." >&2
  exit 2
fi
mkdir -p "$EVIDENCE_DIR"

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

# Bootable jar selection: slots.jarGlob pins the module (multi-module repos
# where the largest jar is the wrong one); otherwise the largest jar under
# target/ wins (boot jars bundle deps).
JAR_GLOB="$(python -c 'import json, sys; print(json.load(open(sys.argv[1])).get("jarGlob", ""))' "$SLOTS")"
if [ -n "$JAR_GLOB" ]; then
  JAR="$(find "$REPO_DIR" -path "*/target/$JAR_GLOB" -type f \
    ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' | head -1)"
  [ -n "$JAR" ] || finding "jarGlob '$JAR_GLOB' matched no jar under target/ (see build.log)"
else
  JAR="$(find "$REPO_DIR" -path '*/target/*.jar' -type f \
    ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' \
    -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
  [ -n "$JAR" ] || finding "no jar under target/ after build"
fi

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
  if [ "$JFR_MODE" = true ]; then
    # h3: in-memory recording (NO disk=true — JFR's disk-chunk writes fail on
    # Docker Desktop's Windows bind mount), dumponexit flushes the finished
    # file straight to the evidence mount on graceful shutdown (compose stop
    # below — temurin JRE has no jcmd for live dumps). Same recipe as the
    # pre-existing docker-compose.benchmark.yml.
    export JFR_OPTS="-XX:StartFlightRecording=name=h3,settings=profile,dumponexit=true,filename=/jfr-repo/advanced/h3/$NAME/profile.jfr"
  fi
  for i in "${!COMPOSE_FILES[@]}"; do
    case "${COMPOSE_FILES[$i]}" in
      /*) COMPOSE_FILES[$i]="$(cygpath -w "${COMPOSE_FILES[$i]}" 2>/dev/null || echo "${COMPOSE_FILES[$i]}")" ;;
    esac
  done

  # MSYS_NO_PATHCONV=1 on every compose call (via env in the array): Git Bash
  # rewrites POSIX-looking env values ('/hackathon/...', and now JFR_OPTS's
  # '/jfr-repo/...') into 'C:/Program Files/Git/...' when spawning docker.exe
  # — the Windows path-mangling bug class (trajectories 2026-08-28_23-32,
  # 2026-08-29_11-37; h2 patched only the k6 `compose run` calls, h3's
  # JFR_OPTS hit the same mangling on `up`). Scoped to compose so node/python
  # calls keep normal /c/... conversion.
  COMPOSE=(env MSYS_NO_PATHCONV=1 docker compose "${COMPOSE_FILES[@]}")

  "${COMPOSE[@]}" build service || finding "docker image build failed"
  "${COMPOSE[@]}" up -d --wait --wait-timeout 240 service \
    || finding "target did not become healthy in docker"

  echo ">> Smoke gate (${SMOKE_VUS} VUs, ${SMOKE_DURATION}; validates the committed script)"
  "${COMPOSE[@]}" run --rm \
    -e K6_VUS=$SMOKE_VUS -e K6_DURATION=$SMOKE_DURATION -e K6_RAMP=$SMOKE_RAMP \
    -e K6_ENTITY_COUNT=$SMOKE_ENTITY_COUNT \
    -e K6_JSON_OUT="/hackathon/evidence/advanced/$PROFILE/$NAME/k6-smoke.json" \
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
    -e K6_JSON_OUT="/hackathon/evidence/advanced/$PROFILE/$NAME/k6-full.json" \
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

# --- h3: finalize the JFR recording and diagnose -------------------------------
if [ "$JFR_MODE" = true ]; then
  # Stopping the service (SIGTERM, 15s grace) makes the JVM flush the
  # recording to the evidence mount via dumponexit — the trap's compose down
  # removes the container afterwards.
  echo "[h3] Stopping service to finalize the JFR recording ..."
  "${COMPOSE[@]}" stop service >/dev/null 2>&1 || true

  JFR_FILE="$EVIDENCE_DIR/profile.jfr"
  if [ -s "$JFR_FILE" ]; then
    echo "[h3] Diagnosing $JFR_FILE ..."
    bash "$PROJECT_ROOT/jfr-diagnose.sh" -o "$EVIDENCE_DIR/jfr" -n diagnosis \
      "$JFR_FILE" || echo "WARNING: jfr-diagnose failed; JFR evidence incomplete" >&2
  else
    echo "WARNING: no JFR recording at $JFR_FILE (k6 evidence still valid)" >&2
  fi
fi

echo ""
echo "Pipeline complete: $NAME (k6 exit $K6_RC)"
if [ "$JFR_MODE" = true ]; then
  echo "Artifacts: $EVIDENCE_DIR/{k6-smoke.json,k6-full.json,load-report.json,load-report.md,profile.jfr,jfr/}"
else
  echo "Artifacts: $EVIDENCE_DIR/{k6-smoke.json,k6-full.json,load-report.json,load-report.md}"
fi
