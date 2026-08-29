#!/usr/bin/env bash
#
# Fast, offline unit tests for benchmarks/k6-report.js (h2 fixed-shape
# load report). Uses fixture k6 summary JSONs; no k6, no docker.
#
# Usage: tests/unit/test-k6-report.sh   (from the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORTER="$REPO_ROOT/benchmarks/k6-report.js"
FIXTURES="$REPO_ROOT/tests/unit/fixtures/k6-report"

failures=0

assert_file_contains() {
  if grep -qF "$2" "$1"; then
    echo "PASS: $3"
  else
    echo "FAIL: $3"
    echo "  expected to find in $1: $2"
    failures=$((failures + 1))
  fi
}

assert_exit_code() {
  if [ "$1" -eq "$2" ]; then
    echo "PASS: $3"
  else
    echo "FAIL: $3 (expected exit $1, got $2)"
    failures=$((failures + 1))
  fi
}

# --- Case 1: clean run -> PASS verdict, fixed shape ------------------------------
out="$(mktemp -d)"
node "$REPORTER" "$FIXTURES/summary-pass.json" --repo demo --out "$out" >/dev/null
assert_file_contains "$out/load-report.json" '"verdict": "PASS"' "clean run: verdict PASS"
assert_file_contains "$out/load-report.json" '"rps": 19.84' "clean run: rps extracted"
assert_file_contains "$out/load-report.json" '"p95": 120.44' "clean run: p95 extracted"
assert_file_contains "$out/load-report.json" '"checkPassRate": 0.9983' "clean run: check rate extracted"
assert_file_contains "$out/load-report.md" '| p95 latency | 120.44 ms |' "clean run: md table written"
rm -rf "$out"

# --- Case 2: breached thresholds -> FAIL verdict + breached list -------------------
out="$(mktemp -d)"
node "$REPORTER" "$FIXTURES/summary-breach.json" --repo demo --out "$out" >/dev/null
assert_file_contains "$out/load-report.json" '"verdict": "FAIL"' "breach: verdict FAIL"
assert_file_contains "$out/load-report.json" 'http_req_duration: p(95)<500' "breach: latency threshold listed"
assert_file_contains "$out/load-report.json" 'http_req_failed: rate<0.01' "breach: error threshold listed"
assert_file_contains "$out/load-report.md" '**FAIL**' "breach: md shows FAIL"
rm -rf "$out"

# --- Case 3: finding mode -> NOT_TESTABLE with explicit note -----------------------
out="$(mktemp -d)"
node "$REPORTER" --finding "mvn package failed (see build.log)" --repo demo --out "$out" >/dev/null
assert_file_contains "$out/load-report.json" '"verdict": "NOT_TESTABLE"' "finding: verdict NOT_TESTABLE"
assert_file_contains "$out/load-report.json" 'could not generate a valid load scenario: mvn package failed' \
  "finding: explicit note recorded"
assert_file_contains "$out/load-report.md" 'N/A' "finding: metrics rendered as N/A"
rm -rf "$out"

# --- Case 4: usage and input errors -------------------------------------------------
code=0
node "$REPORTER" "$FIXTURES/summary-pass.json" >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "missing --repo exits with code 2"

code=0
node "$REPORTER" "$FIXTURES/summary-pass.json" --repo demo --finding x >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "file and --finding together exit with code 2"

code=0
node "$REPORTER" no-such-file.json --repo demo >/dev/null 2>&1 || code=$?
assert_exit_code 2 "$code" "unreadable k6 JSON exits with code 2"

notk6="$(mktemp)"
echo '{}' > "$notk6"
code=0
node "$REPORTER" "$notk6" --repo demo >/dev/null 2>&1 || code=$?
assert_exit_code 1 "$code" "non-k6 JSON exits with code 1"
rm -f "$notk6"

# --- summary -------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) FAILED."
  exit 1
fi
echo
echo "All unit tests passed."
