---
name: cortex-ai-autosync-check
description: "Trigger: check autosync, verificar sync, pending sync, sync pendiente, procesar sync, run pending sync. Check for pending auto-sync markers and execute queued documentation synchronization."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-autosync-check

## Activation Contract

Activate at session start for any registered CORTEX-AI project that has auto-sync enabled. This skill should be run BEFORE the user begins working, ideally as the first action in a session.

Also activate when the user explicitly says "check pending sync" or "process sync queue."

Do NOT activate if the project is not registered in CORTEX-AI.
Do NOT activate if `.cortex-ai/pending-sync` does not exist (no pending work).

## Hard Rules

- NEVER run auto-sync if the project has uncommitted changes that might affect the sync (dirty working tree for doc files).
- ALWAYS read the marker file content before processing — determine whether it's a file list or `full-sync`.
- ALWAYS delete the marker file AFTER successful sync — never leave stale markers.
- ALWAYS update `.cortex-ai/last-sync` with the current ISO-8601 timestamp after successful sync.
- If sync fails partially (some files uploaded, some not), keep the marker file with only the FAILED files for retry.
- NEVER invoke `cortex-ai-push` with destructive parameters — auto-sync is always additive.

## Decision Gates

| Situation | Action |
|-----------|--------|
| `.cortex-ai/pending-sync` does not exist | No-op; report "no pending sync" |
| Marker content is `full-sync` | Invoke `cortex-ai-push` with full scan parameters |
| Marker content is a file list | Invoke `cortex-ai-push` with only those specific files |
| Project not registered in CORTEX-AI | Abort; report "project not registered" |
| Drive MCP unreachable | Abort; leave marker intact for next attempt |
| Sync fails for some files | Update marker with only failed files; report partial success |
| Sync succeeds completely | Delete marker; update last-sync timestamp |
| `.cortex-ai/` directory missing | Create it; proceed with sync |

## Execution Steps

1. **Check for pending sync.** Read `.cortex-ai/pending-sync`. If the file does not exist, report "no pending sync" and stop.
2. **Parse marker content.** Read the marker file content:
   - If content is `full-sync`: set sync mode to full (scan all project docs).
   - If content is a list of file paths: set sync mode to targeted (only those files).
   - If content is empty or unreadable: delete marker; report "invalid marker, cleared."
3. **Resolve project.** Search Engram for `cortex-ai/{project-slug}` to get Drive folder ID and notebook ID.
4. **Execute sync.** Invoke `cortex-ai-push` with the determined parameters:
   - For `full-sync`: standard `cortex-ai-push` execution (full scan).
   - For targeted sync: pass the specific file list to `cortex-ai-push` step 2 (detect changes) to limit scope.
5. **Handle result.**
   - **Success:** Delete `.cortex-ai/pending-sync`. Write current ISO-8601 timestamp to `.cortex-ai/last-sync`.
   - **Partial failure:** Update `.cortex-ai/pending-sync` with ONLY the failed files. Write timestamp to `.cortex-ai/last-sync` with a `partial` flag.
   - **Complete failure:** Leave `.cortex-ai/pending-sync` intact. Do NOT update last-sync. Report error.
6. **Report.** Deliver the sync result to the user.

## Output Contract

```
CORTEX-AI auto-sync {completed | partial | failed} for {project-name}
  Mode: {full-sync | targeted ({n} files)}
  Synced to Drive: {n} files
  Added/updated in Notebook: {n} sources
  Pending retry: {n} files — {list | none}
  Last sync: {iso-8601}
```

## References

- `cortex-ai-autosync-setup` — installs the hooks that create pending-sync markers.
- `cortex-ai-push` — the core sync operation invoked by this skill.
- `cortex-ai-init` — may invoke this skill if auto-sync was enabled during registration.
