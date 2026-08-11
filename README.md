# CORTEX-AI — Second Brain for Coding Agents

<p align="center">
  <img src="logo.png" alt="CORTEX-AI Logo" width="400">
</p>

**CORTEX-AI** is a knowledge management system that gives coding agents (Claude Code, OpenCode, Gemini CLI, Codex, etc.) persistent memory and project intelligence across sessions. It acts as a **second brain**: every project decision, specification, architecture document, and design asset lives in Google Drive and is indexed by Google NotebookLM for semantic retrieval.

## What It Does

- **Persistent project memory** — specs, decisions, designs survive across sessions and agents.
- **Semantic search** — query project knowledge in natural language via NotebookLM.
- **Cross-project search** — find where you solved something before, across all your projects.
- **Onboarding summaries** — resume work after days/weeks with an AI-generated executive summary.
- **System health dashboard** — see which projects are synced, pending indexing, or need attention.
- **Multi-agent support** — works with OpenCode, Claude Code, Gemini CLI, and any agent that supports MCP servers.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  CODING AGENT                        │
│  (OpenCode / Claude Code / Gemini / Codex / etc.)   │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Skills  │  │   MCP    │  │   MCP    │          │
│  │ (7)      │  │notebooklm│  │google-dri│          │
│  └──────────┘  └────┬─────┘  └────┬─────┘          │
│                      │             │                 │
│  ┌──────────┐        │             │                 │
│  │   MCP    │        │             │                 │
│  │  engram  │        │             │                 │
│  └────┬─────┘        │             │                 │
└───────┼──────────────┼─────────────┼────────────────┘
        │              │             │
        ▼              ▼             ▼
┌───────────┐  ┌─────────────┐  ┌──────────────┐
│  ENGRAM   │  │ NOTEBOOKLM  │  │ GOOGLE DRIVE │
│ Cross-ref │  │  Google AI  │  │  File Store  │
│ Persist.  │  │  Semantic   │  │  (source of  │
│  Memory   │  │   Search    │  │   truth)     │
└───────────┘  └─────────────┘  └──────────────┘
```

### Components

| Component | Technology | Role |
|-----------|-----------|------|
| **Skills** (7) | Markdown instruction files | Expert workflows that teach agents how to use the second brain |
| **Google Drive** | MCP `@piotr-agier/google-drive-mcp` | Stores project docs, specs, READMEs — the source of truth |
| **Google NotebookLM** | MCP `notebooklm-mcp-cli` | Indexes Drive documents, provides semantic search and summaries |
| **Engram** | CLI `engram` | Persistent cross-reference memory — maps project IDs → Drive folder IDs → Notebook IDs |

## The Seven Skills

| Skill | Trigger | What It Does |
|-------|---------|--------------|
| `cortex-ai-init` | "init cortex", "inicializar cerebro" | Register a project: creates Drive folder, README, NotebookLM notebook, cross-reference |
| `cortex-ai-push` | "push cortex", "sync docs" | Sync changed local docs → Drive → NotebookLM (additive, never deletes) |
| `cortex-ai-ask` | "ask cortex", "pregunta sobre" | Query project knowledge via NotebookLM first, local docs as fallback |
| `cortex-ai-onboard` | "resume del proyecto", "ponme al dia" | Generate executive summary from notebook to resume after inactivity |
| `cortex-ai-status` | "status del cerebro", "how is the brain" | System-wide health report across ALL registered projects |
| `cortex-ai-cross-search` | "buscar en todos", "cross search" | Search the same query across ALL project notebooks at once |
| `cortex-ai-reindex` | "reindexa", "rebuild notebook" | Destructive rebuild of a notebook from Drive folder contents |

## Project Structure

```
cortex-ai/
├── README.md                    # This file (English)
├── README-es.md                 # Spanish version
├── INSTALL.md                   # Installation guide (English)
├── INSTALL-es.md                # Installation guide (Spanish)
├── skills/                      # CORTEX-AI skill definitions
│   ├── cortex-ai-ask/SKILL.md
│   ├── cortex-ai-cross-search/SKILL.md
│   ├── cortex-ai-init/
│   │   ├── SKILL.md
│   │   └── assets/readme-template.md
│   ├── cortex-ai-onboard/SKILL.md
│   ├── cortex-ai-push/SKILL.md
│   ├── cortex-ai-reindex/SKILL.md
│   └── cortex-ai-status/SKILL.md
├── mcp/                         # MCP server config snippets
│   ├── notebooklm.json
│   ├── google-drive.json
│   └── engram.json
├── configs/                     # Per-agent ready-to-use configs
│   ├── opencode.json
│   ├── claude-code.json
│   ├── gemini.json
│   └── codex.json
└── .atl/                        # Auto-generated meta-artifacts
    └── skill-registry.md
```

## Prerequisites

- **Google Account** — for Google Drive and NotebookLM access.
- **notebooklm-mcp** — MCP server for NotebookLM (`uv tool install notebooklm-mcp-cli`).
- **google-drive-mcp** — MCP server for Google Drive (`npx @piotr-agier/google-drive-mcp`).
- **engram** — optional but recommended, for cross-reference persistence.
- **Node.js** — required by the google-drive MCP (`npx`).

## Quick Start

See **[INSTALL.md](./INSTALL.md)** (English) or **[INSTALL-es.md](./INSTALL-es.md)** (Español) for detailed per-agent installation steps.

1. Install the three MCP servers.
2. Configure your coding agent's MCP section (use files in `configs/` as templates).
3. Copy the skills to your agent's skills directory.
4. Run `cortex-ai-init` on your first project.

## License

Apache-2.0
