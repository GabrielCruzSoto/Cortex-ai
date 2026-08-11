---
name: cortex-ai-cross-search
description: "Trigger: buscar en todos, cross search, en que proyecto ya, across projects, search all notebooks. Search the same query across ALL registered CORTEX-AI project notebooks."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
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
| Too many projects to query in one pass (>10) | Prioritize by most recent `last-update` date; inform user the search was scoped |
| A specific notebook MCP fails | Skip it; list in "could not query" section of output |
| No results found in any notebook | State "no context found across {n} projects" |
| Result found but source is stale (last-update > push date) | Include the result but flag: "⚠️ may be outdated" |

## Execution Steps

1. **List all projects.** Call `search` with `query: "mimeType = 'application/vnd.google-apps.folder' and name = 'CORTEX-AI'"` to find the root folder, then `listFolder(folderId: root_id)` to enumerate project subfolders. For each project, call `readTextFile(fileId)` on its `README.md` to extract project name and ID.
2. **Resolve notebooks.** For each project, get its notebook ID from the Engram cross-reference (`cortex-ai/{slug}`) or from the Drive README.
3. **Query each notebook.** Call `notebooklm_notebook_query` with the user's question against each project's notebook.
4. **Filter results.** Discard responses with no cited sources, low relevance, or generic answers. Keep only verbatim-cited findings.
5. **Consolidate.** Group remaining findings by project. Format each as: `[{project-name}] {finding} — source: {source-title}`.
6. **Report gaps.** List projects whose notebooks could not be queried, and projects that returned no relevant results.

## Output Contract

```
Cross-search results for: "{query}"

🔍 {project-name-1}
  - {finding} — source: {source-title}
  - {finding} — source: {source-title}

🔍 {project-name-2}
  - {finding} — source: {source-title}

Could not query: {project-list}
No results in: {project-list}
```

## References

- `cortex-ai-ask` — single-project knowledge query.
- `cortex-ai-status` — system health overview.
