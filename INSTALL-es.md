# CORTEX-AI — Guía de Instalación y Configuración

Esta guía cubre la instalación de CORTEX-AI para **OpenCode**, **Claude Code**, **Gemini CLI**, **Codex** y cualquier otro agente compatible con MCP.

---

## 1. Prerrequisitos

### Software Requerido

| Herramienta | Cómo Instalar | Propósito |
|------|---------------|---------|
| **Node.js** >= 18 | `brew install node` o [nodejs.org](https://nodejs.org) | Requerido por `google-drive-mcp` (se ejecuta vía `npx`) |
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

```bash
# Vía Homebrew
brew install gentle-ai/gentle-ai/engram
```

Si no se usa engram, CORTEX-AI usará los READMEs de Drive para las referencias cruzadas.

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
- Crear una carpeta raíz `CORTEX-AI/` en Google Drive (si no existe).
- Crear una subcarpeta del proyecto (`CORTEX-AI/{slug-del-proyecto}/`).
- Generar y subir un `README.md` con los metadatos del proyecto.
- Subir toda la documentación del proyecto (`.md`, `.pdf`, `.drawio`, `.docx`, `.xlsx`, imágenes) a Drive.
- Crear un notebook de Google NotebookLM indexado con esos documentos.
- Persistir la referencia cruzada (ID de proyecto ↔ ID de carpeta Drive ↔ ID de Notebook).

---

## 4. Flujo de Trabajo Diario

```
init cortex     → Una vez por proyecto
push cortex     → Después de escribir/cambiar docs, specs, decisiones
ask cortex      → Preguntar sobre decisiones, specs, historial del proyecto
status cortex   → Revisar salud del sistema
onboard         → Retomar trabajo después de inactividad
reindex         → Reconstruir un notebook corrupto (rara vez necesario)
cross search    → Encontrar algo en todos los proyectos
```

---

## 5. Solución de Problemas

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

### "NotebookLM dice que no hay fuentes"

Ejecuta `push cortex` para sincronizar los docs locales a Drive y NotebookLM. Si los docs ya están en Drive pero no indexados, ejecuta `reindex`.

### "Los skills no se activan"

- Verifica que los skills estén en el directorio correcto para tu agente.
- Revisa que el agente soporte carga de skills desde ese directorio.
- Para OpenCode, el plugin `skill-registry` indexa automáticamente los skills al iniciar.

---

## 6. Snippets de Configuración MCP por Agente

Los archivos de configuración listos para usar están en `configs/`:

| Archivo | Agente | Combinar En |
|------|-------|------------|
| `configs/opencode.json` | OpenCode | `~/.config/opencode/opencode.json` → sección `mcp` |
| `configs/claude-code.json` | Claude Code | `~/.claude/settings.json` → sección `mcpServers` |
| `configs/gemini.json` | Gemini CLI | `~/.gemini/settings.json` → sección `mcpServers` |
| `configs/codex.json` | Codex CLI | `~/.codex/config.json` → sección `mcp` |

---

## 7. Referencia de Ubicaciones de Archivos

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
| engram | `/home/linuxbrew/.linuxbrew/bin/engram` (vía brew) |
