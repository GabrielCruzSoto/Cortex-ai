---
name: cortex-ai-cleanup
description: "Trigger: cleanup, limpiar, archivar proyecto, archive project, cleanup projects, limpiar proyectos, proyectos inactivos, inactive projects. Archive inactive projects, clean stale notebook sources, and generate storage reports."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-cleanup

## Activation Contract

Activate when the user explicitly requests cleanup, archival, or storage management. Also activate when `cortex-ai-status` or `cortex-ai-status-team` reports projects inactive for >6 months.

Do NOT activate automatically — always require explicit user confirmation before any destructive action.

## Hard Rules

- NEVER delete project data without explicit user confirmation for EACH project.
- Archival moves projects to `CORTEX-AI/_archived/{team-slug}/{project-slug}` — it does NOT delete.
- After archival, the project's NotebookLM notebook sources are preserved but flagged as "archived."
- Stale source cleanup only removes notebook sources that are >6 months old AND have been superseded by a newer version.
- Storage reports are read-only — they never modify data.
- Always produce a preview of what will be archived/cleaned before executing.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User requests cleanup without specifying scope | Ask: "Which team? Or all teams?" |
| Project inactive for >6 months | Suggest archival; require confirmation |
| Project has 0 notebook sources and >6 months inactive | Strongly suggest archival |
| Notebook has sources >6 months old with newer superseded versions | Suggest stale source cleanup; require confirmation |
| User confirms archival | Move to `_archived/` folder; update cross-reference |
| User confirms stale source cleanup | Delete superseded notebook sources; keep the latest version |
| `_archived/` folder does not exist | Create it before moving |
| Drive MCP fails during archival | ABORT; leave project in original location |

## Execution Steps

### Storage Report (read-only)

1. **Scan all projects.** List all projects across all teams (and standalone).
2. **Collect metrics.** For each project: notebook source count, last-push date, last-git-sync date, Drive folder size estimate (file count).
3. **Identify inactive projects.** Projects with no activity (last push >6 months ago).
4. **Identify stale sources.** Notebook sources that have been superseded (same filename, older version).
5. **Build report.** Present: total projects, total notebook sources, inactive projects, stale sources, estimated storage distribution.

### Archive Projects

1. **Present candidates.** List projects inactive >6 months with their last activity date.
2. **User selects projects.** User confirms which projects to archive.
3. **Ensure `_archived/` exists.** Create `CORTEX-AI/_archived/` if missing. If archiving team projects, create `CORTEX-AI/_archived/{team-slug}/`.
4. **Move project folder.** For each selected project:
   - Read the project's Drive folder ID from cross-reference.
   - Move the folder to `_archived/{team-slug}/` using Drive API (or copy + delete if move is unsupported).
   - Update the cross-reference in Engram to reflect new location and `archived: true` flag.
5. **Update team README.** Decrement project count in team README if applicable.
6. **Report.** List archived projects with their new locations.

### Clean Stale Notebook Sources

1. **Identify stale sources.** For a given project, compare notebook sources by filename. If multiple versions exist, keep only the newest.
2. **Present preview.** List sources to be deleted with their dates.
3. **User confirms.** Require explicit confirmation.
4. **Delete superseded sources.** Call `notebooklm_source_delete` for each stale source.
5. **Verify.** Call `notebooklm_notebook_get` to confirm source count decreased as expected.
6. **Report.** List deleted sources and remaining count.

## Output Contract

### Storage Report
```
CORTEX-AI Storage Report — {n} projects, {m} teams

Total notebook sources: {n}
Inactive projects (>6 months): {n}
  - {project-name} (team: {team-name}) — last activity: {date}
Stale notebook sources (superseded): {n}
  - {project-name}: {n} superseded sources

Estimated distribution:
  {team-name}: {n} projects, {m} sources
  Standalone: {n} projects, {m} sources
  Archived: {n} projects
```

### Archive Confirmation
```
Projects to archive:
  1. {project-name} (team: {team-name}) — last activity: {date}, {n} sources
  2. {project-name} (team: {team-name}) — last activity: {date}, {n} sources

These projects will be moved to CORTEX-AI/_archived/.
Notebooks will remain accessible but marked as archived.
Confirm? (y/n)
```

### Archive Complete
```
Archived {n} projects:
  - {project-name} → _archived/{team-slug}/{project-slug}
  - {project-name} → _archived/{project-slug}

Team READMEs updated.
Cross-references updated in engram.
```

### Stale Source Cleanup
```
Stale sources to remove from {project-name}:
  - {source-name} (added: {date}) — superseded by {newer-source-name} (added: {date})

{n} sources will be removed.
Confirm? (y/n)
```

## References

- `cortex-ai-status` — identifies inactive projects and stale sources.
- `cortex-ai-status-team` — identifies team-level cleanup candidates.
- `cortex-ai-team` — manages team namespace structure.
- `cortex-ai-init` — registers new projects (opposite of archival).
