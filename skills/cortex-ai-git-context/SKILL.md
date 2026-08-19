---
name: cortex-ai-git-context
description: "Trigger: git context, contexto git, quién trabajó, qué commits, hay PRs, issues abiertas, último cambio, who worked on this, recent commits, open PRs. Query a project's Git context (commits, PRs, issues) from the synced git-context document."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-git-context

## Activation Contract

Activate when the user asks questions about Git activity of a specific project: recent commits, who worked on what, open PRs, open issues, last changes to a file/module, or any question about repository activity.

Do NOT activate for code-level questions (e.g., "what does this function do?") — use `cortex-ai-ask` instead.
Do NOT activate for cross-project Git searches — use `cortex-ai-cross-search` with a Git-related query.

## Hard Rules

- Always cite the source: `[Git/NotebookLM]` when the answer comes from the indexed git-context, or `[Git/Drive]` when read directly from Drive, or `[Git/local]` when read from local git commands.
- NEVER fabricate commit hashes, PR numbers, or issue numbers.
- If no `git-context.md` exists (never synced), suggest running `cortex-ai-git-sync` and do NOT attempt to answer from local git commands alone.
- If the git-context is stale (last sync >24h ago), flag "⚠️ git context may be outdated — last sync was {time ago}. Consider running `cortex-ai-git-sync`."
- For questions about code changes to specific files, prefer the local `git log` as a supplementary source when available.

## Decision Gates

| Situation | Action |
|-----------|--------|
| No `git-context.md` in notebook or Drive | Suggest `cortex-ai-git-sync`; answer "no git context available" |
| git-context exists but is stale (>24h) | Answer from available data; flag staleness |
| NotebookLM MCP fails | Fall back to reading `git-context.md` from Drive directly |
| Drive MCP also fails | Fall back to local `git log` / `git log --oneline -20` as best effort |
| User asks about a specific file's history | Supplement with `git log -- <file>` if local git is available |
| User asks about PR review status | Answer from git-context data; note limitations of API scope |

## Execution Steps

1. **Resolve project.** Search Engram for `cortex-ai/{project-slug}` to get notebook ID and Drive folder ID.
2. **Query NotebookLM.** Call `notebooklm_notebook_query` with the user's question, scoped to git-related content. NotebookLM will retrieve relevant passages from the indexed `git-context.md`.
3. **Check staleness.** Extract `last-sync` from the git-context content. If >24h ago, flag staleness.
4. **Local fallback (optional).** If NotebookLM has insufficient data and local git is available, supplement with:
   - `git log --oneline -20` for recent commits
   - `git log --author="<name>" --oneline -10` for contributor-specific queries
   - `git log -- <file>` for file-specific history
5. **Combine and attribute.** Merge NotebookLM results with local git data (if used). Clearly mark the source of each piece of information.
6. **Deliver.** Present the answer with source citations and staleness warning if applicable.

## Output Contract

```
Git Context — {project-name}

{answer to user's question}

Sources: [Git/NotebookLM], [Git/local]
{⚠️ git context may be outdated — last sync {time-ago} | if applicable}
```

## Common Query Patterns

| User Says | Query Approach |
|-----------|---------------|
| "Quién trabajó en esto recientemente?" | List recent commit authors from git-context |
| "Hay PRs pendientes de review?" | List open PRs from git-context |
| "Cuál fue el último cambio en este módulo?" | Search commits for relevant file paths |
| "Qué issues están bloqueando este feature?" | List open issues with relevant labels |
| "Qué se hizo la semana pasada?" | Filter commits by date range |
| "Estado del repo" | Summary of all sections: commits count, PRs, issues |

## References

- `cortex-ai-git-sync` — generates the `git-context.md` document this skill queries.
- `cortex-ai-ask` — for code-level or spec-level questions (not Git activity).
- `cortex-ai-onboard` — includes Git context in the executive summary.
