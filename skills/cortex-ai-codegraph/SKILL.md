---
name: cortex-ai-codegraph
description: "Trigger: codegraph, explore code, find symbol, who calls, impact analysis, call graph, code structure, donde esta la funcion, que usa esto, que rompe esto. Explore codebase structure and symbols via CodeGraph MCP."
license: Apache-2.0
metadata:
  author: "gabrielcruzsoto"
  version: "1.0"
---

# cortex-ai-codegraph

## Activation Contract

Activate when the user asks about code structure, symbol locations, call relationships, impact analysis, or code-level exploration that benefits from semantic indexing (e.g., "where is X defined?", "what calls Y?", "what would break if I change Z?", "show me the authentication flow").

This skill complements `cortex-ai-ask` (which queries documentation) by providing code-level intelligence. Use `cortex-ai-codegraph` for implementation questions and `cortex-ai-ask` for design/decision questions.

Do NOT activate for documentation-only queries (specs, decisions, architecture rationale) — those belong to `cortex-ai-ask`.

## Hard Rules

- Always check for `.codegraph/` directory before activating. If absent, inform user the project is not indexed and suggest `codegraph init`.
- Prefer CodeGraph over grep/find for symbol lookup — CodeGraph resolves dynamic dispatch and call paths that text search cannot.
- If CodeGraph MCP fails, fall back to `codegraph explore "<query>"` via shell. If that also fails, fall back to grep/find as last resort.
- Always cite the source: `[CodeGraph]` for results from the MCP tool or shell, `[grep]` for fallback results.
- NEVER fabricate symbol relationships. If CodeGraph returns no results, say so explicitly.

## Decision Gates

| Situation | Action |
|-----------|--------|
| `.codegraph/` directory does not exist | Inform user: "Project not indexed. Run `codegraph init` to enable code intelligence." Do not activate skill. |
| CodeGraph MCP tool available | Use `codegraph_explore` for structured results with verbatim source and call paths |
| CodeGraph MCP fails or times out | Fall back to shell: `codegraph explore "<query>"` |
| Shell also fails | Fall back to grep/find; mark results as `[grep]` (no call-path resolution) |
| User asks about code AND documentation | Combine `cortex-ai-codegraph` for code structure with `cortex-ai-ask` for design context |
| User asks "what would break if I change X?" | Use CodeGraph reverse-impact: query callers and dependents of the symbol |
| User asks to explore a specific file | Use `codegraph_explore` with file name; CodeGraph returns line-numbered source |

## Execution Steps

1. **Verify indexing.** Check if `.codegraph/` exists in the project root. If not, inform user and suggest `codegraph init`.
2. **Resolve query type.** Classify the user's request:
   - *Symbol location*: "where is X defined?"
   - *Call graph*: "what calls X?" or "what does X call?"
   - *Impact analysis*: "what breaks if I change X?"
   - *Code exploration*: "show me the authentication flow"
   - *File reading*: "show me the contents of file X"
3. **Query CodeGraph MCP.** Call `codegraph_explore` with the user's question. The tool returns:
   - Relevant symbols' verbatim source (line-numbered)
   - Call paths between symbols (including dynamic-dispatch hops)
   - Deferred symbols (load by name if needed)
4. **Shell fallback (if MCP unavailable).** Run `codegraph explore "<query>"` via Bash. Parse the output for symbols and call paths.
5. **Synthesize.** Present results with clear structure:
   - Symbol definitions with file:line references
   - Call relationships (caller → callee)
   - Impact scope (what depends on this symbol)
6. **Cross-reference with Cortex-ai (optional).** If the user's question also touches design decisions or specs, suggest running `cortex-ai-ask` for documentation context.
7. **Flag gaps.** If CodeGraph found no results, suggest the user verify the symbol name or check if the file is indexed.

## Output Contract

```
{code-intelligence-answer}
---
📎 Sources:
  - [CodeGraph] {symbol-locations-and-call-paths}
  - [grep] {fallback-results-if-any}
{cross-reference-suggestion-if-applicable}
```

## References

- `cortex-ai-ask` — for documentation and design decision queries (complements code-level intelligence).
- `cortex-ai-init` — prerequisite for project registration in the second brain.
- CodeGraph CLI: `codegraph init` indexes the project; `codegraph serve --mcp` runs the MCP server.
