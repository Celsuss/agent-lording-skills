# Agent lording skills

Agent skills that work across every CLI harness I use:
[Claude Code](https://docs.claude.com/en/docs/claude-code),
[Codex](https://developers.openai.com/codex),
[OpenCode](https://opencode.ai), and
[Antigravity](https://antigravity.google).

All four load the same thing — a directory containing a `SKILL.md` with
`name` and `description` frontmatter and a markdown body — so the skills
themselves need no per-harness variants. Only the install location differs.

## Installation

Requires [`just`](https://github.com/casey/just). From the repo root:

```sh
just install      # symlink every skill and command into every harness
just list         # show install state, per target
just status       # exit non-zero if anything is missing or hijacked
just doctor       # which harnesses and target directories exist here
just uninstall    # remove only the symlinks this repo created
just lint         # validate every SKILL.md frontmatter
just new <name>   # scaffold a new skill from skills/_template/
```

Symlinks point back into the repo, so editing a `SKILL.md` here updates the
installed skill immediately — no re-install needed. Directories prefixed with
`_` (e.g. `_template/`) are skipped by every install recipe.

## Where things get installed

Two skill directories reach all four CLIs, because OpenCode auto-loads both
of the others:

| Target | Read by |
| --- | --- |
| `~/.claude/skills/` | Claude Code, OpenCode |
| `~/.agents/skills/` | Codex, Antigravity, OpenCode |

Commands need one directory per harness. Antigravity has none — it derives
slash commands from skills automatically:

| Target | Read by |
| --- | --- |
| `~/.claude/commands/` | Claude Code |
| `~/.codex/prompts/` | Codex |
| `~/.config/opencode/command/` | OpenCode |

Both lists are justfile variables, so a new harness is one entry:

```sh
just install skill_targets="~/.claude/skills ~/.agents/skills ~/.cursor/skills"
```

Install never clobbers anything it did not create, and `uninstall` only
removes symlinks that resolve back into this repo — these directories are
shared with skills the harnesses install themselves.

## Adding a new skill

```sh
just new my-skill
```

Edit `skills/my-skill/SKILL.md` — fill in the `description` (include a
`TRIGGER when:` clause; every harness dispatches on the description), then
flesh out the `Rules` and `Examples` sections from the template. Run
`just lint` to verify the frontmatter, then `just install`.

`just lint` enforces the intersection of what all four harnesses accept, so a
skill that lints clean here loads everywhere: `name` matching the directory
and restricted to lowercase `[a-z0-9-]`, and a non-empty `description` under
1024 characters.

## Repository layout

```
.
├── skills/              # one directory per skill; each has a SKILL.md
│   └── _template/       # scaffold copied by `just new <name>`
├── commands/            # one .md per slash command
├── scripts/
│   ├── link.sh          # symlink fan-out: install/uninstall/list/status
│   └── lint_skills.py   # frontmatter validator
├── l-stack/changes/     # design.md + tasks.md per planned feature
├── .github/workflows/   # CI: runs `just lint` on push/PR
├── justfile             # every recipe above
├── AGENTS.md            # conventions for agents working on this repo
└── CLAUDE.md            # symlink to AGENTS.md
```
