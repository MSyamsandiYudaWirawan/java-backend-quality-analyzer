#!/usr/bin/env bash
#
# h1 evidence collector — mechanical evidence gathering for the advanced
# analyzer (exp/h1-rubric-scoring, Option A design).
#
# Collects ONLY mechanical facts about a Java backend repo; it makes no
# quality judgments. The agent reads the collected evidence and scores the
# rubric (service/rubric/quality-rubric.md) separately.
#
# Per repo, writes into the out dir:
#   build.log              mvn package output (unless --skip-build)
#   test.log               mvn test output (unless --skip-build)
#   surefire-summary.txt   parsed "Tests run:" lines from test.log
#   test-census.txt        main/test source counts, LOC, assertion counts
#   package-tree.txt       src/main/java package layout with file counts
#   largest-classes.txt    top 20 Java files by LOC (god-class evidence)
#   dependency-analyze.log mvn dependency:analyze (unused/undeclared deps)
#   dependency-list.txt    mvn dependency:list (resolved dep versions)
#   repo-scan.txt          README/license/config/binaries/secrets scan
#   collect-manifest.json  machine-readable summary of all of the above
#
# Usage:
#   collect.sh <git-url|local-path> [--out DIR] [--skip-build]
#
# Options:
#   --out DIR      Where to write the evidence files. Default: ./collect-output
#   --skip-build   Structural scan only; no Maven invocations. Build/test
#                  and dependency evidence are marked SKIP in the manifest.
#                  Used by unit tests so they stay fast and offline.
#
# Env:
#   BUILD_TIMEOUT_SECONDS   Max wall time per maven invocation (default 900).

set -euo pipefail

readonly BUILD_TIMEOUT_SECONDS="${BUILD_TIMEOUT_SECONDS:-900}"

# --- argument parsing --------------------------------------------------------

TARGET=""
OUT_DIR="collect-output"
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
      sed -n '2,33p' "$0"
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
  echo "ERROR: no target given. Usage: collect.sh <git-url|local-path> [--out DIR] [--skip-build]" >&2
  exit 2
fi

for tool in git find wc; do
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

has_pom=0
[ -f "$REPO_DIR/pom.xml" ] && has_pom=1

# --- maven evidence ----------------------------------------------------------

build_status=SKIP
test_status=SKIP
deps_status=SKIP

if [ "$SKIP_BUILD" -eq 0 ]; then
  if [ "$has_pom" -eq 0 ]; then
    build_status=FAIL
    test_status=FAIL
    deps_status=FAIL
    echo ">> No pom.xml at repo root; maven evidence marked FAIL"
  elif ! command -v mvn >/dev/null 2>&1; then
    echo "ERROR: mvn not found; install Maven or run with --skip-build" >&2
    exit 2
  else
    echo ">> Running mvn package (timeout ${BUILD_TIMEOUT_SECONDS}s, log: $OUT_DIR/build.log)"
    if (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B -q -DskipTests package) \
        >"$OUT_DIR/build.log" 2>&1; then
      build_status=PASS
    else
      build_status=FAIL
    fi

    if [ "$build_status" = PASS ]; then
      echo ">> Running mvn test (timeout ${BUILD_TIMEOUT_SECONDS}s, log: $OUT_DIR/test.log)"
      if (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B -q test) \
          >"$OUT_DIR/test.log" 2>&1; then
        test_status=PASS
      else
        test_status=FAIL
      fi

      echo ">> Running mvn dependency:analyze / dependency:list"
      # No -q here: -q suppresses the dependency plugin's report output.
      if (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B dependency:analyze) \
          >"$OUT_DIR/dependency-analyze.log" 2>&1; then
        deps_status=PASS
      else
        deps_status=FAIL
      fi
      (cd "$REPO_DIR" && timeout "$BUILD_TIMEOUT_SECONDS" mvn -B dependency:list) \
          >"$OUT_DIR/dependency-list.txt" 2>&1 || true
    else
      test_status=FAIL
      deps_status=FAIL
    fi
  fi
fi

# --- surefire summary ----------------------------------------------------------

surefire_file="$OUT_DIR/surefire-summary.txt"
: > "$surefire_file"
if [ "$test_status" != SKIP ] && [ -f "$OUT_DIR/test.log" ]; then
  grep -E 'Tests run:|BUILD (SUCCESS|FAILURE)|ERROR.*(FAIL|Failed)' "$OUT_DIR/test.log" \
    > "$surefire_file" || true
fi

# --- test census ---------------------------------------------------------------

main_files="$(find "$REPO_DIR" -path '*/src/main/java/*' -name '*.java' -type f | wc -l | tr -d ' ')"
test_files="$(find "$REPO_DIR" -path '*/src/test/java/*' -name '*.java' -type f | wc -l | tr -d ' ')"
main_loc="$(find "$REPO_DIR" -path '*/src/main/java/*' -name '*.java' -type f -print0 | xargs -0 -r cat 2>/dev/null | wc -l | tr -d ' ')"
test_loc="$(find "$REPO_DIR" -path '*/src/test/java/*' -name '*.java' -type f -print0 | xargs -0 -r cat 2>/dev/null | wc -l | tr -d ' ')"
assert_count=0
if [ "$test_files" -gt 0 ]; then
  # grep exits 1 (and xargs then 123) when nothing matches; swallow that so
  # set -e + pipefail do not abort on a legitimately assertion-free suite.
  assert_count="$( { find "$REPO_DIR" -path '*/src/test/java/*' -name '*.java' -type f -print0 \
    | xargs -0 -r grep -hoE 'assert(That|Equals|True|False|Null|NotNull|Throws|ArrayEquals|Same|NotSame)|verify\(' \
    || true; } | wc -l | tr -d ' ')"
fi

census_file="$OUT_DIR/test-census.txt"
{
  echo "main_java_files=$main_files"
  echo "test_java_files=$test_files"
  echo "main_loc=$main_loc"
  echo "test_loc=$test_loc"
  echo "assertion_calls=$assert_count"
} > "$census_file"

# --- package tree ----------------------------------------------------------------

tree_file="$OUT_DIR/package-tree.txt"
{
  echo "# Java packages under src/main/java (file counts per directory)"
  find "$REPO_DIR" -path '*/src/main/java/*' -name '*.java' -type f \
    | sed "s|^$REPO_DIR/||; s|/[^/]*\.java$||" \
    | sort | uniq -c | sort -k2
  echo
  echo "# Java packages under src/test/java (file counts per directory)"
  find "$REPO_DIR" -path '*/src/test/java/*' -name '*.java' -type f \
    | sed "s|^$REPO_DIR/||; s|/[^/]*\.java$||" \
    | sort | uniq -c | sort -k2
} > "$tree_file"

# --- largest classes ---------------------------------------------------------------

largest_file="$OUT_DIR/largest-classes.txt"
{
  echo "# Top 20 Java files by LOC (path LOC)"
  { find "$REPO_DIR" -name '*.java' -type f -not -path '*/target/*' -print0 \
    | xargs -0 -r wc -l \
    | grep -v ' total$' || true; } \
    | sort -rn | head -20 \
    | awk '{path=$2; for(i=3;i<=NF;i++) path=path" "$i; printf "%s %s\n", path, $1}' \
    | sed "s|^$REPO_DIR/||"
} > "$largest_file"

# --- repo scan -----------------------------------------------------------------------

scan_file="$OUT_DIR/repo-scan.txt"
{
  echo "# README files at repo root (size in bytes)"
  find "$REPO_DIR" -maxdepth 1 -type f -iname 'readme*' -printf '%f %s\n' 2>/dev/null \
    || find "$REPO_DIR" -maxdepth 1 -type f -iname 'readme*' | while read -r f; do
         echo "$(basename "$f") $(wc -c < "$f" | tr -d ' ')"
       done
  echo
  echo "# License files at repo root"
  find "$REPO_DIR" -maxdepth 1 -type f \( -iname 'license*' -o -iname 'copying*' -o -iname 'notice*' \) \
    | sed "s|^$REPO_DIR/||"
  echo
  echo "# Config files (application*.properties/yml/yaml, excluding target/)"
  find "$REPO_DIR" -type f \( -name 'application*.properties' -o -name 'application*.yml' -o -name 'application*.yaml' \) \
    -not -path '*/target/*' | sed "s|^$REPO_DIR/||"
  echo
  echo "# Committed binaries (jar/class/war/ear, excluding target/)"
  find "$REPO_DIR" -type f \( -name '*.jar' -o -name '*.class' -o -name '*.war' -o -name '*.ear' \) \
    -not -path '*/target/*' | sed "s|^$REPO_DIR/||"
  echo
  echo "# Suspicious secret-looking lines in tracked config/source (password|secret|apikey|token = <value>)"
  { find "$REPO_DIR" -type f \( -name '*.properties' -o -name '*.yml' -o -name '*.yaml' \) \
    -not -path '*/target/*' -print0 \
    | xargs -0 -r grep -inE '(password|secret|api[-_]?key|token)[[:space:]]*[:=][[:space:]]*[^[:space:]#]' \
    || true; } | sed "s|^$REPO_DIR/||" | head -50
} > "$scan_file"

# --- manifest -------------------------------------------------------------------------

manifest_file="$OUT_DIR/collect-manifest.json"
cat > "$manifest_file" <<EOF
{
  "target": "$TARGET",
  "commit": "$REPO_COMMIT",
  "collector": "service/advanced/collect.sh (h1, mechanical facts only)",
  "dateUtc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hasPom": $has_pom,
  "buildStatus": "$build_status",
  "testStatus": "$test_status",
  "depsStatus": "$deps_status",
  "mainJavaFiles": $main_files,
  "testJavaFiles": $test_files,
  "mainLoc": $main_loc,
  "testLoc": $test_loc,
  "assertionCalls": $assert_count
}
EOF

echo
echo ">> Evidence written to $OUT_DIR"
echo "   build=$build_status test=$test_status deps=$deps_status main_files=$main_files test_files=$test_files"
