# agent-lording-skills

A distribution source for agent skills, shared across four CLI harnesses:
Claude Code, Codex, OpenCode, and Antigravity. The repo holds the canonical
copies; `just install` symlinks them into each harness's directory.

## Layout

```
skills/<name>/SKILL.md   canonical skill sources; _template/ is the scaffold
commands/<name>.md       slash commands (Claude Code, Codex, OpenCode)
scripts/link.sh          symlink fan-out: install/uninstall/list/status
scripts/lint_skills.py   frontmatter validator
justfile                 every workflow below
```

There is deliberately no `.claude/` or `.agents/` directory. Both are
auto-loaded from a working directory by the harnesses that own them, which
would make every session started *in this repo* load the whole payload. This
repo distributes skills; it is not governed by them.

## Workflow

```sh
just new <name>   # scaffold from skills/_template/
just lint         # validate frontmatter — run before every commit
just install      # symlink skills and commands into every harness
just status       # exit non-zero if anything is missing or hijacked
just doctor       # which harnesses and target directories exist here
just uninstall    # remove only the symlinks this repo created
```

Symlinks point back into the repo, so editing a `SKILL.md` here changes the
installed skill immediately. No re-install needed, and never copy instead.

## Rules

- **Keep `SKILL.md` content harness-neutral.** All four harnesses load the same
  format — YAML frontmatter with `name` and `description`, markdown body. Do
  not reference a specific harness's tool names, config files, or directory
  layout in a skill body unless the skill is *about* that harness.
- **`name` must equal the directory name** and be lowercase kebab-case. The
  linter enforces both; the charset rule is the intersection of what the four
  harnesses accept.
- **Give every `description` a `TRIGGER when:` / `SKIP when:` clause.** Every
  harness dispatches on the description, so this is what decides whether a
  skill fires. Keep it under 1024 characters — Claude Code's cap is the
  strictest known, so it governs.
- **Underscore-prefixed directories are scaffolds** and are never installed.
- **Adding a harness is one entry in `skill_targets`** in the justfile, not a
  new recipe and not a per-harness copy of anything.
- Plans live in `l-stack/changes/<feature>/` — see the `plan-feature` skill.
