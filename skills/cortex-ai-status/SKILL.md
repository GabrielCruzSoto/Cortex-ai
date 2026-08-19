---
name: cortex-ai-status
description: "Trigger: status del cerebro, panorama, estado de proyectos, que quedo pendiente, how is the brain, system health. Report health of all CORTEX-AI registered projects: sync, indexing, git status, auto-sync, and pending items."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.2"
---

# cortex-ai-status

## Activation Contract

Activate when the user requests a system-wide health overview (e.g., "how is the second brain?", "show me project status", "what's pending indexing?").

Do NOT activate for single-project queries — use `cortex-ai-ask` for those.

## Hard Rules

- Never fabricate project data when Drive MCP is unreachable; report "partial or unavailable" explicitly.
- A project with a Drive folder but no NotebookLM notebook is `init-incomplete`, not `ok`.
- A project with pending-indexing marks from a previous `push`/`init` failure retains that status until the notebook source count confirms the files were ingested.
- Corrupt README.md (missing required fields): mark as `invalid-registry`, do not guess state.
- Git sync status is informational only — a failed git sync does not affect the project's core health classification.
- Auto-sync status is informational — it does not block or change the project's health classification.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Drive MCP fails entirely | Report partial/unavailable; do not fake project list |
| NotebookLM MCP fails for a specific project | Mark as "indexing-status unknown" for that project |
| README.md missing or corrupt in a subfolder | Mark as "invalid-registry"; suggest manual review or `cortex-ai/init` repair |
| Project has Drive folder + README + notebook but pending-indexing marks | Status: `desync`; list pendientes |
| Project has all artifacts and no pending marks | Status: `ok` |
| Project has git-context.md but last-git-sync >24h | Git status: `stale`; suggest `cortex-ai-git-sync` |
| Project is a Git repo but no git-context.md | Git status: `never-synced`; suggest `cortex-ai-git-sync` |
| Project is not a Git repo | Git status: `n/a` |
| `.cortex-ai/pending-sync` exists | Auto-sync: `pending`; suggest `cortex-ai-autosync-check` |
| `.git/hooks/post-commit` has CORTEX-AI marker | Auto-sync: `enabled` |
| No `.git/hooks/post-commit` or no CORTEX-AI marker | Auto-sync: `disabled` or `n/a` |

## Execution Steps

1. **List projects.** Call `search` with `query: "mimeType = 'application/vnd.google-apps.folder' and name = 'CORTEX-AI'"` to find the root folder, then `listFolder(folderId: root_id)` to enumerate all project subfolders. Each subfolder = one project.
2. **Read READMEs.** For each subfolder, call `readTextFile(fileId)` on its `README.md`. Extract: project name, project ID, creation date, last-update date.
3. **Query notebooks.** For each project, resolve its notebook ID from the cross-reference (Engram `cortex-ai/{slug}`). Call `notebooklm_notebook_get` to retrieve: source count, last-source-added date.
4. **Merge pending marks.** For each project, search Engram for `cortex-ai/{slug}` and extract any `pending-indexing` list left by `cortex-ai/push` or `cortex-ai/init`.
5. **Classify each project.** Determine status: `ok`, `desync` (push needed), `pending-indexing` (notebook retry needed), `init-incomplete` (no notebook), `invalid-registry` (corrupt README), `unknown` (MCP unreachable). Also determine Git status: `synced`, `stale`, `never-synced`, or `n/a`. Also determine auto-sync status: `enabled`, `pending`, `disabled`, or `n/a`.
6. **Build summary table.** Consolidate into a table: Project Name | Last Drive Sync | Notebook Sources | Pendientes | Git Status | Auto-sync | Status.
7. **Surface action items.** Below the table, list how many projects require action and what action: push pending, reindex needed, git sync needed, pending auto-sync to process, init incomplete, or manual review.

## Output Contract

```
CORTEX-AI System Health — {n} projects

| Project | Last Drive Sync | Notebook Sources | Pendientes | Git Status | Auto-sync | Status |
|---------|----------------|-----------------|------------|------------|-----------|--------|
| ...     | ...            | ...             | ...        | ...        | ...       | ...    |

Action required:
  🔴 {n} projects with push/reindex pending
  🟡 {n} with init incomplete
  🟠 {n} with git sync needed (never-synced or stale)
  🔵 {n} with pending auto-sync to process
  ⚪ {n} with invalid registry
```

## References

- `cortex-ai-init` — registers a new project.
- `cortex-ai-push` — syncs docs; may leave pending-indexing marks.
- `cortex-ai-ask` — query a single project's knowledge.
- `cortex-ai-git-sync` — syncs Git repository metadata.
- `cortex-ai-git-context` — queries Git activity details.
- `cortex-ai-autosync-check` — processes pending auto-sync markers.
- `cortex-ai-autosync-setup` — installs auto-sync Git hooks.
