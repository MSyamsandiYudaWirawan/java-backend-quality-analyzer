#!/usr/bin/env bash
#
# Fast, offline unit tests for service/baseline/analyze.sh.
# Runs the analyzer with --skip-build against committed fixture repos and
# asserts the structural score. Build/test behavior is covered separately
# by the end-to-end run against spring-petclinic (see evidence/baseline/).
#
# Usage: tests/unit/test-baseline.sh   (from the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ANALYZER="$REPO_ROOT/service/baseline/analyze.sh"
FIXTURES="$REPO_ROOT/tests/unit/fixtures"

failures=0

assert_file_contains() {
  # $1 = file, $2 = expected substring, $3 = test name
  if grep -qF "$2" "$1"; then
    echo "PASS: $3"
  else
    echo "FAIL: $3"
    echo "  expected to find in $1: $2"
    failures=$((failures + 1))
  fi
}

assert_exit_code() {
  # $1 = expected code, $2 = actual code, $3 = test name
  if [ "$1" -eq "$2" ]; then
    echo "PASS: $3"
  else
    echo "FAIL: $3 (expected exit $1, got $2)"
    failures=$((failures + 1))
  fi
}

run_analyzer() {
  # $1 = fixture name; writes output to a fresh temp dir, echoed on stdout
  local out_dir
  out_dir="$(mktemp -d)"
  "$ANALYZER" "$FIXTURES/$1" --skip-build --out "$out_dir" >/dev/null
  echo "$out_dir"
}

# --- Case 1: full structure -> all structural points (10+10+20 = 40) --------
out="$(run_analyzer good-repo)"
assert_file_contains "$out/baseline-report.md" "**Score: 40/100**" \
  "good-repo scores 40/100 (all structural checks pass)"
assert_file_contains "$out/baseline-report.md" "| Tests present (1 test files) | 20 | PASS | 20 |" \
  "good-repo detects exactly 1 test file"
assert_file_contains "$out/baseline-score.json" '"score": 40' \
  "good-repo JSON score is 40"
assert_file_contains "$out/baseline-score.json" '"status": "SKIP"' \
  "build checks are SKIP in --skip-build mode"
rm -rf "$out"

# --- Case 2: README + pom, no tests -> 10+10+0 = 20 --------------------------
out="$(run_analyzer no-tests-repo)"
assert_file_contains "$out/baseline-report.md" "**Score: 20/100**" \
  "no-tests-repo scores 20/100"
assert_file_contains "$out/baseline-report.md" "| Tests present (0 test files) | 20 | FAIL | 0 |" \
  "no-tests-repo fails the tests-present check"
rm -rf "$out"

# --- Case 3: bare repo -> 0 ---------------------------------------------------
out="$(run_analyzer bare-repo)"
assert_file_contains "$out/baseline-report.md" "**Score: 0/100**" \
  "bare-repo scores 0/100"
rm -rf "$out"

# --- Case 4: missing target argument -> exit 2 --------------------------------
actual=0
"$ANALYZER" >/dev/null 2>&1 || actual=$?
assert_exit_code 2 "$actual" "no target argument exits with code 2"

# --- Case 5: unknown option -> exit 2 -----------------------------------------
actual=0
"$ANALYZER" "$FIXTURES/good-repo" --bogus >/dev/null 2>&1 || actual=$?
assert_exit_code 2 "$actual" "unknown option exits with code 2"

echo
if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) FAILED"
  exit 1
fi
echo "All unit tests passed."
