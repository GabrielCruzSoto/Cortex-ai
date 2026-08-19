#!/bin/bash
# CORTEX-AI auto-sync: trigger full sync after push
# This hook creates a full-sync marker that cortex-ai-autosync-check will process.
# A full sync re-evaluates all documentation, not just recently changed files.

CORTEX_MARKER_DIR=".cortex-ai"
CORTEX_MARKER_FILE="$CORTEX_MARKER_DIR/pending-sync"

# Ensure marker directory exists
mkdir -p "$CORTEX_MARKER_DIR"

# Write full-sync marker
echo "full-sync" > "$CORTEX_MARKER_FILE"

echo "[CORTEX-AI] Push detected. Full sync queued for next session start."
