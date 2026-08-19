#!/bin/bash
# CORTEX-AI auto-sync: detect documentation changes after each commit
# This hook creates a marker file that cortex-ai-autosync-check will process.
# Only documentation files trigger a sync — code-only commits are ignored.

CORTEX_MARKER_DIR=".cortex-ai"
CORTEX_MARKER_FILE="$CORTEX_MARKER_DIR/pending-sync"

# Ensure marker directory exists
mkdir -p "$CORTEX_MARKER_DIR"

# Get list of changed files in this commit (added, modified, renamed)
DOCS_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -iE '\.(md|drawio|doc|docx|xls|xlsx|jpg|jpeg|png|pdf)$')

if [ -n "$DOCS_CHANGED" ]; then
    # Append changed docs to the marker file (one path per line)
    # Avoid duplicates by checking if file is already listed
    if [ -f "$CORTEX_MARKER_FILE" ]; then
        for f in $DOCS_CHANGED; do
            grep -qxF "$f" "$CORTEX_MARKER_FILE" 2>/dev/null || echo "$f" >> "$CORTEX_MARKER_FILE"
        done
    else
        echo "$DOCS_CHANGED" > "$CORTEX_MARKER_FILE"
    fi
    echo "[CORTEX-AI] Documentation changes detected. Sync will run at next session start."
else
    echo "[CORTEX-AI] No documentation changes in this commit. Skipping sync."
fi
