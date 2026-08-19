---
name: cortex-ai-team
description: "Trigger: create team, crear equipo, team setup, configurar equipo, manage team, listar equipos, list teams. Create and manage team namespaces for organizing projects in CORTEX-AI."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-team

## Activation Contract

Activate when the user wants to create a new team, list existing teams, or manage team membership. Also activate when `cortex-ai-init` needs to resolve a team namespace.

## Hard Rules

- Team slug MUST be normalized kebab-case derived from the team name.
- Team folder structure is `CORTEX-AI/{team-slug}/` — projects live inside as `CORTEX-AI/{team-slug}/{project-slug}`.
- The team folder MUST contain a `README.md` with team metadata (template from `assets/team-readme-template.md`).
- Creating a team is idempotent — if the team folder already exists with a valid README, report "team already exists" and stop.
- NEVER delete a team folder or its projects — use `cortex-ai-cleanup` for archival.
- Teams are purely organizational — they do NOT enforce access control (use repository permissions for that).
- If no team is specified during `cortex-ai-init`, the project is placed in the root: `CORTEX-AI/{project-slug}` (no team prefix).

## Decision Gates

| Situation | Action |
|-----------|--------|
| Team folder already exists with valid README | Report "team already exists"; stop |
| Team folder exists but README is missing/corrupt | Repair in place; generate README |
| `CORTEX-AI` root folder missing | Create it first, then create team folder |
| User requests team list | Enumerate `CORTEX-AI/` children; filter folders with valid team READMEs |
| User requests project count per team | List team children; count subfolders with valid project READMEs |
| Team name contains invalid characters | Normalize to kebab-case; warn user of transformation |

## Execution Steps

### Create Team

1. **Locate or create root.** Ensure `CORTEX-AI` folder exists in Drive.
2. **Check team existence.** List children of `CORTEX-AI`. If `{team-slug}` subfolder exists, read its `README.md`. If valid, report "team already exists" and stop. If exists but README corrupt, repair in place.
3. **Create team folder.** Call `createFolder(name: team-slug, parent: root_id)`.
4. **Compose team README.** Fill `assets/team-readme-template.md` with team name, description, ISO-8601 date, UUID, and initial project count (0).
5. **Upload README.** Call `createTextFile(name: "README.md", content: readme_content, parentFolderId: team_folder_id)`.
6. **Persist team record.** Call `mem_save` with topic key `cortex-ai/team/{team-slug}`, type `config`, storing: team ID, Drive folder ID, creation date, project list (initially empty).

### List Teams

1. **Locate root.** Find `CORTEX-AI` folder in Drive.
2. **Enumerate children.** Call `listFolder(folderId: root_id)`.
3. **Filter teams.** For each subfolder, read `README.md`. If it contains a `team-uuid` field, it's a team. If it contains a `project-id` field, it's a standalone project (not in a team).
4. **Build team list.** For each team, count project subfolders. Output: Team Name | Projects | Last Activity.

### Add Project to Team

This is handled automatically by `cortex-ai-init` when a team is specified — the init skill creates the project under `CORTEX-AI/{team-slug}/{project-slug}` instead of `CORTEX-AI/{project-slug}`.

## Output Contract

### Create Team
```
Team created: {team-name}
  Team ID: {uuid}
  Drive folder: {url}
  Projects: 0
  Cross-reference saved to engram → cortex-ai/team/{team-slug}
```

### List Teams
```
CORTEX-AI Teams — {n} teams

| Team | Projects | Last Activity |
|------|----------|---------------|
| {team-name} | {n} | {date} |

Total projects across all teams: {n}
Standalone projects (no team): {n}
```

## References

- `assets/team-readme-template.md` — team README template with required fields.
- `cortex-ai-init` — invokes this skill when a team is specified during project registration.
- `cortex-ai-status-team` — generates health reports filtered by team.
- `cortex-ai-cleanup` — archives inactive projects within a team.
