# CORTEX-AI — Segundo Cerebro para Agentes de Codificación

**CORTEX-AI** es un sistema de gestión de conocimiento que proporciona a los agentes de codificación (Claude Code, OpenCode, Gemini CLI, Codex, etc.) memoria persistente e inteligencia de proyecto entre sesiones. Funciona como un **segundo cerebro**: cada decisión de proyecto, especificación, documento de arquitectura y activo de diseño vive en Google Drive y es indexado por Google NotebookLM para recuperación semántica.

## Qué Hace

- **Memoria persistente de proyecto** — especificaciones, decisiones y diseños sobreviven entre sesiones y agentes.
- **Búsqueda semántica** — consulta el conocimiento del proyecto en lenguaje natural vía NotebookLM.
- **Búsqueda entre proyectos** — encuentra dónde resolviste algo antes, en todos tus proyectos.
- **Resúmenes de retorno** — retoma el trabajo después de días o semanas con un resumen ejecutivo generado por IA.
- **Panel de salud del sistema** — ve qué proyectos están sincronizados, pendientes de indexación o necesitan atención.
- **Soporte multi-agente** — funciona con OpenCode, Claude Code, Gemini CLI y cualquier agente que soporte servidores MCP.

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                AGENTE DE CODIFICACIÓN                │
│  (OpenCode / Claude Code / Gemini / Codex / etc.)   │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Skills  │  │   MCP    │  │   MCP    │          │
│  │   (7)    │  │notebooklm│  │google-dri│          │
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
│ Referencia│  │  IA Google  │  │  Almacén de  │
│ cruzada y │  │  Búsqueda   │  │   archivos   │
│  memoria  │  │  semántica  │  │  (fuente de  │
│persistente│  │             │  │   verdad)    │
└───────────┘  └─────────────┘  └──────────────┘
```

### Componentes

| Componente | Tecnología | Rol |
|-----------|-----------|------|
| **Skills** (7) | Archivos Markdown de instrucción | Flujos expertos que enseñan a los agentes a usar el segundo cerebro |
| **Google Drive** | MCP `@piotr-agier/google-drive-mcp` | Almacena docs del proyecto, specs, READMEs — la fuente de verdad |
| **Google NotebookLM** | MCP `notebooklm-mcp-cli` | Indexa documentos de Drive, provee búsqueda semántica y resúmenes |
| **Engram** | CLI `engram` | Memoria persistente de referencias cruzadas — mapea IDs de proyecto → IDs de carpeta Drive → IDs de Notebook |

## Los Siete Skills

| Skill | Activadores | Qué Hace |
|-------|---------|--------------|
| `cortex-ai-init` | "init cortex", "inicializar cerebro" | Registra un proyecto: crea carpeta en Drive, README, notebook NotebookLM, referencia cruzada |
| `cortex-ai-push` | "push cortex", "sync docs", "publicar documentacion" | Sincroniza docs locales modificados → Drive → NotebookLM (aditivo, nunca elimina) |
| `cortex-ai-ask` | "ask cortex", "pregunta sobre", "consulta" | Consulta el conocimiento del proyecto vía NotebookLM primero, docs locales como respaldo |
| `cortex-ai-onboard` | "resume del proyecto", "ponme al dia", "executive summary" | Genera un resumen ejecutivo desde el notebook para retomar después de inactividad |
| `cortex-ai-status` | "status del cerebro", "panorama", "how is the brain" | Reporte de salud de todo el sistema en TODOS los proyectos registrados |
| `cortex-ai-cross-search` | "buscar en todos", "cross search", "en que proyecto ya" | Busca la misma consulta en TODOS los notebooks de proyectos a la vez |
| `cortex-ai-reindex` | "reindexa", "rebuild notebook", "reconstruir notebook" | Reconstrucción destructiva de un notebook desde los contenidos de la carpeta Drive |

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
│   └── engram.json
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
- **Node.js** — requerido por el MCP de Google Drive (`npx`).

## Inicio Rápido

Consulta **[INSTALL-es.md](./INSTALL-es.md)** para los pasos detallados de instalación por agente.

1. Instala los tres servidores MCP.
2. Configura la sección MCP de tu agente de codificación (usa los archivos en `configs/` como plantilla).
3. Copia los skills al directorio de skills de tu agente.
4. Ejecuta `cortex-ai-init` en tu primer proyecto.

## Licencia

Apache-2.0
