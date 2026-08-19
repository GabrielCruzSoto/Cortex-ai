# CORTEX-AI — Segundo Cerebro para Agentes de Codificación

**CORTEX-AI** es un sistema de gestión de conocimiento que proporciona a los agentes de codificación (Claude Code, OpenCode, Gemini CLI, Codex, etc.) memoria persistente e inteligencia de proyecto entre sesiones. Funciona como un **segundo cerebro**: cada decisión de proyecto, especificación, documento de arquitectura y activo de diseño vive en Google Drive y es indexado por Google NotebookLM para recuperación semántica.

## Qué Hace

- **Memoria persistente de proyecto** — especificaciones, decisiones y diseños sobreviven entre sesiones y agentes.
- **Búsqueda semántica** — consulta el conocimiento del proyecto en lenguaje natural vía NotebookLM.
- **Búsqueda entre proyectos** — encuentra dónde resolviste algo antes, en todos tus proyectos.
- **Resúmenes de retorno** — retoma el trabajo después de días o semanas con un resumen ejecutivo generado por IA.
- **Panel de salud del sistema** — ve qué proyectos están sincronizados, pendientes de indexación o necesitan atención.
- **Soporte multi-agente** — funciona con OpenCode, Claude Code, Gemini CLI y cualquier agente que soporte servidores MCP.
- **Integración Git** — sincroniza commits, PRs e issues al segundo cerebro para contexto completo del proyecto.
- **Auto-sync** — hooks de Git encolan automáticamente los cambios de documentación para sincronizar en commit/push.
- **Organización por equipos** — agrupa proyectos en namespaces de equipo para gestión organizada.
- **Búsqueda escalable** — cross-search paginado con filtro por equipo para despliegues grandes.
- **Limpieza y archivado** — archiva proyectos inactivos y limpia fuentes de notebook obsoletas.

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                AGENTE DE CODIFICACIÓN                │
│  (OpenCode / Claude Code / Gemini / Codex / etc.)   │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Skills  │  │   MCP    │  │   MCP    │          │
│  │  (10)    │  │notebooklm│  │google-dri│          │
│  └──────────┘  └────┬─────┘  └────┬─────┘          │
│                      │             │                 │
│  ┌──────────┐  ┌─────┴─────┐  ┌───┴───────┐        │
│  │   MCP    │  │   MCP    │  │   MCP    │        │
│  │  engram  │  │  github   │  │codegraph  │        │
│  └────┬─────┘  └─────┬─────┘  └─────┬─────┘        │
└───────┼──────────────┼───────────────┼──────────────┘
        │              │               │
        ▼              ▼               ▼
┌───────────┐  ┌─────────────┐  ┌──────────────┐
│  ENGRAM   │  │ NOTEBOOKLM  │  │ GOOGLE DRIVE │
│ Referencia│  │  IA Google  │  │  Almacén de  │
│ cruzada y │  │  Búsqueda   │  │   archivos   │
│  memoria  │  │  semántica  │  │  (fuente de  │
│persistente│  │             │  │   verdad)    │
└───────────┘  └─────────────┘  └──────────────┘
        │                              │
        ▼                              ▼
┌───────────────┐            ┌──────────────────┐
│    GITHUB     │            │   CODEGRAPH      │
│  Commits, PRs │            │  Índice de código │
│  Issues, etc. │            │  símbolos, grafo  │
└───────────────┘            │  de llamadas      │
                             └──────────────────┘
```

### Componentes

| Componente | Tecnología | Rol |
|-----------|-----------|------|
| **Skills** (15) | Archivos Markdown de instrucción | Flujos expertos que enseñan a los agentes a usar el segundo cerebro |
| **Google Drive** | MCP `@piotr-agier/google-drive-mcp` | Almacena docs del proyecto, specs, READMEs — la fuente de verdad |
| **Google NotebookLM** | MCP `notebooklm-mcp-cli` | Indexa documentos de Drive, provee búsqueda semántica y resúmenes |
| **Engram** | CLI `engram` | Memoria persistente de referencias cruzadas — mapea IDs de proyecto → IDs de carpeta Drive → IDs de Notebook |
| **GitHub** | MCP `@modelcontextprotocol/server-github` | Lee commits, PRs e issues para sincronizar el contexto Git |
| **CodeGraph** | CLI `codegraph` | Índice de código fuente con navegación por símbolos, grafo de llamadas y análisis de impacto |

## Los Quince Skills

| Skill | Activadores | Qué Hace |
|-------|---------|--------------|
| `cortex-ai-init` | "init cortex", "inicializar cerebro" | Registra un proyecto: crea carpeta en Drive, README, notebook NotebookLM, referencia cruzada + sync Git opcional + auto-sync opcional + soporte de equipos |
| `cortex-ai-push` | "push cortex", "sync docs", "publicar documentacion" | Sincroniza docs locales modificados → Drive → NotebookLM + refresh de contexto Git opcional (soporta proyectos con equipo) |
| `cortex-ai-ask` | "ask cortex", "pregunta sobre", "consulta" | Consulta el conocimiento del proyecto vía NotebookLM primero, docs locales como respaldo |
| `cortex-ai-onboard` | "resume del proyecto", "ponme al dia", "executive summary" | Genera un resumen ejecutivo desde el notebook + actividad Git para retomar después de inactividad |
| `cortex-ai-status` | "status del cerebro", "panorama", "how is the brain" | Reporte de salud de todo el sistema en TODOS los proyectos registrados (incluye estado de sync Git + auto-sync) |
| `cortex-ai-cross-search` | "buscar en todos", "cross search", "en que proyecto ya" | Busca la misma consulta en los notebooks con paginación y filtro por equipo |
| `cortex-ai-reindex` | "reindexa", "rebuild notebook", "reconstruir notebook" | Reconstrucción destructiva de un notebook desde los contenidos de la carpeta Drive |
| `cortex-ai-git-sync` | "sync git", "git context", "sincronizar git" | Sincroniza metadata del repositorio Git (commits, PRs, issues) a Drive y NotebookLM |
| `cortex-ai-git-context` | "git context", "quién trabajó", "hay PRs" | Consulta la actividad Git de un proyecto desde el documento git-context sincronizado |
| `cortex-ai-autosync-setup` | "setup autosync", "install hooks", "configurar sync automatico" | Instala hooks de Git para sincronización automática de documentación |
| `cortex-ai-autosync-check` | "check autosync", "pending sync", "procesar sync" | Verifica marcadores de sync pendiente y ejecuta la sincronización encolada |
| `cortex-ai-team` | "create team", "crear equipo", "list teams" | Crea y gestiona namespaces de equipo para organizar proyectos |
| `cortex-ai-status-team` | "team status", "status equipo", "team health" | Reporte de salud filtrado por equipo o comparativo entre equipos |
| `cortex-ai-cleanup` | "cleanup", "archivar", "archive project", "limpiar" | Archiva proyectos inactivos, limpia fuentes obsoletas, genera reportes de almacenamiento |
| `cortex-ai-codegraph` | "codegraph", "explore code", "find symbol", "who calls", "impact analysis", "que usa esto", "que rompe esto" | Explora la estructura del código y símbolos vía CodeGraph MCP — complementa la documentación con inteligencia de código |

## Estructura del Proyecto

```
cortex-ai/
├── README.md                    # Este archivo (inglés)
├── README-es.md                 # Versión en español
├── INSTALL.md                   # Guía de instalación (inglés)
├── INSTALL-es.md                # Guía de instalación (español)
├── skills/                      # Definiciones de los skills CORTEX-AI
│   ├── cortex-ai-ask/SKILL.md
│   ├── cortex-ai-cross-search/SKILL.md
│   ├── cortex-ai-git-context/SKILL.md
│   ├── cortex-ai-git-sync/
│   │   ├── SKILL.md
│   │   └── assets/git-context-template.md
│   ├── cortex-ai-autosync-setup/
│   │   ├── SKILL.md
│   │   └── assets/
│   │       ├── post-commit.sh
│   │       └── post-push.sh
│   ├── cortex-ai-autosync-check/SKILL.md
│   ├── cortex-ai-team/
│   │   ├── SKILL.md
│   │   └── assets/team-readme-template.md
│   ├── cortex-ai-status-team/SKILL.md
│   ├── cortex-ai-cleanup/SKILL.md
│   ├── cortex-ai-codegraph/SKILL.md
│   ├── cortex-ai-init/
│   │   ├── SKILL.md
│   │   └── assets/readme-template.md
│   ├── cortex-ai-onboard/SKILL.md
│   ├── cortex-ai-push/SKILL.md
│   ├── cortex-ai-reindex/SKILL.md
│   └── cortex-ai-status/SKILL.md
├── mcp/                         # Configs individuales de servidores MCP
│   ├── notebooklm.json
│   ├── google-drive.json
│   ├── engram.json
│   ├── github.json
│   └── codegraph.json
├── configs/                     # Configs listas para usar por agente
│   ├── opencode.json
│   ├── claude-code.json
│   ├── gemini.json
│   └── codex.json
└── .atl/                        # Meta-artefactos autogenerados
    └── skill-registry.md
```

## Prerrequisitos

- **Cuenta de Google** — para acceso a Google Drive y NotebookLM.
- **notebooklm-mcp** — servidor MCP para NotebookLM (`uv tool install notebooklm-mcp-cli`).
- **google-drive-mcp** — servidor MCP para Google Drive (`npx @piotr-agier/google-drive-mcp`).
- **engram** — opcional pero recomendado, para persistencia de referencias cruzadas.
- **codegraph** — opcional pero recomendado, para inteligencia de código y navegación por símbolos (`curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`).
- **Node.js** — requerido por el MCP de Google Drive (`npx`).
- **Token de acceso personal de GitHub** — opcional, para sincronización del contexto Git (variable de entorno `GITHUB_TOKEN`).

## Inicio Rápido

Consulta **[INSTALL-es.md](./INSTALL-es.md)** para los pasos detallados de instalación por agente.

1. Instala los tres servidores MCP.
2. Configura la sección MCP de tu agente de codificación (usa los archivos en `configs/` como plantilla).
3. Copia los skills al directorio de skills de tu agente.
4. Ejecuta `cortex-ai-init` en tu primer proyecto.

## Licencia

Apache-2.0
