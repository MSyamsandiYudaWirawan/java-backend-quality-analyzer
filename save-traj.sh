#!/bin/bash
# ============================================================================
# Save current Kimi trajectory
# ============================================================================
# Part of the trajectory curation workflow (prompts/README.md §6 — one curated
# trajectory per work block). Run /log inside the Kimi CLI, place the exported
# .md in trajectories/, then run this script.
#
# Usage:
#   ./save-traj.sh [label]        # label defaults to "session"
#
# Input:  the newest trajectories/*.md (the /log export).
# Output: trajectories/kimi-api/<YYYYMMDD-HHMMSS>_<label>.md with a metadata
#         header (date, branch, commit) prepended; the source file is removed.
#
# Exit codes: 0 saved, 1 no exported .md found in trajectories/.
# ============================================================================

LABEL="${1:-session}"
DATE=$(date +%Y%m%d-%H%M%S)
OUTDIR="trajectories/kimi-api"
mkdir -p "$OUTDIR"

# Kimi /log exports to a file — drop it in trajectories/ and this picks it up
LATEST=$(ls -t trajectories/*.md 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
  echo "No .md file found in trajectories/."
  echo "Run /log inside Kimi CLI first, then place the exported file in trajectories/."
  exit 1
fi

OUTFILE="$OUTDIR/${DATE}_${LABEL}.md"
{
  echo "# Trajectory: $LABEL"
  echo ""
  echo "- Date: $DATE"
  echo "- Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
  echo "- Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  echo "---"
  echo ""
  cat "$LATEST"
} > "$OUTFILE"

rm "$LATEST"
echo "Saved to $OUTFILE"
