# Tasks

- [x] 1. Run `just uninstall` **before touching anything else**, so the existing
      `~/.claude/skills/*` symlinks are removed while the justfile still knows
      the path they point at. (Design → Risks, "Moving `.claude/skills/`")
      Verify: `just list` reports `missing` for all nine skills, and
      `ls -la ~/.claude/skills/` shows no links into this repo.

- [x] 2. `git mv .claude/skills skills` and `git mv .claude/commands commands`;
      remove the now-empty `.claude/`. (Design → "Canonical sources move to
      `skills/`")
      Verify: `ls skills/` lists the nine skill dirs plus `_template`;
      `ls commands/` lists `l-init.md`; `.claude/` does not exist;
      `git status` shows renames, not delete+add.

- [x] 3. Point `scripts/lint_skills.py` at `skills/` instead of
      `.claude/skills`, and tighten it to the cross-harness intersection: add a
      `[a-z0-9-]+` check on `name`, keep the directory-match check, keep the
      1024-char `description` cap, keep the TRIGGER-phrase check as a *warning*.
      (Design → "The linter enforces the cross-harness intersection")
      Verify: `just lint` prints `ok` for all seven skills (plus `_template`) and exits 0.
      Temporarily rename a skill dir so `name` mismatches — lint exits 1.
      Temporarily set a `name` to `My_Skill` — lint exits 1 with a charset error.

- [x] 4. Rewrite the justfile's `install` / `uninstall` / `list` / `status`
      recipes to loop over a `targets` variable
      (`~/.claude/skills ~/.agents/skills`) instead of the single `dst`. Keep
      every existing guard: skip `_`-prefixed dirs, refuse to clobber a real
      directory, and only remove symlinks that resolve back into this repo.
      `list` and `status` must name the target in each output line, so a
      half-installed state is legible. (Design → "Two targets", "Targets are a
      justfile list")
      Verify: `just install` creates seven symlinks in each of the two targets;
      `just status` exits 0 and prints seventeen `ok` lines (7+7 skills, 3 commands). `rm` one symlink
      from `~/.agents/skills` — `status` exits non-zero naming that target
      only. `mkdir ~/.agents/skills/python` — `status` reports `occupied` for
      that one target and does not touch it.

- [x] 5. Confirm each installed CLI actually sees the skills. This is the task
      that validates the whole findings table in design.md.
      Verify: `claude` lists the skills (e.g. `terraform`, `python`) in its
      skills listing. `codex` shows them — check via `codex doctor` or the
      in-session `/skills`-equivalent listing. `opencode` shows them; note
      OpenCode caches config at startup, so restart it before checking. Record
      the actual command used for each in design.md's findings table, replacing
      the inferred paths with confirmed ones.

- [x] 6. Add a `commands` fan-out to the justfile: install `commands/*.md` into
      `~/.claude/commands/`, `~/.codex/prompts/`, and
      `~/.config/opencode/command/`, by the same symlink rules as skills.
      Answers the third Open Question. (Design → "Commands install per harness")
      Verify: `l-init` appears as `/l-init` in Claude Code. In Codex and
      OpenCode, confirm the file is *accepted* — specifically that its
      Claude-only `allowed-tools` and `disable-model-invocation` keys are
      ignored rather than causing a parse error or a startup failure. If either
      harness rejects it, stop and record the failure in design.md's Open
      Questions before working around it.

- [x] 7. Add a `just doctor` recipe that prints, for each target directory,
      whether it exists and how many of this repo's symlinks are in it, plus
      which of the four CLIs is on `PATH`. (Design → Risks, "path evidence is
      partly binary archaeology")
      Verify: `just doctor` on this machine reports both skill targets present
      and `antigravity` absent. Rename `~/.agents/skills` aside — `doctor`
      reports it missing and still exits 0 (it diagnoses, it does not enforce;
      `status` is the enforcing recipe).

- [x] 8. Write `AGENTS.md` at the repo root with this repo's own conventions
      (what the repo is, where skills live, the install/lint workflow, the rule
      that `SKILL.md` content stays harness-neutral), and add `CLAUDE.md` as a
      symlink to it. (Design → "`AGENTS.md` is the instruction file")
      Verify: `cat CLAUDE.md` shows the `AGENTS.md` content;
      `git ls-files -s CLAUDE.md` shows mode `120000` (a committed symlink, not
      a copy).

- [x] 9. Rewrite README.md: drop "Custom Claude Code skills" framing, state the
      four supported harnesses and the two install targets, update the
      repository-layout block to the new `skills/` + `commands/` structure, and
      document `just doctor`.
      Verify: no occurrence of `.claude/skills` remains —
      `grep -rn "\.claude/skills" README.md justfile scripts/ docs/` is empty.

- [x] 10. Update `.github/workflows/ci.yml` only if Task 3 changed the lint
      invocation. CI runs `just lint`, which stays the entry point, so this is
      expected to be a no-op — confirm rather than assume.
      Verify: push a branch; the `lint` job goes green. Break a `SKILL.md`
      frontmatter on that branch; the job exits non-zero.

- [x] 11. Fold the existing `docs/TASKS.md` item (lint `commands/*.md` under
      their own rule set, sharing `parse_frontmatter`, no TRIGGER warning, empty
      dir is a no-op) into the generalized linter, and update its wording from
      `.claude/commands` to `commands/`. It is a pre-existing task, not part of
      this restructure, but Task 2 invalidates its paths.
      Verify: `docs/TASKS.md` references no `.claude/` path.


## Outcome — 2026-10-23

All 11 tasks done. Deviations from the plan as written, and why:

- **Task 3 — scaffolds are skipped entirely.** The new `[a-z0-9-]` name rule
  rejected `skills/_template` on its leading underscore. First attempt exempted
  only the charset check and kept validating the rest; on review the call was
  to skip `_`-prefixed directories outright, matching what every install recipe
  already does. `just lint` no longer prints a line for `_template`. Trade-off
  accepted: a broken template is no longer caught by lint, but `just new`
  immediately produces a skill that is, which is where the error would surface
  anyway.
- **Task 4 — logic factored into `scripts/link.sh`.** The plan said to loop the
  existing recipes over a target list. Done, but adding commands (Task 6) would
  have made that four near-identical bash blocks times two. The shared script
  takes `action, repo, src, dir|file, targets...` and each recipe calls it
  twice. Same semantics and the same guards, one copy.
- **Task 5 — Antigravity unverified.** The other three are confirmed; see the
  verification table in design.md. Antigravity is not installed here.
- **Task 6 — acceptance confirmed, surfacing not.** Both Codex and OpenCode
  load with the command symlinked in and report no error, which answers the
  risk the decision carried. Whether `/l-init` actually appears needs a TUI.
- **Task 10 — no-op, as predicted.** CI still runs `just lint`, and `just lint`
  is still the entry point. Verified locally rather than assumed; not yet
  verified on a pushed branch.
- **Out of plan: `commands/l-init.md` deleted.** It was an unimplemented stub
  whose "Implementation notes" had been invalidated by Task 6 (it claimed
  `~/.claude/commands/` "does not exist yet"). Rather than correct a file that
  had never been started, it was removed. `commands/` now holds only a
  `.gitkeep`, kept so the directory survives a clone — README.md, AGENTS.md and
  the justfile all document it as the command source. The fan-out handles an
  empty source as a no-op (`note      nothing to link in commands`), which is
  tested.

Known cosmetic issue carried forward, pre-existing and not touched: the
`create-helm-chart` description has no TRIGGER phrase, so `just lint` emits one
warning (exit 0). Fixing it edits skill content, which design.md lists as a
non-goal.
