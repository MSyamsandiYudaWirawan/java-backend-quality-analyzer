#!/usr/bin/env bash
#
# Fast, offline unit tests for run-experiment.sh argument handling and
# the committed-script prerequisite. No Maven, no docker, no network.
#
# Usage: tests/unit/test-run-experiment.sh   (from the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PIPELINE="$REPO_ROOT/run-experiment.sh"

failures=0

assert_exit_code() {
  if [ "$1" -eq "$2" ]; then
    echo "PASS: $3"
  else
    echo "FAIL: $3 (expected exit $1, got $2)"
    failures=$((failures + 1))
  fi
}

# --- Case 1: no target -> exit 2 -----------------------------------------------------
code=0
"$PIPELINE" >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "no target argument exits with code 2"

# --- Case 2: unknown option -> exit 2 --------------------------------------------------
code=0
"$PIPELINE" --bogus >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "unknown option exits with code 2"

# --- Case 3: old baseline/advanced MODE is gone ----------------------------------------
code=0
"$PIPELINE" baseline >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "legacy 'baseline' mode is rejected (no committed script for it)"

# --- Case 4: target without a committed k6 script -> exit 2 -----------------------------
code=0
"$PIPELINE" "$REPO_ROOT/tests/unit/fixtures/bare-repo" >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "target without committed script/slots exits with code 2"

# --- Case 5: extra positional argument -> exit 2 ----------------------------------------
code=0
"$PIPELINE" a b >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "unexpected extra argument exits with code 2"

# --- Case 6: --jfr without --docker -> exit 2 -------------------------------------------
code=0
"$PIPELINE" some-target --jfr >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "--jfr without --docker exits with code 2"

# --- Case 7: --jfr --docker without committed script -> exit 2, no h3 dir leaked ---------
code=0
"$PIPELINE" "$REPO_ROOT/tests/unit/fixtures/bare-repo" --jfr --docker >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "--jfr --docker without committed script/slots exits with code 2"
if [ ! -d "$REPO_ROOT/evidence/advanced/h3/bare-repo" ]; then
  echo "PASS: failed --jfr lookup leaves no h3 evidence dir"
else
  echo "FAIL: failed --jfr lookup leaves no h3 evidence dir"
  failures=$((failures + 1))
  rm -rf "$REPO_ROOT/evidence/advanced/h3/bare-repo"
fi

# --- Case 8: slots.jarGlob matching nothing -> finding, exit 3 ---------------------------
# The fixture repo + evidence are created at runtime and removed afterwards:
# *.jar and */target/ are gitignored, so a committed fixture jar would vanish.
FAKE_NAME="jarglob-repo"
FAKE_REPO="$REPO_ROOT/tests/unit/fixtures/$FAKE_NAME"
FAKE_EVIDENCE="$REPO_ROOT/evidence/advanced/h2/$FAKE_NAME"
mkdir -p "$FAKE_REPO/target" "$FAKE_EVIDENCE"
: > "$FAKE_REPO/target/decoy-1.0.0.jar"   # heuristic would pick it; the glob must not
cat > "$FAKE_EVIDENCE/slots.json" <<'JSON'
{"repoName": "jarglob-repo", "jarGlob": "no-such-module-*.jar"}
JSON
echo "// runtime fixture" > "$FAKE_EVIDENCE/load-test.js"
code=0
"$PIPELINE" "$FAKE_REPO" --skip-build >/dev/null 2>&1 || code=$?
assert_exit_code 3 "$code" "jarGlob matching no jar under target/ exits with code 3 (finding)"
rm -rf "$FAKE_REPO" "$FAKE_EVIDENCE"

# --- summary ------------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) FAILED."
  exit 1
fi
echo
echo "All unit tests passed."
