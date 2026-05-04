# Agent lording skills

Custom [Claude Code](https://docs.claude.com/en/docs/claude-code) skills.

## Skills

- **`terraform`** — Conventions for writing Terraform/HCL. Triggered on `.tf` files. AWS IAM patterns (`aws_iam_policy_document`, no Access Keys in code), `init → fmt → validate → plan` workflow, never `apply` without approval.
- **`python`** — Conventions for Python code and `pyproject.toml`. Declarative dependency management (no `requirements.txt`/`setup.py`), uv/poetry only, ruff for lint+format, full type hints with the RORO pattern, pytest in `tests/`.
- **`graphify-context`** — Navigation policy for repos containing a `graphify-out/` knowledge graph. Forbids raw `cat`/`grep`/`find`/`ls` for architecture questions; requires `GRAPH_REPORT.md` and the `graphify` CLI first. Raw reads allowed only when editing or for AST-invisible details.
- **`repomix-context`** — Navigation policy for Terraform projects packed with [Repomix](https://repomix.com). Consult `repomix-output.xml` first for architecture/dependency/cross-file questions; refresh via `npx repomix` after significant changes.

## Installation

Requires [`just`](https://github.com/casey/just). From the repo root:

```sh
just install      # symlink every skill into ~/.claude/skills/
just list         # show install state
just status       # exit non-zero if anything is missing or hijacked
just uninstall    # remove only the symlinks this repo created
```

Symlinks point back into the repo, so editing a `SKILL.md` here updates
the installed skill immediately — no re-install needed.
