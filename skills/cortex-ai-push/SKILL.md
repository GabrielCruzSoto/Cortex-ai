---
name: cortex-ai-push
description: "Trigger: push cortex, sync docs, publicar documentacion, subir docs. Sync changed docs to Drive and NotebookLM for a registered CORTEX-AI project."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-push

## Activation Contract

Activate when the user or a pipeline explicitly requests syncing/publishing documentation (e.g., after closing a Spec → Plan → Code → Test phase) for a project ALREADY registered in `CORTEX-AI` (valid `README.md` with ID in Drive).

Do NOT activate if the project has no `CORTEX-AI` registration — suggest `cortex-ai/init` instead.

## Hard Rules

- NEVER delete or recreate existing sources in the NotebookLM notebook — all operations are additive/append.
- Upload files to Drive FIRST (step 4), then NotebookLM (step 6); Drive errors must not block the notebook step, and vice versa.
- If a source already exists in the notebook (by filename slug), replace only that single source — do NOT reindex the whole notebook.
- Preserve the local subdirectory structure when uploading to Drive.
- NotebookLM sources MUST use the uploaded Drive documents as primary sources via `source_type=drive`; fall back to `source_type=file` or `source_type=text` only when a file type is unsupported by NotebookLM Drive indexing.

## Decision Gates

| Situation | Action |
|-----------|--------|
| No cross-reference found (Engram) nor valid README in Drive | Stop; suggest `cortex-ai/init` |
| Drive upload fails for a file | Retry once; if still failing, skip it, continue with remaining files, report skipped |
| NotebookLM source-add fails | Mark those sources `pending-indexing`; Drive files stay intact |
| Source already exists in notebook (same filename slug) | Replace only that source via delete + add |
| Source file type unsupported by NotebookLM Drive indexing | Fall back to `source_type=file` (local path) for images/drawio, `source_type=text` for markdown |
| No local files modified since last push | Report clean state; no-op |

## Execution Steps

1. **Resolve project record.** Search Engram for `cortex-ai/{project-slug}`. If not found, use `search` with `query: "name = 'README.md' and fullText contains '{project-id}'"` scoped to the project's Drive folder to locate it. Extract: project ID, Drive folder ID, notebook ID.
2. **Detect changes.** List local `docs/`, specs, and project README files. Compare modification timestamps against the last push timestamp stored in the cross-reference.
3. **Upload to Drive.** For each modified or new file, upload using the appropriate method:
   - For `.md` files: call `createTextFile(name=<filename>, content=<content>, parentFolderId=<drive-parent-path>)`.
   - For binary files (`.drawio`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.jpg`, `.jpeg`, `.png`, `.pdf`): call `uploadFile(localPath=<absolute-path>, parentFolderId=<drive-parent-path>)`. For Office files (`.doc`, `.docx`, `.xls`, `.xlsx`), set `convertToGoogleFormat: true`.
   - Preserve the local subdirectory structure by constructing the Drive parent path as `CORTEX-AI/{project-slug}/{relative-dir}`. The `parentFolderId` parameter supports path syntax and creates intermediate folders automatically.
   - Collect all resulting Drive file IDs, grouped by file type, for the notebook import step.
4. **Update README timestamp.** Call `readTextFile(fileId)` on the project's Drive README, update the "Fecha de última actualización" field to current ISO-8601, then call `updateTextFile(fileId, content: updated_readme)` to persist it.
5. **Add to NotebookLM from Drive.** Add the uploaded Drive documents as notebook sources using the best available method per file type:
   - **PDFs**: `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="pdf")`
   - **Converted Google Docs** (from `.doc`, `.docx`): `notebooklm_source_add(source_type="drive", document_id=<converted-file-id>, doc_type="doc")`
   - **Converted Google Sheets** (from `.xls`, `.xlsx`): `notebooklm_source_add(source_type="drive", document_id=<converted-file-id>, doc_type="sheets")`
   - **Markdown** (`.md`): read file content and call `notebooklm_source_add(source_type="text", text=<content>, title=<filename>)`
   - **Images** (`.jpg`, `.jpeg`, `.png`) and **diagrams** (`.drawio`): `notebooklm_source_add(source_type="file", file_path=<local-absolute-path>)`
   - If a source already exists in the notebook (by filename slug), delete it first via `notebooklm_source_delete` then re-add. Track which sources succeed and which fail.
6. **Verify notebook count.** Call `notebooklm_notebook_get` and confirm the source count increased or updated as expected.
7. **Update cross-reference.** Call `mem_save` with topic key `cortex-ai/{project-slug}`, updating the last-push timestamp and pending-indexing list.

## Output Contract

```
CORTEX-AI push complete for {project-name}
  Synced to Drive: {n} files — {list}
  Added/updated in Notebook: {n} sources — {list}
  Pending (retry next push): {n} — {list with reason}
  Last push timestamp: {iso-8601}
```

## References

- `cortex-ai-init` — prerequisite skill for project registration.
