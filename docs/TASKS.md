# Tasks

- [ ] 1. Lint `commands/*.md` under its own rule set, kept separate from
      the skill rules. Commands have no `name` (the filename is the command),
      take `argument-hint` / `allowed-tools` / `model` /
      `disable-model-invocation`, and must not draw the TRIGGER-phrase warning —
      that check exists because a skill's description is its dispatch
      mechanism, which does not apply to an explicitly invoked command. Share
      `parse_frontmatter` and the ok/error/warn reporting rather than copying
      them; only the rules differ. A missing or empty `commands/` is a
      no-op, not the exit-2 that `lint_skills.py` gives for skills, since
      commands are optional in most repos.
      Note: `commands/` is currently empty, so this task needs a command to
      test against — write one first, or add a throwaway `commands/probe.md`.
      Verify: `just lint` prints a status line for that command and leaves the
      existing skill output unchanged. Break its frontmatter; lint exits
      non-zero. Confirm it draws no "no trigger phrase" warning.
      `mv commands /tmp && just lint` still exits 0.
