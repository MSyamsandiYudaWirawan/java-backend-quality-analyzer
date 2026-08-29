#!/usr/bin/env bash
#
# Fast, offline unit tests for service/advanced/analyze-h1.sh (h1 wrapper).
# Uses a fixture score sheet via H1_EVIDENCE_DIR; no Maven, no network.
#
# Usage: tests/unit/test-analyze-h1.sh   (from the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WRAPPER="$REPO_ROOT/service/advanced/analyze-h1.sh"
FIXTURES="$REPO_ROOT/tests/unit/fixtures"

export H1_EVIDENCE_DIR="$FIXTURES/h1-evidence"

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

# --- Case 1: known repo name -> committed score is handed to the harness -----
out="$(mktemp -d)"
"$WRAPPER" "https://github.com/example/fake-repo.git" --out "$out" >/dev/null
assert_file_contains "$out/h1-score.json" '"score": 42' \
  "URL target maps by basename (.git stripped) and copies the score sheet"
rm -rf "$out"

# --- Case 2: local path target maps the same way ------------------------------
out="$(mktemp -d)"
"$WRAPPER" "targets/fake-repo" --out "$out" >/dev/null
assert_file_contains "$out/h1-score.json" '"score": 42' \
  "local path target maps by basename"
rm -rf "$out"

# --- Case 3: no committed sheet -> exit 1, no score file -----------------------
out="$(mktemp -d)"
code=0
"$WRAPPER" "targets/no-such-repo" --out "$out" >/dev/null 2>&1 || code=$?
assert_exit_code 1 "$code" "missing score sheet exits with code 1"
if [ ! -e "$out/h1-score.json" ]; then
  echo "PASS: missing score sheet produces no score file"
else
  echo "FAIL: missing score sheet must not produce a score file"
  failures=$((failures + 1))
fi
rm -rf "$out"

# --- Case 4: argument errors -----------------------------------------------------
code=0
"$WRAPPER" >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "no target argument exits with code 2"

# --- summary -----------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) FAILED."
  exit 1
fi
echo
echo "All unit tests passed."
