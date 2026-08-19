---
name: cortex-ai-autosync-setup
description: "Trigger: setup autosync, configurar sync automatico, install hooks, instalar hooks, autosync setup, enable auto sync. Install Git hooks for automatic documentation synchronization in a registered CORTEX-AI project."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-autosync-setup

## Activation Contract

Activate when the user explicitly requests enabling automatic synchronization, OR when `cortex-ai-init` asks the user whether to enable auto-sync and they confirm.

Do NOT activate if the project is not a Git repository.
Do NOT activate if the project is not registered in CORTEX-AI (no Drive folder).
Do NOT activate if hooks are already installed (`.git/hooks/post-commit` contains CORTEX-AI marker).

## Hard Rules

- NEVER overwrite existing Git hooks — if `post-commit` or `post-push` already exists and does not contain a CORTEX-AI marker, ABORT and report "existing hook detected, manual setup required."
- The hooks are BASH scripts — verify the system has `/bin/bash` available.
- Always make the hook scripts executable (`chmod +x`).
- Create the `.cortex-ai/` directory in the project root for marker files.
- The hooks must be idempotent — running setup twice should not duplicate hooks.
- Store the hook template files from `assets/` — do NOT inline hook logic in the SKILL.md.

## Decision Gates

| Situation | Action |
|-----------|--------|
| `.git/` directory does not exist | Abort; report "not a Git repository" |
| Project not registered in CORTEX-AI | Abort; suggest `cortex-ai-init` first |
| `.git/hooks/post-commit` exists without CORTEX-AI marker | Abort; report "existing hook detected" |
| `.git/hooks/post-push` exists without CORTEX-AI marker | Abort; report "existing hook detected" |
| `.git/hooks/post-commit` already has CORTEX-AI marker | Report "hooks already installed"; no-op |
| `.git/hooks/post-push` already has CORTEX-AI marker | Report "hooks already installed"; no-op |
| `/bin/bash` not available | Abort; report "bash required for hooks" |
| Hook file write fails | Report failure; do not leave partial state |

## Execution Steps

1. **Verify prerequisites.** Confirm `.git/` exists in project root AND project is registered in CORTEX-AI (cross-reference exists in Engram or Drive README is valid).
2. **Check for existing hooks.** Read `.git/hooks/post-commit` and `.git/hooks/post-push` if they exist. If either file exists and does NOT contain the string `CORTEX-AI`, abort and report "existing hook detected — manual setup required."
3. **Create marker directory.** Create `.cortex-ai/` in the project root. This directory stores:
   - `pending-sync` — marker file created by hooks, consumed by `cortex-ai-autosync-check`
   - `last-sync` — timestamp of last successful auto-sync
4. **Install post-commit hook.** Copy `assets/post-commit.sh` content to `.git/hooks/post-commit`. Make it executable with `chmod +x .git/hooks/post-commit`.
5. **Install post-push hook.** Copy `assets/post-push.sh` content to `.git/hooks/post-push`. Make it executable with `chmod +x .git/hooks/post-push`.
6. **Verify installation.** Read both hook files back and confirm they contain the CORTEX-AI marker string. Report success.
7. **Persist configuration.** Update the cross-reference in Engram (`cortex-ai/{project-slug}`) to include `autosync: true`.

## Output Contract

```
CORTEX-AI auto-sync enabled for {project-name}
  Hooks installed:
    .git/hooks/post-commit — detects documentation changes per commit
    .git/hooks/post-push — triggers full sync after push
  Marker directory: .cortex-ai/
  Behavior:
    - After each commit: changed docs are queued for sync
    - After each push: full sync is queued
    - Sync runs at next session start via cortex-ai-autosync-check
  To disable: remove .git/hooks/post-commit and .git/hooks/post-push
```

## References

- `assets/post-commit.sh` — post-commit hook template (detects doc changes).
- `assets/post-push.sh` — post-push hook template (triggers full sync).
- `cortex-ai-autosync-check` — processes pending sync markers at session start.
- `cortex-ai-push` — the sync operation triggered by auto-sync.
