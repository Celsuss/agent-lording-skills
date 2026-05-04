---
name: graphify-context
description: Codebase navigation policy for repos that contain a graphify-out/ knowledge graph. Use when graphify-out/GRAPH_REPORT.md exists in the project. Forbids cat/grep/find/ls/raw .py reads for general architecture questions; require GRAPH_REPORT.md and the graphify CLI instead. Raw file reads allowed only when about to edit, or for granular details unrepresentable in the AST.
---

# Codebase Navigation Policy

You are strictly prohibited from using `cat`, `grep`, `find`, `ls`, or reading raw `.py` files to understand the general architecture, dependencies, or structure of this repository.

To understand this codebase, you MUST:

1. Rely on the `graphify-out/GRAPH_REPORT.md` file.
2. Run the `graphify` shell command (the CLI binary, not the `/graphify` slash skill) if you need to query the knowledge graph.

**Exceptions:**

You may ONLY read a raw code file if you are explicitly about to edit it, or if you need to inspect a granular implementation detail (like a specific mathematical formula or local variable) that is fundamentally impossible to represent in the Graphify AST structure.

---

Note: this skill governs how to *use* an existing knowledge graph. The `/graphify` skill at `~/.claude/skills/graphify/` is a separate tool for *building* the graph in the first place.
