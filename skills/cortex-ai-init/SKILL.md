---
name: cortex-ai-init
description: "Trigger: init cortex, segundo cerebro, brain setup, inicializar cerebro, cortex-ai. Initialize CORTEX-AI second brain for an unregistered project: Drive folder + NotebookLM notebook + cross-reference + optional Git sync + optional auto-sync + team support."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.3"
---

# cortex-ai-init

## Activation Contract

Activate at session start or project creation when the current project has no record inside the `CORTEX-AI` root folder in Google Drive — neither a matching kebab-case subfolder name nor a `README.md` inside it containing the current project's ID.

Do NOT activate when `CORTEX-AI/{project-slug}/README.md` already exists and is valid.
Do NOT activate when `CORTEX-AI/{team-slug}/{project-slug}/README.md` already exists and is valid (team-scoped project).

## Hard Rules

- Abort cleanly on Drive MCP failure; never leave partial artifacts.
- If `CORTEX-AI/{project-slug}` exists but `README.md` is missing or corrupt, **repair in place** — do not duplicate the folder.
- The project slug MUST be normalized kebab-case derived from the project name.
- Persist the cross-reference (project ID ↔ Drive folder ID ↔ Notebook ID) before reporting success.
- If NotebookLM creation fails after Drive artifacts are already written, leave Drive intact and mark the project `pending-indexing`; on next invocation retry only the notebook step.
- Upload ALL project documentation files (`.md`, `.drawio`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.jpg`, `.jpeg`, `.png`, `.pdf`) to the project's Drive folder, preserving the relative directory structure.
- The NotebookLM notebook MUST use the documents uploaded to the Drive folder as its primary sources via `source_type=drive`; fall back to `source_type=file` or `source_type=text` only when a file type is unsupported by NotebookLM Drive indexing.
- If the project is a Git repository (`.git/` directory exists) and the GitHub MCP is configured, automatically run `cortex-ai-git-sync` after step 10 to index repository metadata (commits, PRs, issues).
- If the project is a Git repository, ask the user whether to enable auto-sync. If they confirm, invoke `cortex-ai-autosync-setup` after step 11.
- If the user specifies a `--team` parameter or mentions a team name, the project is placed under `CORTEX-AI/{team-slug}/{project-slug}` instead of `CORTEX-AI/{project-slug}`. If the team does not exist, create it first via `cortex-ai-team`.

## Decision Gates

| Situation | Action |
|-----------|--------|
| `CORTEX-AI` root folder missing in Drive | Create it, then continue |
| Project folder exists, `README.md` missing or invalid | Repair: generate README.md inside the existing folder |
| Project folder exists, `README.md` valid | Stop; project already registered |
| NotebookLM fails after Drive artifacts created | Mark pending-indexing; do not recreate Drive artifacts |
| Generated UUID collides with an existing project | Regenerate once, then report if collision persists |
| No documentation files found to upload (only README) | Proceed with README-only registration; note in output |
| File upload fails for a specific file | Retry once; skip on second failure; continue with remaining files; report skipped |
| NotebookLM cannot index a specific file type (e.g., `.drawio`) | Skip notebook indexing for that file; it remains available in Drive |
| Project is a Git repository with GitHub MCP configured | Run `cortex-ai-git-sync` after cross-reference is persisted (step 11) |
| Project is a Git repository but GitHub MCP is not configured | Skip git sync; note "Git detected but GitHub MCP not available" in output |
| User confirms auto-sync enable | Invoke `cortex-ai-autosync-setup` after step 11 |
| User declines auto-sync enable | Skip auto-sync setup; note in output |
| User specifies a team that does not exist | Create team via `cortex-ai-team` first, then continue |
| User specifies a team that exists | Place project under team folder |
| No team specified | Place project at root level: `CORTEX-AI/{project-slug}` |

## Execution Steps

0. **Resolve team context (optional).** Check if the user specified a team name or `--team` parameter. If a team is specified:
   - Normalize team name to kebab-case.
   - Check if `CORTEX-AI/{team-slug}` exists in Drive. If not, invoke `cortex-ai-team` to create it.
   - Set `drive-parent-path = "CORTEX-AI/{team-slug}"` for all subsequent steps.
   - If no team is specified, set `drive-parent-path = "CORTEX-AI"`.
1. **Locate or create root.** Call `search` with `query: "mimeType = 'application/vnd.google-apps.folder' and name = 'CORTEX-AI'"`. If missing, create it via `createFolder(name: "CORTEX-AI")`.
2. **Check project registration.** Call `listFolder(folderId: root_id or team_folder_id)` to enumerate children under the resolved parent path. Normalize the current project name to kebab-case. If a matching subfolder exists, call `readTextFile(fileId)` on its `README.md` and extract the project ID — if valid, stop (already registered).
3. **Generate ID.** Create a UUID v4 project ID. Verify no collision against existing subfolder READMEs.
4. **Create project folder.** Call `createFolder(name: kebab-slug, parent: parent_id)` as a subfolder of `drive-parent-path`.
5. **Compose README.** Fill the template from `assets/readme-template.md` with the project's current name, description, ISO-8601 date, project ID, and the Drive folder URL.
6. **Upload README.** Call `createTextFile(name: "README.md", content: readme_content, parentFolderId: project_folder_id)` into the project subfolder. Record its Drive file ID.
7. **Scan project files and upload to Drive.** Use `glob` with pattern `**/*.{md,drawio,doc,docx,xls,xlsx,jpg,jpeg,png,pdf}` to locate all documentation files in the project root. Exclude files under `.git/`, `node_modules/`, `vendor/`, and other dependency directories. For each file:
   - Compute its relative path from the project root.
   - Construct the Drive parent path as `{drive-parent-path}/{project-slug}/{relative-dir}`.
   - For `.md` files: call `createTextFile(name=<filename>, content=<content>, parentFolderId=<drive-parent-path>)`.
   - For binary files (`.drawio`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.jpg`, `.jpeg`, `.png`, `.pdf`): call `uploadFile(localPath=<absolute-path>, parentFolderId=<drive-parent-path>)`. For Office files (`.doc`, `.docx`, `.xls`, `.xlsx`), set `convertToGoogleFormat: true`.
   - Collect all resulting Drive file IDs, grouped by file type (pdf, doc, sheets, md-text, binary-other), for the notebook import step.
   - If no matching files are found (project has only the README), note this and proceed.
8. **Create NotebookLM notebook.** Call `notebooklm_notebook_create` with the project name as title. Record the returned notebook ID.
9. **Import sources from Drive folder.** Add all uploaded Drive documents as notebook sources. Use the best available method per file type:
   - **PDFs** (`doc_type=pdf`): `notebooklm_source_add(source_type="drive", document_id=<drive-file-id>, doc_type="pdf")`
   - **Converted Google Docs** (from `.doc`, `.docx`): `notebooklm_source_add(source_type="drive", document_id=<converted-file-id>, doc_type="doc")`
   - **Converted Google Sheets** (from `.xls`, `.xlsx`): `notebooklm_source_add(source_type="drive", document_id=<converted-file-id>, doc_type="sheets")`
   - **Markdown** (`.md`): read file content and call `notebooklm_source_add(source_type="text", text=<content>, title=<filename>)`
   - **Images** (`.jpg`, `.jpeg`, `.png`) and **diagrams** (`.drawio`): `notebooklm_source_add(source_type="file", file_path=<local-absolute-path>)`
   - Track which sources succeed and which fail. Mark failed sources in the cross-reference for retry.
10. **Persist cross-reference.** Call `mem_save` with topic key `cortex-ai/{project-slug}`, type `config`, storing: project ID, Drive folder ID, notebook ID, registration date, uploaded file count, and any `pending-indexing` sources.
11. **Git sync (optional).** Check if `.git/` exists in the project root AND the GitHub MCP is available. If both conditions are met, invoke `cortex-ai-git-sync` to generate `git-context.md`, upload it to Drive, and index it in NotebookLM. If `.git/` exists but GitHub MCP is not configured, note "Git detected but GitHub MCP not available — run `cortex-ai-git-sync` manually after configuring GitHub MCP."
12. **Auto-sync setup (optional).** If `.git/` exists in the project root, ask the user: "Enable automatic documentation sync on commit/push? (y/n)". If the user confirms, invoke `cortex-ai-autosync-setup` to install Git hooks. If the user declines, skip and note in output.

## Output Contract

Return a single confirmation block:

```
CORTEX-AI initialized for {project-name}
  Project ID: {uuid}
  Drive folder: {url}
  Files uploaded to Drive: {n} ({extensions-summary})
  Files skipped (upload failure): {n} — {list with reason}
  Notebook: {created-and-indexed | partial-indexing | pending-indexing}
  Sources added to notebook: {n}/{total}
  Pending notebook indexing: {n} — {list}
  Cross-reference saved to engram → cortex-ai/{project-slug}
  Git sync: {completed | skipped-not-a-repo | skipped-no-mcp | not-configured}
  Auto-sync: {enabled | disabled | skipped-not-a-repo}
  Team: {team-name | none (standalone)}
```

## References

- `assets/readme-template.md` — README.md template with required fields.
- `cortex-ai-team` — creates team namespaces (invoked in step 0 when team is specified).
- `cortex-ai-git-sync` — syncs Git repository metadata to Drive and NotebookLM (invoked in step 11).
- `cortex-ai-autosync-setup` — installs Git hooks for automatic documentation sync (invoked in step 12).
