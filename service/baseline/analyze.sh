#!/usr/bin/env bash
#
# Baseline repository quality analyzer — the intentionally naive control.
#
# Answers only shallow yes/no questions about a Java backend repo:
#   1. Does it have a README?
#   2. Does it have a Maven build file?
#   3. Does it have tests?
#   4. Does `mvn package` succeed?
#   5. Does `mvn test` pass?
# and reduces them to a single 0-100 score. No AI, no deep analysis.
#
# Usage:
#   analyze.sh <git-url|local-path> [--out DIR] [--skip-build]
#
# Options:
#   --out DIR      Where to write baseline-report.md / baseline-score.json
#                  and raw maven logs. Default: ./baseline-output
#   --skip-build   Run only the structural checks (1-3). Build and test
#                  checks are reported as SKIP and contribute 0 points.
#                  Used by unit tests so they stay fast and offline.
#
# Env:
#   BUILD_TIMEOUT_SECONDS   Max wall time per maven invocation (default 900).

# Pipeline: invoked per repo by the eval harness (service/eval/evaluate.py) —
# the intentional control the advanced analyzer is measured against.
# Exit codes: 0 ok (any score), 2 usage/environment error.

set -euo pipefail

# Scoring weights. tests/unit/test-baseline.sh asserts against these values;
# change them together.
readonly W_README=10
readonly W_BUILD_FILE=10
readonly W_TESTS_PRESENT=20
readonly W_BUILD_PASSES=25
readonly W_TESTS_PASS=35

readonly BUILD_TIMEOUT_SECONDS="${BUILD_TIMEOUT_SECONDS:-900}"

# --- argument parsing --------------------------------------------------------

TARGET=""
OUT_DIR="baseline-output"
SKIP_BUILD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      [ $# -ge 2 ] || { echo "ERROR: --out requires a directory" >&2; exit 2; }
      OUT_DIR="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        echo "ERROR: unexpected extra argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "ERROR: no target given. Usage: analyze.sh <git-url|local-path> [--out DIR] [--skip-build]" >&2
  exit 2
fi

for tool in git find; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: required tool missing: $tool" >&2; exit 2; }
done

# --- resolve the repository directory ----------------------------------------

WORK_DIR=""
if [ -d "$TARGET" ]; then
  REPO_DIR="$(cd "$TARGET" && pwd)"
else
  WORK_DIR="$(mktemp -d)"
  trap '[ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"' EXIT
  echo ">> Cloning $TARGET"
  git clone --depth 1 --quiet "$TARGET" "$WORK_DIR/repo"
  REPO_DIR="$WORK_DIR/repo"
fi

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

REPO_COMMIT="unknown"
if [ -d "$REPO_DIR/.git" ]; then
  REPO_COMMIT="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

# --- checks ------------------------------------------------------------------
# Each check sets <name>_status to PASS / FAIL / SKIP and <name>_points.

# Check 1: README at repository root (any common extension, any case).
readme_status=FAIL
if find "$REPO_DIR" -maxdepth 1 -type f -iname 'readme*' | grep -q .; then
  readme_status=PASS
fi

# Check 2: Maven build file. Naive on purpose: Gradle-only repos fail here.
build_file_status=FAIL
if [ -f "$REPO_DIR/pom.xml" ]; then
  build_file_status=PASS
fi

# Check 3: at least one test source under a standard Maven test directory.
test_file_count="$(find "$REPO_DIR" -path '*/src/test/*' -name '*.java' -type f | wc -l | tr -d ' ')"
tests_present_status=FAIL
if [ "$test_file_count" -gt 0 ]; then
  tests_present_status=PASS
fi

# Checks 4-5: real Maven invocations. Logs are kept as evidence.
build_passes_status=SKIP
tests_pass_status=SKIP
if [ "$SKIP_BUILD" -eq 1 ]; then
  : # structural-only mode, both stay SKIP
elif [ "$build_file_status" != PASS ]; then
  build_passes_status=FAIL
  tests_pass_status=FAIL
elif ! command -v mvn >/dev/null 2>&1; then
  echo "ERROR: mvn not found; install Maven or run with --skip-build" >&2
  exit 2
else
  echo ">> Running mvn package (timeout ${BUILD_TIMEOUT_SECONDS}s, log: $OUT_DIR/build.log)"
  if (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B -q -DskipTests package) \
      >"$OUT_DIR/build.log" 2>&1; then
    build_passes_status=PASS
  else
    build_passes_status=FAIL
  fi

  if [ "$build_passes_status" = PASS ]; then
    echo ">> Running mvn test (timeout ${BUILD_TIMEOUT_SECONDS}s, log: $OUT_DIR/test.log)"
    if (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B -q test) \
        >"$OUT_DIR/test.log" 2>&1; then
      tests_pass_status=PASS
    else
      tests_pass_status=FAIL
    fi
  else
    tests_pass_status=FAIL
  fi
fi

points_for() {
  # $1 = status, $2 = weight
  if [ "$1" = PASS ]; then
    echo "$2"
  else
    echo 0
  fi
}

readme_points="$(points_for "$readme_status" "$W_README")"
build_file_points="$(points_for "$build_file_status" "$W_BUILD_FILE")"
tests_present_points="$(points_for "$tests_present_status" "$W_TESTS_PRESENT")"
build_passes_points="$(points_for "$build_passes_status" "$W_BUILD_PASSES")"
tests_pass_points="$(points_for "$tests_pass_status" "$W_TESTS_PASS")"

total_score=$((readme_points + build_file_points + tests_present_points \
              + build_passes_points + tests_pass_points))

# --- report ------------------------------------------------------------------

report_file="$OUT_DIR/baseline-report.md"
{
  echo "# Baseline Quality Report (naive)"
  echo
  echo "- Target: $TARGET"
  echo "- Commit: $REPO_COMMIT"
  echo "- Date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Analyzer: service/baseline/analyze.sh (no AI, shallow checks only)"
  echo
  echo "| Check | Weight | Result | Points |"
  echo "|-------|--------|--------|--------|"
  echo "| README present | $W_README | $readme_status | $readme_points |"
  echo "| Maven build file (pom.xml) | $W_BUILD_FILE | $build_file_status | $build_file_points |"
  echo "| Tests present ($test_file_count test files) | $W_TESTS_PRESENT | $tests_present_status | $tests_present_points |"
  echo "| Build passes (mvn package) | $W_BUILD_PASSES | $build_passes_status | $build_passes_points |"
  echo "| Tests pass (mvn test) | $W_TESTS_PASS | $tests_pass_status | $tests_pass_points |"
  echo
  echo "**Score: $total_score/100**"
} > "$report_file"

score_file="$OUT_DIR/baseline-score.json"
cat > "$score_file" <<EOF
{
  "target": "$TARGET",
  "commit": "$REPO_COMMIT",
  "analyzer": "baseline",
  "score": $total_score,
  "maxScore": 100,
  "checks": {
    "readme":        { "weight": $W_README,        "status": "$readme_status",        "points": $readme_points },
    "buildFile":     { "weight": $W_BUILD_FILE,     "status": "$build_file_status",    "points": $build_file_points },
    "testsPresent":  { "weight": $W_TESTS_PRESENT,  "status": "$tests_present_status", "points": $tests_present_points, "testFileCount": $test_file_count },
    "buildPasses":   { "weight": $W_BUILD_PASSES,   "status": "$build_passes_status",  "points": $build_passes_points },
    "testsPass":     { "weight": $W_TESTS_PASS,     "status": "$tests_pass_status",    "points": $tests_pass_points }
  }
}
EOF

echo
cat "$report_file"
echo
echo ">> Wrote $report_file"
echo ">> Wrote $score_file"
