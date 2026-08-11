---
name: cortex-ai-reindex
description: "Trigger: reindexa, rebuild notebook, reconstruir notebook, notebook corrupto, reindex project. Destructively rebuild a project NotebookLM notebook from its Drive folder contents."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-reindex

## Activation Contract

Activate when the user explicitly requests rebuilding a project's notebook (e.g., "reindexa el proyecto X", "the notebook for X is corrupt"), OR when `cortex-ai/status` reports a `desync` project and the user confirms.

NEVER activate automatically — this is a destructive operation on the notebook and REQUIRES explicit user confirmation.

## Hard Rules

- Require explicit user confirmation before deleting any notebook sources. If not confirmed, abort without touching the notebook.
- If source deletion fails mid-process: STOP before loading new sources. Do NOT leave the notebook in a mixed state (half old, half new) without warning.
- If new source loading fails after the notebook was emptied: report immediately that the notebook is now empty, then retry loading in the same execution before giving up.
- Files from Drive that are not indexable by NotebookLM (unsupported format) MUST be skipped and reported — do NOT halt the process for them.
- Reload sources using Drive documents as primary sources via `source_type=drive`; fall back to `source_type=file` or `source_type=text` only when a file type is unsupported by NotebookLM Drive indexing (e.g., images, `.drawio`, raw `.md` files).
- After a successful reindex, clear ALL pending-indexing marks for the project in Engram.

## Decision Gates

| Situation | Action |
|-----------|--------|
| User does NOT confirm step 2 | Abort; do not modify the notebook |
| Source deletion fails mid-way | Stop; report the failure; do NOT load new sources |
| Notebook emptied but new source load fails | Retry immediately; if it still fails, report notebook-is-empty |
| Drive file is unsupported format | Skip it; include in final omitted-files list |
| Cross-reference missing (no Engram record) | Resolve from Drive README; if also missing, suggest `cortex-ai/init` first |

## Execution Steps

1. **Resolve project.** Search Engram for `cortex-ai/{project-slug}`. Extract Drive folder ID, notebook ID, and current README.md.
2. **Confirm with user.** State: "This will DELETE all current notebook sources and rebuild from Drive. Continue?" Wait for explicit yes.
3. **List Drive contents.** Call `listFolder(folderId: project_folder_id)` on the project's Drive folder to enumerate all files: README.md, docs/, specs, and any indexable content.
4. **Delete notebook sources.** Call `notebooklm_source_delete` for every existing source in the notebook. Verify the notebook is empty via `notebooklm_notebook_get`.
5. **Reload sources from Drive.** For each Drive file from step 3, add it as a notebook source using the best available method per file type:
   - **PDFs**: `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="pdf")`
   - **Google Docs** (converted `.doc`, `.docx`): `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="doc")`
   - **Google Sheets** (converted `.xls`, `.xlsx`): `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="sheets")`
   - **Google Slides**: `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="slides")`
   - **Markdown** (`.md`): read file content via `readTextFile(fileId)` and call `notebooklm_source_add(source_type="text", text=<content>, title=<filename>)`
   - **Images** (`.jpg`, `.jpeg`, `.png`) and **diagrams** (`.drawio`): download from Drive via `downloadFile(localPath)`, then `notebooklm_source_add(source_type="file", file_path=<local-path>)`
   - **Unsupported formats**: skip and add to omitted-files list. Track successes and failures.
6. **Update README.** Call `readTextFile(fileId)` on the project's `README.md`, update the "fecha de última reindexación completa" field, then call `updateTextFile(fileId, content: updated_readme)` to persist it.
7. **Clear pending marks.** Search Engram for the project's `pending-indexing` list; if found, remove those entries and update the cross-reference.

## Output Contract

```
CORTEX-AI reindex complete for {project-name}
  Previous sources deleted: {n}
  New sources loaded: {n}
  Omitted (unsupported format): {n} — {list}
  Reindex date: {iso-8601}
```

## References

- `cortex-ai-init` — project registration prerequisite.
- `cortex-ai-status` — identifies projects needing reindex.
- `cortex-ai-push` — normal incremental sync (use this for daily updates, not reindex).
