#!/usr/bin/env bash
#
# Fast, offline unit tests for service/advanced/collect.sh (h1 collector).
# Runs the collector with --skip-build against committed fixture repos and
# asserts the structural evidence. Maven evidence gathering is covered by
# the real run against the eval set (see evidence/advanced/).
#
# Usage: tests/unit/test-collect.sh   (from the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COLLECTOR="$REPO_ROOT/service/advanced/collect.sh"
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

assert_file_exists() {
  # $1 = file, $2 = test name
  if [ -f "$1" ]; then
    echo "PASS: $2"
  else
    echo "FAIL: $2 (missing file: $1)"
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

run_collector() {
  # $1 = fixture name; writes output to a fresh temp dir, echoed on stdout
  local out_dir
  out_dir="$(mktemp -d)"
  "$COLLECTOR" "$FIXTURES/$1" --skip-build --out "$out_dir" >/dev/null
  echo "$out_dir"
}

EVIDENCE_FILES="collect-manifest.json test-census.txt package-tree.txt \
largest-classes.txt repo-scan.txt surefire-summary.txt"

# --- Case 1: good-repo — pom + README + 1 test file, no main sources ---------
out="$(run_collector good-repo)"
for f in $EVIDENCE_FILES; do
  assert_file_exists "$out/$f" "good-repo: $f written"
done
assert_file_contains "$out/collect-manifest.json" '"buildStatus": "SKIP"' \
  "good-repo: maven evidence is SKIP in --skip-build mode"
assert_file_contains "$out/collect-manifest.json" '"hasPom": 1' \
  "good-repo: pom detected"
assert_file_contains "$out/test-census.txt" "test_java_files=1" \
  "good-repo: detects exactly 1 test file"
assert_file_contains "$out/test-census.txt" "main_java_files=0" \
  "good-repo: no main sources"
assert_file_contains "$out/package-tree.txt" "src/test/java/com/example" \
  "good-repo: package tree lists the test package"
assert_file_contains "$out/repo-scan.txt" "README.md" \
  "good-repo: repo scan finds the README"
assert_file_contains "$out/largest-classes.txt" "FooTest.java" \
  "good-repo: largest-classes lists the test class"
rm -rf "$out"

# --- Case 2: no-tests-repo — pom + README, zero java sources -----------------
out="$(run_collector no-tests-repo)"
assert_file_contains "$out/test-census.txt" "test_java_files=0" \
  "no-tests-repo: zero test files"
assert_file_contains "$out/test-census.txt" "assertion_calls=0" \
  "no-tests-repo: zero assertions (no grep abort on empty suite)"
rm -rf "$out"

# --- Case 3: bare-repo — no pom, one main class ------------------------------
out="$(run_collector bare-repo)"
assert_file_contains "$out/collect-manifest.json" '"hasPom": 0' \
  "bare-repo: no pom detected"
assert_file_contains "$out/test-census.txt" "main_java_files=1" \
  "bare-repo: one main source file"
rm -rf "$out"

# --- Case 4: argument errors ---------------------------------------------------
code=0
"$COLLECTOR" >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "no target argument exits with code 2"

code=0
"$COLLECTOR" "$FIXTURES/good-repo" --bogus >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "unknown option exits with code 2"

# --- summary ---------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) FAILED."
  exit 1
fi
echo
echo "All unit tests passed."
