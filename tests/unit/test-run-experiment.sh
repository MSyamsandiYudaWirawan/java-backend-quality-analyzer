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

# --- summary ------------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) FAILED."
  exit 1
fi
echo
echo "All unit tests passed."
