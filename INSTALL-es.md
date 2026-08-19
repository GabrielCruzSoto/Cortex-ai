# CORTEX-AI — Guía de Instalación y Configuración

Esta guía cubre la instalación de CORTEX-AI para **OpenCode**, **Claude Code**, **Gemini CLI**, **Codex** y cualquier otro agente compatible con MCP.

---

## 1. Prerrequisitos

### Software Requerido

| Herramienta | Cómo Instalar | Propósito |
|------|---------------|---------|
| **Node.js** >= 18 | `brew install node` o [nodejs.org](https://nodejs.org) | Requerido por `google-drive-mcp` y `github-mcp` (se ejecutan vía `npx`) |
| **Python** >= 3.12 | `brew install python` o [python.org](https://python.org) | Requerido por `uv` (gestor de paquetes para notebooklm-mcp) |

### Instalar Servidores MCP

#### notebooklm-mcp

```bash
# Instalar uv (gestor de paquetes de Python)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instalar notebooklm-mcp-cli
uv tool install notebooklm-mcp-cli

# Autenticarse con Google
nlm login
```

Verificación:
```bash
notebooklm-mcp --help
nlm --help
```

#### google-drive-mcp

```bash
# Precargar el paquete para que el primer arranque del agente sea rápido
npx -y @piotr-agier/google-drive-mcp --help
```

No se requiere autenticación manual — el servidor MCP maneja OAuth en la primera conexión.

#### engram (opcional, recomendado)

Instalar desde: [github.com/Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram)

Si no se usa engram, CORTEX-AI usará los READMEs de Drive para las referencias cruzadas.

#### github-mcp (opcional, para integración Git)

```bash
# Crear un Token de Acceso Personal de GitHub en:
# https://github.com/settings/tokens
# Scopes requeridos: repo (control total de repositorios privados)

# Exportar el token
export GITHUB_TOKEN=ghp_your_token_here
```

El servidor GitHub MCP se ejecuta vía `npx` — no requiere instalación separada. Se configura en la sección MCP del agente (ver abajo).

---

## 2. Configuración por Agente

### OpenCode

Ubicación de la configuración: `~/.config/opencode/opencode.json` (o `opencode.jsonc`)

Agregar a la sección `mcp`:

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

**Instalación de skills:**

```bash
# Copiar skills al directorio de skills de OpenCode
cp -r skills/* ~/.config/opencode/skills/
```

OpenCode carga los skills desde `~/.config/opencode/skills/` automáticamente.

---

### Claude Code

Ubicación de la configuración: `~/.claude/settings.json`

Agregar a la sección `mcpServers` (combinar con entradas existentes):

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

**Instalación de skills:**

```bash
# Copiar skills al directorio de skills de Claude Code
cp -r skills/* ~/.claude/skills/
```

Claude Code carga los skills desde `~/.claude/skills/` vía el skill `memory-management` o configuración directa del CLI.

---

### Gemini CLI

Ubicación de la configuración: `~/.gemini/settings.json`

Agregar a la sección `mcpServers`:

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

**Instalación de skills:**

```bash
# Copiar skills al directorio de skills de Gemini
cp -r skills/* ~/.gemini/skills/
```

Gemini CLI carga los skills desde `~/.gemini/skills/`.

---

### Codex (OpenAI Codex CLI)

Ubicación de la configuración: `~/.codex/config.json` (o `~/.codex-sdk/config.json`)

Agregar a la sección `mcp` (formato similar a OpenCode):

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

**Instalación de skills:**

```bash
# Copiar skills al directorio de skills de Codex (ajustar ruta según sea necesario)
cp -r skills/* ~/.codex/skills/
```

---

## 3. Primer Registro de Proyecto

Una vez configurados los servidores MCP e instalados los skills, inicializa tu primer proyecto:

1. Abre tu agente de codificación en el directorio del proyecto.
2. Di: **"init cortex"** o **"inicializar segundo cerebro"**.

El skill `cortex-ai-init` hará lo siguiente:
- Preguntar si quieres asignar el proyecto a un **equipo** (opcional).
- Crear una carpeta raíz `CORTEX-AI/` en Google Drive (si no existe).
- Crear una subcarpeta del proyecto (`CORTEX-AI/{slug-del-proyecto}/` o `CORTEX-AI/{slug-equipo}/{slug-del-proyecto}/`).
- Generar y subir un `README.md` con los metadatos del proyecto.
- Subir toda la documentación del proyecto (`.md`, `.pdf`, `.drawio`, `.docx`, `.xlsx`, imágenes) a Drive.
- Crear un notebook de Google NotebookLM indexado con esos documentos.
- Persistir la referencia cruzada (ID de proyecto ↔ ID de carpeta Drive ↔ ID de Notebook).
- Opcionalmente sincronizar el contexto Git (commits, PRs, issues) si el proyecto es un repositorio Git.
- Opcionalmente instalar hooks de auto-sync para sincronización automática de documentación.

---

## 4. Flujo de Trabajo Diario

```
init cortex         → Una vez por proyecto (con equipo opcional, sync Git, auto-sync)
push cortex         → Después de escribir/cambiar docs, specs, decisiones
ask cortex          → Preguntar sobre decisiones, specs, historial del proyecto
status cortex       → Revisar salud del sistema en todos los proyectos
onboard             → Retomar trabajo después de inactividad (incluye resumen de actividad Git)
reindex             → Reconstruir un notebook corrupto (rara vez necesario)
cross search        → Encontrar algo en todos los proyectos (con paginación y filtro por equipo)
git sync            → Sincronizar metadata Git (commits, PRs, issues) a Drive/NotebookLM
git context         → Consultar actividad Git de un proyecto
team                → Crear/listar namespaces de equipo
team status         → Reporte de salud para un equipo o comparativa entre equipos
autosync setup      → Instalar hooks de Git para auto-sync
check autosync      → Procesar marcadores de sync pendiente
cleanup             → Archivar proyectos inactivos, limpiar fuentes obsoletas
```

---

## 5. Equipos (Opcional)

Los equipos permiten organizar proyectos en namespaces. Los proyectos viven bajo `CORTEX-AI/{slug-equipo}/{slug-proyecto}/` en lugar de `CORTEX-AI/{slug-proyecto}/`.

### Crear un Equipo

```
Di: "create team backend" o "crear equipo frontend"
```

### Usar un Equipo Durante Init

```
Di: "init cortex --team backend" o "init cortex con equipo frontend"
```

### Listar Todos los Equipos

```
Di: "list teams" o "listar equipos"
```

### Status Filtrado por Equipo

```
Di: "team status backend" o "status equipo frontend"
```

---

## 6. Auto-Sync (Opcional)

El auto-sync instala hooks de Git que encolan cambios de documentación para sincronización automática.

### Habilitar Durante Init

Al ejecutar `cortex-ai-init` en un repositorio Git, se preguntará: "¿Habilitar sincronización automática de documentación en commit/push?"

### Habilitar Manualmente

```
Di: "setup autosync" o "configurar sync automatico"
```

### Cómo Funciona

1. **Hook post-commit** — Después de cada commit, si cambiaron archivos de documentación (`.md`, `.pdf`, etc.), se encolan en `.cortex-ai/pending-sync`.
2. **Hook post-push** — Después de cada push, se encola un sync completo.
3. **Al inicio de sesión** — Di "check autosync" o el agente verifica automáticamente. Los syncs pendientes se procesan vía `cortex-ai-push`.

### Deshabilitar Auto-Sync

```bash
rm .git/hooks/post-commit .git/hooks/post-push
```

---

## 7. Solución de Problemas

### "notebooklm-mcp: command not found"

```bash
# Asegurar que el directorio bin de uv esté en PATH
export PATH="$HOME/.local/bin:$PATH"

# Reinstalar
uv tool install notebooklm-mcp-cli
```

### "google-drive MCP devuelve errores de autenticación"

El servidor MCP maneja OAuth de forma interactiva. Si falla:
1. Asegúrate de que haya un navegador disponible para el flujo OAuth.
2. Verifica que `npx` funcione: `npx --version`.

### "GitHub MCP no funciona"

1. Asegúrate de que `GITHUB_TOKEN` esté exportado: `echo $GITHUB_TOKEN`
2. Verifica que el token tenga scope `repo` en https://github.com/settings/tokens
3. Verifica que el servidor MCP inicie: `npx -y @modelcontextprotocol/server-github`

### "NotebookLM dice que no hay fuentes"

Ejecuta `push cortex` para sincronizar los docs locales a Drive y NotebookLM. Si los docs ya están en Drive pero no indexados, ejecuta `reindex`.

### "Los skills no se activan"

- Verifica que los skills estén en el directorio correcto para tu agente.
- Revisa que el agente soporte carga de skills desde ese directorio.
- Para OpenCode, el plugin `skill-registry` indexa automáticamente los skills al iniciar.

### "El auto-sync no se activa"

1. Verifica que los hooks estén instalados: `ls -la .git/hooks/post-commit .git/hooks/post-push`
2. Verifica que los hooks sean ejecutables: `chmod +x .git/hooks/post-commit .git/hooks/post-push`
3. Revisa si hay sync pendiente: `cat .cortex-ai/pending-sync`

---

## 8. Snippets de Configuración MCP por Agente

Los archivos de configuración listos para usar están en `configs/`:

| Archivo | Agente | Combinar En |
|------|-------|------------|
| `configs/opencode.json` | OpenCode | `~/.config/opencode/opencode.json` → sección `mcp` |
| `configs/claude-code.json` | Claude Code | `~/.claude/settings.json` → sección `mcpServers` |
| `configs/gemini.json` | Gemini CLI | `~/.gemini/settings.json` → sección `mcpServers` |
| `configs/codex.json` | Codex CLI | `~/.codex/config.json` → sección `mcp` |

---

## 9. Referencia de Ubicaciones de Archivos

| Artefacto | Ruta |
|----------|------|
| Config de OpenCode | `~/.config/opencode/opencode.json` |
| Skills de OpenCode | `~/.config/opencode/skills/` |
| Config de Claude Code | `~/.claude/settings.json` |
| Skills de Claude Code | `~/.claude/skills/` |
| Config de Gemini CLI | `~/.gemini/settings.json` |
| Skills de Gemini CLI | `~/.gemini/skills/` |
| Config de Codex CLI | `~/.codex/config.json` |
| Skills de Codex CLI | `~/.codex/skills/` |
| Binario notebooklm-mcp | `~/.local/bin/notebooklm-mcp` (vía `uv`) |
| Origen notebooklm-mcp | `uv tool install notebooklm-mcp-cli` |
| google-drive-mcp | `npx @piotr-agier/google-drive-mcp` (bajo demanda) |
| github-mcp | `npx @modelcontextprotocol/server-github` (bajo demanda) |
| engram | `/home/linuxbrew/.linuxbrew/bin/engram` (vía brew) |
| Variable GITHUB_TOKEN | `export GITHUB_TOKEN=ghp_...` |
| Marcadores auto-sync | `.cortex-ai/pending-sync` (por proyecto) |
| Última ejecución auto-sync | `.cortex-ai/last-sync` (por proyecto) |
