---
name: cortex-ai-onboard
description: "Trigger: resume del proyecto, ponme al dia, executive summary, project summary, dame contexto, get me up to speed. Generate an executive summary from a project's NotebookLM notebook to resume work after inactivity."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.1"
---

# cortex-ai-onboard

## Activation Contract

Activate when the user explicitly asks to catch up on a project (e.g., "give me a summary of X", "I haven't touched this in weeks, bring me up to speed"), OR at session start for a registered project with significant inactivity when the user confirms they want the summary.

## Hard Rules

- If the notebook has insufficient sources for a coherent summary, deliver only what the README.md provides and explicitly state the limitation.
- Always compare the notebook's last-source-added date against the Drive README's last-update date. If Drive is more recent than the notebook, flag "⚠️ notebook may be outdated — last push was not fully indexed."
- Never infer context that is not documented. If there's no activity record, say so.
- Structure the summary into: what the project is, where it stands, key decisions, what's pending, and recent Git activity (if available).

## Decision Gates

| Situation | Action |
|-----------|--------|
| Notebook has rich sources with decisions and specs | Deliver full executive summary |
| Notebook has only README-level info | Deliver what's available; warn about limited context |
| NotebookLM MCP fails | Fall back to Drive README only; flag that notebook was unreachable |
| No activity record in notebook or Drive | State "no documented activity found" |
| Notebook is stale relative to Drive (push newer than index) | Include the summary but flag potential gaps |
| Git context available (git-context.md indexed) | Include Git activity section in summary |
| Git context available but stale (>24h since last sync) | Include Git section with staleness warning |
| No git context (project not a Git repo or never synced) | Omit Git section entirely; do not fabricate |

## Execution Steps

1. **Resolve project.** Search Engram for `cortex-ai/{project-slug}`. Extract project ID, Drive folder ID, notebook ID.
2. **Read README.** Call `readTextFile(fileId)` on the project's `README.md`. Extract description, creation date, last-update date.
3. **Query notebook for summary.** Call `notebooklm_notebook_query` with prompts covering: "key decisions documented", "current state of specs/tasks", "pending items explicitly mentioned".
4. **Query git context.** If the project has a `git-context.md` source in the notebook, call `notebooklm_notebook_query` with prompts covering: "recent commits and contributors", "open pull requests", "open issues blocking progress". If no git context is found, skip this step.
5. **Build executive summary.** Structure as:
   - **What it is:** 1-2 sentence description from README.
   - **Where it stands:** current state from notebook — last major phase, active specs, completed tasks.
   - **Key decisions:** 3-5 most recent or impactful decisions documented.
   - **Pending:** explicit roadmap items, spec gaps, or open questions found in sources.
   - **Recent Git activity:** (only if git context available) last 5 commits, open PRs count, open issues count, top contributors.
6. **Compare timestamps.** Compare `last-update` from README vs `last-source-added` from notebook. If Drive is newer, append the staleness warning. Also compare `last-git-sync` if available; if >24h ago, append git staleness warning.
7. **Deliver.** Present the summary with clear sections and the staleness warning if applicable.

## Output Contract

```
📋 Executive Summary — {project-name}

What it is:
{description}

Where it stands:
{current-state — last activity, phase, status}

Key decisions:
  - {decision} — source: {source-title}
  - {decision} — source: {source-title}

Pending:
  - {item}
  - {item}

Recent Git activity:
  - Last {n} commits by {authors}
  - Open PRs: {n} — {list with titles}
  - Open issues: {n} — {list with titles}
  {⚠️ git context may be outdated — last sync {time-ago} | if applicable}

{⚠️ notebook may be outdated — last push {push-date} > last index {notebook-date} | if applicable}
```

## References

- `cortex-ai-ask` — single-question project knowledge query.
- `cortex-ai-status` — system-wide health overview.
- `cortex-ai-push` — syncs docs to keep the notebook current.
- `cortex-ai-git-sync` — generates Git context included in the summary.
- `cortex-ai-git-context` — queries Git activity details.
