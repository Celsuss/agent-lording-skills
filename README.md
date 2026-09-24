# Agent lording skills

Custom [Claude Code](https://docs.claude.com/en/docs/claude-code) skills.

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

## Repository layout

```
.
├── .claude/skills/      # one directory per skill; each has a SKILL.md
│   └── _template/       # scaffold copied by `just new <name>`
├── .github/workflows/   # CI: runs `just lint` on push/PR
├── scripts/             # lint_skills.py (frontmatter validator)
├── justfile             # install / uninstall / list / status / lint / new
└── README.md
```
