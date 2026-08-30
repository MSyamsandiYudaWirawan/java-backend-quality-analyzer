#!/usr/bin/env bash
#
# h1 analyzer — thin harness wrapper for exp/h1-rubric-scoring.
#
# The h1 pipeline is: collect.sh gathers mechanical evidence per repo, the
# agent reads that evidence and scores the rubric, and the resulting score
# sheet is COMMITTED under evidence/advanced/h1/<repo>/score-sheet.json.
# This wrapper is what the eval harness (service/eval/evaluate.py) invokes:
# it maps the target to a repo name, validates the committed score sheet,
# and writes <out>/h1-score.json with the total score.
#
# It does NOT re-run the collector or re-score: the score is a committed
# artifact, so eval runs are fast and reproducible. To refresh evidence,
# run service/advanced/collect.sh separately and re-score.
#
# Usage:
#   analyze-h1.sh <git-url|local-path> [--out DIR]
#
# Env:
#   H1_EVIDENCE_DIR   Dir holding per-repo h1 evidence + score sheets.
#                     Default: <repo-root>/evidence/advanced/h1
#
# Exit codes: 0 ok, 1 no committed score sheet for the target, 2 usage error.

set -euo pipefail

TARGET=""
OUT_DIR="h1-output"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      [ $# -ge 2 ] || { echo "ERROR: --out requires a directory" >&2; exit 2; }
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,20p' "$0"
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
  echo "ERROR: no target given. Usage: analyze-h1.sh <git-url|local-path> [--out DIR]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVIDENCE_DIR="${H1_EVIDENCE_DIR:-$SCRIPT_DIR/../../evidence/advanced/h1}"

# Same name mapping as service/eval/evaluate.py: basename, .git stripped.
NAME="$(basename "$TARGET" .git)"

SHEET="$EVIDENCE_DIR/$NAME/score-sheet.json"
if [ ! -f "$SHEET" ]; then
  echo "ERROR: no committed h1 score sheet for '$NAME' at $SHEET" >&2
  echo "Run service/advanced/collect.sh + rubric scoring for this repo first." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
# The sheet is self-contained and already has a top-level "score" field;
# copying it as h1-score.json is the whole handoff to the harness.
cp "$SHEET" "$OUT_DIR/h1-score.json"
echo ">> h1 score for $NAME: $(grep -o '"score": [0-9]*' "$SHEET" | head -1 | awk '{print $2}')/100 (from $SHEET)"
