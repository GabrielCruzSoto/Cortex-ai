# CORTEX-AI — Installation & Configuration Guide

This guide covers installing CORTEX-AI for **OpenCode**, **Claude Code**, **Gemini CLI**, **Codex**, and any other MCP-compatible agent.

---

## 1. Prerequisites

### Required Software

| Tool | How to Install | Purpose |
|------|---------------|---------|
| **Node.js** >= 18 | `brew install node` or [nodejs.org](https://nodejs.org) | Required by `google-drive-mcp` (runs via `npx`) |
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

```bash
# Via Homebrew
brew install gentle-ai/gentle-ai/engram
```

If not using engram, CORTEX-AI will rely on Drive READMEs for cross-references.

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
- Create a `CORTEX-AI/` root folder in Google Drive (if it doesn't exist).
- Create a project subfolder (`CORTEX-AI/{project-slug}/`).
- Generate and upload a `README.md` with project metadata.
- Upload all project documentation (`.md`, `.pdf`, `.drawio`, `.docx`, `.xlsx`, images) to Drive.
- Create a Google NotebookLM notebook indexed with those documents.
- Persist the cross-reference (project ID ↔ Drive folder ID ↔ Notebook ID).

---

## 4. Daily Workflow

```
init cortex     → Once per project
push cortex     → After writing/changing docs, specs, decisions
ask cortex      → Ask about project decisions, specs, history
status cortex   → Check system health
onboard         → Resume work after inactivity
reindex         → Rebuild a corrupted notebook (rarely needed)
cross search    → Find something across all projects
```

---

## 5. Troubleshooting

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

### "NotebookLM says no sources"

Run `push cortex` to sync local docs to Drive and NotebookLM. If docs are already in Drive but not indexed, run `reindex`.

### "Skills don't activate"

- Verify skills are in the correct directory for your agent.
- Check that the agent supports skill loading from that directory.
- For OpenCode, the `skill-registry` plugin auto-indexes skills at startup.

---

## 6. Agent-Specific MCP Config Snippets

Ready-to-use config files are in `configs/`:

| File | Agent | Merge Into |
|------|-------|------------|
| `configs/opencode.json` | OpenCode | `~/.config/opencode/opencode.json` → `mcp` section |
| `configs/claude-code.json` | Claude Code | `~/.claude/settings.json` → `mcpServers` section |
| `configs/gemini.json` | Gemini CLI | `~/.gemini/settings.json` → `mcpServers` section |
| `configs/codex.json` | Codex CLI | `~/.codex/config.json` → `mcp` section |

---

## 7. File Locations Reference

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
| engram | `/home/linuxbrew/.linuxbrew/bin/engram` (via brew) |
