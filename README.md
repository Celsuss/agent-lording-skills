# Agent lording skills

Custom [Claude Code](https://docs.claude.com/en/docs/claude-code) skills.

## What is a Claude Code skill?

A skill is a markdown file with YAML frontmatter (`name`,
`description`) that Claude Code loads from `~/.claude/skills/`. When
you give Claude Code a task, it matches the task against every
skill's `description` field and pulls in the matching skills' bodies
as additional instructions — so the `description` is effectively a
router, which is why every skill in this repo uses the explicit
`TRIGGER when: … SKIP when: …` shape.

See the [official skills
documentation](https://docs.claude.com/en/docs/claude-code/skills)
for the full spec.

## Skills

- **`terraform`** — Conventions for writing Terraform/HCL. Triggered on `.tf` files. AWS IAM patterns (`aws_iam_policy_document`, no Access Keys in code), `init → fmt → validate → plan` workflow, never `apply` without approval.
- **`kubernetes`** — Conventions for Kubernetes manifests and `kubectl`. Triggered on k8s manifests (`.yaml`/`.yml` with `apiVersion:` + `kind:`) or `kubectl` invocations. Enforces GitOps: cluster state changes go through manifests in the repo, not ad-hoc `kubectl` writes; read-only `kubectl get/describe/logs/top` allowed.
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
just lint         # validate every SKILL.md frontmatter
just new <name>   # scaffold a new skill from .claude/skills/_template/
```

Symlinks point back into the repo, so editing a `SKILL.md` here updates
the installed skill immediately — no re-install needed. Directories
prefixed with `_` (e.g. `_template/`) are skipped by all install
recipes.

## Adding a new skill

```sh
just new my-skill
```

Edit `.claude/skills/my-skill/SKILL.md` — fill in the `description`
(include a `TRIGGER when:` clause so Claude Code routes to it), then
flesh out the `Rules` and `Examples` sections from the template. Run
`just lint` to verify the frontmatter, then `just install` to symlink
it.

Frontmatter is validated on every push by `.github/workflows/ci.yml`.
See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full contributor
workflow.

## Repository layout

```
.
├── .claude/skills/      # one directory per skill; each has a SKILL.md
│   └── _template/       # scaffold copied by `just new <name>`
├── .github/workflows/   # CI: runs `just lint` on push/PR
├── scripts/             # lint_skills.py (frontmatter validator)
├── justfile             # install / uninstall / list / status / lint / new
├── CONTRIBUTING.md      # contributor workflow
├── PLAN.md              # roadmap
└── README.md
```
