#!/bin/bash
# ============================================================================
# Save current Kimi trajectory
# ============================================================================
# Usage:
#   ./save-traj.sh "experiment/h3-cache"
#
# Run this inside the Kimi CLI with /log, then move the exported file here.
# This script renames and appends metadata so trajectories stay organized.
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
