---
name: cortex-ai-status-team
description: "Trigger: team status, status equipo, panorama equipo, team health, salud equipo, equipo status. Generate a health report for projects within a specific team or across all teams."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-status-team

## Activation Contract

Activate when the user requests a health report scoped to a specific team, or a comparative overview across all teams.

Do NOT activate for single-project queries — use `cortex-ai-ask`.
Do NOT activate for system-wide queries without team scope — use `cortex-ai-status`.

## Hard Rules

- Never fabricate project data when Drive MCP is unreachable.
- Always show team-level aggregates alongside per-project details.
- If a team folder exists but has no registered projects, report "team exists but has no projects."
- Comparative view must normalize by project count to avoid misleading rankings.
- Auto-sync and Git status are informational — they do not affect team health classification.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Specified team does not exist | Report "team not found"; list available teams |
| Team exists but has no projects | Report "team has no projects"; suggest `cortex-ai-init` |
| Drive MCP fails | Report partial/unavailable; do not fake data |
| NotebookLM MCP fails for a project in the team | Mark as "indexing-status unknown" for that project |
| User requests all-teams comparison | Generate comparative table across all teams |

## Execution Steps

### Single Team Report

1. **Resolve team.** Search Engram for `cortex-ai/team/{team-slug}` or locate team folder in Drive.
2. **List team projects.** Enumerate children of `CORTEX-AI/{team-slug}/`. For each subfolder with a valid project README, extract: project name, project ID, last-update date.
3. **Query notebooks.** For each project, resolve notebook ID and call `notebooklm_notebook_get` for source count and last-source-added.
4. **Check auto-sync status.** For each project, check `.git/hooks/post-commit` for CORTEX-AI marker (if local access available) or check Engram for `autosync: true` flag.
5. **Classify each project.** Determine status: `ok`, `desync`, `pending-indexing`, `init-incomplete`, `invalid-registry`, `unknown`.
6. **Build team summary.** Calculate team-level aggregates: total projects, healthy vs needing action, total notebook sources, average sources per project.
7. **Deliver report.** Present per-project table plus team summary.

### All-Teams Comparison

1. **List all teams.** Enumerate `CORTEX-AI/` children; filter team folders (those with valid team READMEs).
2. **For each team:** Run steps 2-6 from single team report.
3. **Build comparison table.** Columns: Team | Projects | Healthy | Needs Action | Total Sources | Avg Sources/Project.
4. **Rank teams.** Sort by health percentage (healthy/total).
5. **Surface outliers.** Highlight teams with <50% healthy projects or projects with 0 notebook sources.

## Output Contract

### Single Team
```
CORTEX-AI Team Health — {team-name} ({n} projects)

| Project | Last Sync | Sources | Auto-sync | Status |
|---------|-----------|---------|-----------|--------|
| ...     | ...       | ...     | ...       | ...    |

Team Summary:
  Total projects: {n}
  Healthy: {n} ({percentage}%)
  Needs action: {n}
  Total notebook sources: {n}
  Average sources per project: {n}
```

### All Teams
```
CORTEX-AI Cross-Team Overview — {n} teams, {m} total projects

| Team | Projects | Healthy | Needs Action | Avg Sources | Health % |
|------|----------|---------|--------------|-------------|----------|
| ...  | ...      | ...     | ...          | ...         | ...      |

Outliers:
  ⚠️ {team-name}: {x}/{n} projects need attention
  ⚠️ {team-name}: projects with 0 notebook sources — {list}
```

## References

- `cortex-ai-status` — system-wide health without team scope.
- `cortex-ai-team` — creates and manages team namespaces.
- `cortex-ai-init` — registers projects within teams.
- `cortex-ai-cleanup` — archives inactive projects.
