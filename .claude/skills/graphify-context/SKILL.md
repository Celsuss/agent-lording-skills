---
name: graphify-context
description: "Codebase navigation policy for repos containing a graphify-out/ knowledge graph. TRIGGER when: graphify-out/GRAPH_REPORT.md exists and the user asks about architecture, dependencies, structure, or where a symbol is defined. SKIP when: GRAPH_REPORT.md is absent; about to edit a specific file (read it directly); inspecting an AST-invisible detail (a specific formula or local variable). Forbids cat/grep/find/ls/raw .py reads for general architecture questions; requires GRAPH_REPORT.md and the `graphify` CLI."
---

## When this applies

Applies when `graphify-out/GRAPH_REPORT.md` exists and the question is about architecture, dependencies, structure, or where a symbol is defined. Does not apply when the report is absent, when about to edit a specific file (read it directly), or for AST-invisible details like a specific formula or local variable.

## Rules

- Do not use `cat`, `grep`, `find`, `ls`, or read raw `.py` files to understand the general architecture, dependencies, or structure of the repository.
- Rely on `graphify-out/GRAPH_REPORT.md` as the primary source for architecture and structure.
- Use the `graphify` shell CLI (the binary, not the `/graphify` slash skill) to query the knowledge graph.
- Read a raw code file only when explicitly about to edit it, or when inspecting a granular implementation detail (e.g. a specific mathematical formula or local variable) that the Graphify AST cannot represent.

## Examples

**DO:**

```bash
graphify query "where is class Foo defined and what uses it?"
```

**DON'T:**

```bash
grep -r "class Foo" src/
```

## Notes

This skill governs how to *use* an existing knowledge graph. The `/graphify` skill at `~/.claude/skills/graphify/` is a separate tool for *building* the graph in the first place.
