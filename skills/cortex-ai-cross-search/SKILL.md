---
name: cortex-ai-cross-search
description: "Trigger: buscar en todos, cross search, en que proyecto ya, across projects, search all notebooks. Search the same query across registered CORTEX-AI project notebooks with pagination and team filtering."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.1"
---

# cortex-ai-cross-search

## Activation Contract

Activate when the user asks a question that explicitly spans multiple projects or does not specify one (e.g., "in which project did I already solve X?", "search all my projects for references to Y").

Do NOT activate for single-project queries — use `cortex-ai-ask` for those.

## Hard Rules

- Query EVERY registered project's notebook individually; group results by project origin.
- If a notebook fails during search, skip it and continue with remaining projects — report which ones were skipped.
- Never fabricate cross-project connections; every finding must be citable to a specific notebook source.
- If no project yields relevant results, say so explicitly.

## Decision Gates

| Situation | Action |
|-----------|--------|
| >10 projects to query | Paginate: process first 10, ask user if they want to continue |
| >50 projects to query | Batch mode: process in groups of 20, show progress |
| Search takes >30s | Report partial results with progress indicator |
| Team filter provided | Only query projects within that team |
| A specific notebook MCP fails | Skip it; list in "could not query" section of output |
| No results found in any notebook | State "no context found across {n} projects" |
| Result found but source is stale (last-update > push date) | Include the result but flag: "⚠️ may be outdated" |
| User requests page 2+ | Continue from where previous page stopped |
| All projects have been queried | Report final results with total count |

## Execution Steps

1. **List projects (scoped).** Call `search` with `query: "mimeType = 'application/vnd.google-apps.folder' and name = 'CORTEX-AI'"` to find the root folder, then `listFolder(folderId: root_id)` to enumerate project subfolders.
   - **Team filter:** If `--team {team-slug}` is specified, only enumerate children of `CORTEX-AI/{team-slug}/`. Skip root-level standalone projects.
   - For each project, call `readTextFile(fileId)` on its `README.md` to extract project name and ID.
2. **Resolve notebooks.** For each project, get its notebook ID from the Engram cross-reference (`cortex-ai/{slug}` or `cortex-ai/{team-slug}/{slug}`) or from the Drive README.
3. **Paginate.** If total project count >10:
   - Process the first 10 projects.
   - Report: "Queried {n}/{total} projects. Results so far: {count}. Continue? (y/n/page N)"
   - If user says yes or specifies a page, continue from where previous batch stopped.
   - If >50 projects, process in batches of 20 and report progress after each batch.
4. **Query each notebook.** Call `notebooklm_notebook_query` with the user's question against each project's notebook. Use batch queries via Engram when available for better performance.
5. **Filter results.** Discard responses with no cited sources, low relevance, or generic answers. Keep only verbatim-cited findings.
6. **Consolidate.** Group remaining findings by project. Format each as: `[{project-name}] {finding} — source: {source-title}`.
7. **Report gaps.** List projects whose notebooks could not be queried, and projects that returned no relevant results. Include pagination status if applicable.

## Output Contract

```
Cross-search results for: "{query}"
Scope: {all projects | team: {team-name}}
Queried: {n}/{total} projects

🔍 {project-name-1}
  - {finding} — source: {source-title}
  - {finding} — source: {source-title}

🔍 {project-name-2}
  - {finding} — source: {source-title}

Could not query: {project-list}
No results in: {project-list}

{Showing page {current}/{total}. Say "continue" for next page. | if paginated}
```

## References

- `cortex-ai-ask` — single-project knowledge query.
- `cortex-ai-status` — system health overview.
- `cortex-ai-team` — manages team namespaces for filtered searches.
