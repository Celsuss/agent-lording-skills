# Contributing

This repo packages [Claude Code](https://docs.claude.com/en/docs/claude-code)
skills. See the [README](./README.md) for a primer on what a skill is
and how Claude Code routes to one.

## Adding a new skill

Scaffold from the canonical template:

```sh
just new my-skill
```

This copies `.claude/skills/_template/SKILL.md` to
`.claude/skills/my-skill/SKILL.md` and rewrites the `name:`
frontmatter. Open the file and:

1. Fill in `description`. It must include a `TRIGGER when: …` clause
   (and usually a `SKIP when: …` clause) — Claude Code matches
   against this field when deciding whether to load the skill.
2. Flesh out the four canonical sections the template provides:
   `When this applies`, `Rules`, `Examples` (at least one DO / DON'T
   pair), and an optional `Notes` section.

## Validating locally

```sh
just lint      # validate every SKILL.md frontmatter
just install   # symlink skills into ~/.claude/skills/
just status    # exit non-zero if any symlink is missing or hijacked
just list      # show install state
```

Skills are installed as symlinks, so edits to `SKILL.md` files in
this repo are picked up immediately by Claude Code — no re-install
needed.

## Testing end-to-end

In a scratch repo, perform an action that should trigger your skill
(e.g. open a `.py` file for `python`, run `kubectl` for
`kubernetes`) and confirm Claude Code applies the rule. If the skill
doesn't fire, the most common cause is a `description` field that
doesn't make the trigger explicit enough — tighten the
`TRIGGER when: …` clause.

## CI gate

`.github/workflows/ci.yml` runs `just lint` on every push and pull
request. Frontmatter errors block merges, so always run `just lint`
locally before pushing.

## PR norms

Keep PRs focused — one skill, or one repo-hygiene change. Follow the
commit-message style already in `git log`.
