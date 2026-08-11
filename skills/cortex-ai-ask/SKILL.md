---
name: cortex-ai-ask
description: "Trigger: ask cortex, pregunta sobre, consulta, que se decidio, resumen del spec, history of, knowledge query. Query project knowledge via NotebookLM first, local docs as fallback."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-ask

## Activation Contract

Activate when the user asks a question about the state, history, decisions, or documentation of a project registered in `CORTEX-AI` (e.g., "what was decided about X?", "summarize the spec for Y").

Do NOT activate for code-level questions (line-by-line logic, implementation details) — those are normal codebase queries.

## Hard Rules

- Strict order: NotebookLM → local. Never query local first when NotebookLM is available.
- Always cite the origin of every claim: `[NotebookLM]` or `[local]`.
- NEVER invent or infer an answer when no source supports it. Say explicitly "no context available".
- If local info is found but missing from the notebook, flag it and suggest running `cortex-ai/push`.

## Decision Gates

| Situation | Action |
|-----------|--------|
| NotebookLM MCP fails or times out | Skip to local search; inform user the answer is local-only |
| Project has no NotebookLM (init incomplete) | Search only local docs; inform user the brain is not indexed |
| NotebookLM answer is sufficient and source-backed | Deliver it with `[NotebookLM]` citation |
| NotebookLM answer is stale or insufficient | Supplement with local search; mark which parts come from where |
| Neither source has relevant info | State "no context available for this query" — do NOT fabricate |

## Execution Steps

1. **Resolve project.** Search Engram for `cortex-ai/{project-slug}`. Extract notebook ID and project context.
2. **Query NotebookLM.** Call `notebooklm_notebook_query` with the user's question. Evaluate: is the answer grounded in cited sources?
3. **Judge sufficiency.** If the answer is specific, current, and cites documents: it is sufficient. If vague, outdated, or uncited: it is insufficient.
4. **Local fallback (if needed).** Search local `docs/`, specs, README, and relevant source comments for the query. Compare against the NotebookLM answer.
5. **Combine.** If both sources contributed, deliver the answer with clear attribution boundaries (e.g., "According to NotebookLM [source: spec-v2.md]… Additionally, local docs show…").
6. **Flag gaps.** If the answer relies on local-only docs, append: "⚠️ This info is not yet indexed in the second brain. Run `cortex-ai/push` to sync it."

## Output Contract

```
{cited-answer}
---
📎 Sources:
  - [NotebookLM] {source-list}
  - [local] {file-list}
{flag-if-gap}
```

## References

- `cortex-ai-init` — prerequisite for project registration.
- `cortex-ai-push` — syncs local docs into the NotebookLM index.
