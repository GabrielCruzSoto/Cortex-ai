# CORTEX-AI — Installation & Configuration Guide

This guide covers installing CORTEX-AI for **OpenCode**, **Claude Code**, **Gemini CLI**, **Codex**, and any other MCP-compatible agent.

---

## 1. Prerequisites

### Required Software

| Tool | How to Install | Purpose |
|------|---------------|---------|
| **Node.js** >= 18 | `brew install node` or [nodejs.org](https://nodejs.org) | Required by `google-drive-mcp` and `github-mcp` (run via `npx`) |
| **Python** >= 3.12 | `brew install python` or [python.org](https://python.org) | Required by `uv` (package manager for notebooklm-mcp) |

### Install MCP Servers

#### notebooklm-mcp

```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install notebooklm-mcp-cli
uv tool install notebooklm-mcp-cli

# Authenticate with Google
nlm login
```

Verification:
```bash
notebooklm-mcp --help
nlm --help
```

#### google-drive-mcp

```bash
# Pre-fetch the package so first agent startup is fast
npx -y @piotr-agier/google-drive-mcp --help
```

No manual auth needed — the MCP server handles OAuth on first connection.

#### engram (optional, recommended)

Install from: [github.com/Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram)

If not using engram, CORTEX-AI will rely on Drive READMEs for cross-references.

#### github-mcp (optional, for Git integration)

```bash
# Create a GitHub Personal Access Token at:
# https://github.com/settings/tokens
# Required scopes: repo (full control of private repositories)

# Export the token
export GITHUB_TOKEN=ghp_your_token_here
```

The GitHub MCP server runs via `npx` — no separate installation needed. It is configured in the agent's MCP section (see below).

---

## 2. Agent Configuration

### OpenCode

Config location: `~/.config/opencode/opencode.json` (or `opencode.jsonc`)

Add to the `mcp` section:

```json
{
  "mcp": {
    "notebooklm": {
      "type": "local",
      "command": ["notebooklm-mcp"],
      "enabled": true
    },
    "google-drive": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@piotr-agier/google-drive-mcp"]
    },
    "engram": {
      "command": ["engram", "mcp", "--tools=agent,batch"],
      "type": "local"
    },
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

**Skills installation:**

```bash
# Copy skills to OpenCode's skills directory
cp -r skills/* ~/.config/opencode/skills/
```

OpenCode loads skills from `~/.config/opencode/skills/` automatically.

---

### Claude Code

Config location: `~/.claude/settings.json`

Add to the `mcpServers` section (merge with existing entries):

```json
{
  "mcpServers": {
    "notebooklm": {
      "type": "stdio",
      "command": "notebooklm-mcp"
    },
    "google-drive": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@piotr-agier/google-drive-mcp"]
    },
    "engram": {
      "command": "/home/linuxbrew/.linuxbrew/bin/engram",
      "args": ["mcp", "--tools=agent,batch"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Skills installation:**

```bash
# Copy skills to Claude Code's skills directory
cp -r skills/* ~/.claude/skills/
```

Claude Code loads skills from `~/.claude/skills/` via the `memory-management` skill or direct CLI configuration.

---

### Gemini CLI

Config location: `~/.gemini/settings.json`

Add to the `mcpServers` section:

```json
{
  "mcpServers": {
    "notebooklm": {
      "type": "stdio",
      "command": "notebooklm-mcp"
    },
    "google-drive": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@piotr-agier/google-drive-mcp"]
    },
    "engram": {
      "command": "/home/linuxbrew/.linuxbrew/bin/engram",
      "args": ["mcp", "--tools=agent,batch"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Skills installation:**

```bash
# Copy skills to Gemini's skills directory
cp -r skills/* ~/.gemini/skills/
```

Gemini CLI loads skills from `~/.gemini/skills/`.

---

### Codex (OpenAI Codex CLI)

Config location: `~/.codex/config.json` (or `~/.codex-sdk/config.json`)

Add to the `mcp` section (format similar to OpenCode):

```json
{
  "mcp": {
    "notebooklm": {
      "type": "local",
      "command": ["notebooklm-mcp"],
      "enabled": true
    },
    "google-drive": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@piotr-agier/google-drive-mcp"]
    },
    "engram": {
      "command": ["engram", "mcp", "--tools=agent,batch"],
      "type": "local"
    },
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

**Skills installation:**

```bash
# Copy skills to Codex's skills directory (adjust path as needed)
cp -r skills/* ~/.codex/skills/
```

---

## 3. First Project Registration

Once the MCP servers are configured and skills are installed, initialize your first project:

1. Open your coding agent in the project directory.
2. Say: **"init cortex"** or **"inicializar segundo cerebro"**.

The `cortex-ai-init` skill will:
- Ask if you want to assign the project to a **team** (optional).
- Create a `CORTEX-AI/` root folder in Google Drive (if it doesn't exist).
- Create a project subfolder (`CORTEX-AI/{project-slug}/` or `CORTEX-AI/{team-slug}/{project-slug}/`).
- Generate and upload a `README.md` with project metadata.
- Upload all project documentation (`.md`, `.pdf`, `.drawio`, `.docx`, `.xlsx`, images) to Drive.
- Create a Google NotebookLM notebook indexed with those documents.
- Persist the cross-reference (project ID ↔ Drive folder ID ↔ Notebook ID).
- Optionally sync Git context (commits, PRs, issues) if the project is a Git repo.
- Optionally install auto-sync hooks for automatic documentation synchronization.

---

## 4. Daily Workflow

```
init cortex         → Once per project (with optional team, Git sync, auto-sync)
push cortex         → After writing/changing docs, specs, decisions
ask cortex          → Ask about project decisions, specs, history
status cortex       → Check system health across all projects
onboard             → Resume work after inactivity (includes Git activity summary)
reindex             → Rebuild a corrupted notebook (rarely needed)
cross search        → Find something across all projects (with pagination + team filter)
git sync            → Sync Git metadata (commits, PRs, issues) to Drive/NotebookLM
git context         → Query Git activity for a project
team                → Create/list team namespaces
team status         → Health report for a specific team or cross-team comparison
autosync setup      → Install Git hooks for auto-sync
check autosync      → Process pending auto-sync markers
cleanup             → Archive inactive projects, clean stale sources
```

---

## 5. Teams (Optional)

Teams let you organize projects into namespaces. Projects live under `CORTEX-AI/{team-slug}/{project-slug}/` instead of `CORTEX-AI/{project-slug}/`.

### Create a Team

```
Say: "create team backend" or "crear equipo frontend"
```

### Use a Team During Init

```
Say: "init cortex --team backend" or "init cortex con equipo frontend"
```

### List All Teams

```
Say: "list teams" or "listar equipos"
```

### Team-Scoped Status

```
Say: "team status backend" or "status equipo frontend"
```

---

## 6. Auto-Sync (Optional)

Auto-sync installs Git hooks that queue documentation changes for synchronization automatically.

### Enable During Init

When running `cortex-ai-init` on a Git repository, you'll be asked: "Enable automatic documentation sync on commit/push?"

### Enable Manually

```
Say: "setup autosync" or "configurar sync automatico"
```

### How It Works

1. **post-commit hook** — After each commit, if documentation files (`.md`, `.pdf`, etc.) changed, they are queued in `.cortex-ai/pending-sync`.
2. **post-push hook** — After each push, a full sync is queued.
3. **At session start** — Say "check autosync" or the agent checks automatically. Pending syncs are processed via `cortex-ai-push`.

### Disable Auto-Sync

```bash
rm .git/hooks/post-commit .git/hooks/post-push
```

---

## 7. Troubleshooting

### "notebooklm-mcp: command not found"

```bash
# Ensure uv's bin directory is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Reinstall
uv tool install notebooklm-mcp-cli
```

### "google-drive MCP returns auth errors"

The MCP server handles OAuth interactively. If it fails:
1. Ensure a browser is available for the OAuth flow.
2. Check that `npx` can run: `npx --version`.

### "GitHub MCP not working"

1. Ensure `GITHUB_TOKEN` is exported: `echo $GITHUB_TOKEN`
2. Verify the token has `repo` scope at https://github.com/settings/tokens
3. Check the MCP server starts: `npx -y @modelcontextprotocol/server-github`

### "NotebookLM says no sources"

Run `push cortex` to sync local docs to Drive and NotebookLM. If docs are already in Drive but not indexed, run `reindex`.

### "Skills don't activate"

- Verify skills are in the correct directory for your agent.
- Check that the agent supports skill loading from that directory.
- For OpenCode, the `skill-registry` plugin auto-indexes skills at startup.

### "Auto-sync not triggering"

1. Verify hooks are installed: `ls -la .git/hooks/post-commit .git/hooks/post-push`
2. Verify hooks are executable: `chmod +x .git/hooks/post-commit .git/hooks/post-push`
3. Check for pending sync: `cat .cortex-ai/pending-sync`

---

## 8. Agent-Specific MCP Config Snippets

Ready-to-use config files are in `configs/`:

| File | Agent | Merge Into |
|------|-------|------------|
| `configs/opencode.json` | OpenCode | `~/.config/opencode/opencode.json` → `mcp` section |
| `configs/claude-code.json` | Claude Code | `~/.claude/settings.json` → `mcpServers` section |
| `configs/gemini.json` | Gemini CLI | `~/.gemini/settings.json` → `mcpServers` section |
| `configs/codex.json` | Codex CLI | `~/.codex/config.json` → `mcp` section |

---

## 9. File Locations Reference

| Artifact | Path |
|----------|------|
| OpenCode config | `~/.config/opencode/opencode.json` |
| OpenCode skills | `~/.config/opencode/skills/` |
| Claude Code config | `~/.claude/settings.json` |
| Claude Code skills | `~/.claude/skills/` |
| Gemini CLI config | `~/.gemini/settings.json` |
| Gemini CLI skills | `~/.gemini/skills/` |
| Codex CLI config | `~/.codex/config.json` |
| Codex CLI skills | `~/.codex/skills/` |
| notebooklm-mcp binary | `~/.local/bin/notebooklm-mcp` (via `uv`) |
| notebooklm-mcp source | `uv tool install notebooklm-mcp-cli` |
| google-drive-mcp | `npx @piotr-agier/google-drive-mcp` (on demand) |
| github-mcp | `npx @modelcontextprotocol/server-github` (on demand) |
| engram | `/home/linuxbrew/.linuxbrew/bin/engram` (via brew) |
| GITHUB_TOKEN env var | `export GITHUB_TOKEN=ghp_...` |
| Auto-sync markers | `.cortex-ai/pending-sync` (per project) |
| Auto-sync last run | `.cortex-ai/last-sync` (per project) |
