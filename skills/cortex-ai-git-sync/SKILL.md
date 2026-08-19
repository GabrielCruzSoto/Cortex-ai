---
name: cortex-ai-git-sync
description: "Trigger: sync git, git sync, sincronizar git, git context, contexto git, subir git, git history. Sync git repository metadata (commits, PRs, issues) to Drive and NotebookLM for a registered CORTEX-AI project."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-git-sync

## Activation Contract

Activate when the user explicitly requests syncing git history/metadata, OR when `cortex-ai-push` detects a Git repository and runs this as an optional step, OR when `cortex-ai-init` finds a Git repository during project registration.

Do NOT activate if the project has no `.git/` directory or no configured remote.

## Hard Rules

- NEVER access private repositories without a valid `GITHUB_TOKEN`.
- NEVER push code or modify the Git repository — this skill is READ-ONLY with respect to Git.
- Always detect the remote provider (GitHub, GitLab, Bitbucket) from `git remote -v` and use the appropriate MCP tools.
- If the GitHub MCP is not configured or unreachable, skip gracefully and report the limitation.
- The generated `git-context.md` MUST use the template from `assets/git-context-template.md`.
- Limit data volume: fetch at most 50 recent commits, 20 open PRs, 20 open issues, and 10 recently closed PRs/issues.
- Upload `git-context.md` to Drive FIRST, then index in NotebookLM.
- Preserve existing project documentation — `git-context.md` is additive.

## Decision Gates

| Situation | Action |
|-----------|--------|
| No `.git/` directory in project root | Skip; report "not a Git repository" |
| No configured remote (`git remote -v` empty) | Skip; report "no remote configured" |
| Remote is not GitHub/GitLab/Bitbucket | Skip; report "unsupported remote provider: {provider}" |
| `GITHUB_TOKEN` not set or invalid | Skip; report "authentication required" |
| GitHub MCP unreachable | Skip; report "GitHub MCP unavailable" |
| No commits found | Create `git-context.md` with empty sections; note "fresh repository" |
| Drive upload fails | Retry once; skip on second failure |
| NotebookLM indexing fails | Mark `pending-indexing`; Drive file stays intact |
| Project has >50 commits since last sync | Fetch only the most recent 50; note truncation |

## Execution Steps

1. **Verify Git repository.** Check for `.git/` directory in the project root. If absent, abort cleanly with "not a Git repository."
2. **Detect remote provider.** Run `git remote -v` to extract the remote URL. Parse provider:
   - `github.com` → GitHub
   - `gitlab.com` → GitLab
   - Other → report "unsupported provider" and abort
3. **Extract owner/repo.** Parse the remote URL to get `{owner}/{repo}`. Handle both SSH (`git@github.com:owner/repo.git`) and HTTPS (`https://github.com/owner/repo.git`) formats.
4. **Fetch recent commits.** Use GitHub MCP `list_commits` (or equivalent) with `{owner}/{repo}`, limited to 50 most recent. For each commit extract: SHA (short), author, date, message (first line).
5. **Fetch open PRs/MRs.** Use GitHub MCP `list_pull_requests` with state `open`, limited to 20. For each PR extract: number, title, author, head branch, base branch, created date, labels.
6. **Fetch recently closed PRs/MRs.** Use GitHub MCP `list_pull_requests` with state `closed`, limited to 10. For each PR extract: number, title, author, merged boolean, closed date.
7. **Fetch open issues.** Use GitHub MCP `list_issues` with state `open`, limited to 20. For each issue extract: number, title, author, labels, created date, priority (from labels if available).
8. **Fetch recently closed issues.** Use GitHub MCP `list_issues` with state `closed`, limited to 10. For each issue extract: number, title, author, closed date.
9. **Generate `git-context.md`.** Fill the template from `assets/git-context-template.md` with all collected data. Use the current ISO-8601 timestamp for `last-sync` field.
10. **Resolve project record.** Search Engram for `cortex-ai/{project-slug}` to get Drive folder ID and notebook ID. If not found, search Drive for the project README.
11. **Upload to Drive.** Call `createTextFile(name: "git-context.md", content: <generated-content>, parentFolderId: <project-drive-folder-id>)`. If a `git-context.md` already exists in Drive (from a previous sync), replace it by deleting the old one first.
12. **Index in NotebookLM.** Call `notebooklm_source_add(source_type="text", text=<git-context-content>, title="git-context.md")`. If a source named `git-context.md` already exists in the notebook, delete it first via `notebooklm_source_delete` then re-add.
13. **Update cross-reference.** Call `mem_save` with topic key `cortex-ai/{project-slug}`, updating the `last-git-sync` timestamp.

## Output Contract

```
CORTEX-AI git sync complete for {project-name}
  Remote: {provider} — {owner}/{repo}
  Commits synced: {n} (last {range})
  Open PRs: {n}
  Closed PRs (recent): {n}
  Open issues: {n}
  Closed issues (recent): {n}
  git-context.md uploaded to Drive: {status}
  Notebook source updated: {status}
  Last git sync: {iso-8601}
```

## References

- `assets/git-context-template.md` — template for the generated git-context.md document.
- `cortex-ai-init` — registers a project; may invoke this skill for Git repos.
- `cortex-ai-push` — may invoke this skill as an optional step.
- `cortex-ai-git-context` — queries the git context generated by this skill.
