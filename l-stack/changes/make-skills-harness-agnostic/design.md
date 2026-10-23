# Design

Make this repo a harness-agnostic source of agent skills, installable into
Claude Code, Codex, OpenCode, and Antigravity (CLI versions of each).

## Findings that drive the design

Gathered on 2026-10-23 from the installed binaries (`claude` 2.1.306, `codex`
0.164.0, `opencode`) and the vendors' docs, then **confirmed empirically after
install** (Task 5). These are the facts the plan rests on; re-check them if a
harness upgrades.

Verification commands, and what each showed once `just install` had run:

| Harness | Command | Result |
| --- | --- | --- |
| Claude Code | in-session skills listing | all 7 skills surfaced from `~/.claude/skills/` |
| Codex | `codex debug prompt-input` | all 7 in the model-visible prompt, rooted at `~/.agents/skills` |
| OpenCode | `opencode debug skill` | all 7, resolved across both `~/.agents/skills/` and `~/.claude/skills/` |
| Antigravity | — | not installed on this machine; still unverified |

| Harness | Global skills dir | Project skills dir | Commands / prompts | Instruction file |
| --- | --- | --- | --- | --- |
| Claude Code | `~/.claude/skills/<name>/SKILL.md` | `.claude/skills/` | `~/.claude/commands/<name>.md` | `CLAUDE.md` |
| Codex | `~/.agents/skills/<name>/SKILL.md` | `.agents/skills/` | `$CODEX_HOME/prompts/<name>.md` | `~/.codex/AGENTS.md`, `AGENTS.md` |
| OpenCode | `~/.config/opencode/skill(s)/<name>/SKILL.md` — **and auto-loads `~/.claude/skills/` and `~/.agents/skills/`** | `.opencode/skill(s)/` | `~/.config/opencode/command(s)/<name>.md` | `AGENTS.md` |
| Antigravity | `~/.agents/skills/` (per codelab example) — see Open Questions | `.agents/skills/` | skills auto-surface as `/<name>` | `AGENTS.md`, `GEMINI.md`, `.agents/rules/*.md` |

Two consequences shape everything below:

1. **The SKILL.md format is already portable.** All four harnesses load a
   directory containing `SKILL.md` with YAML frontmatter carrying `name` and
   `description`, and treat the body as markdown instructions. There is nothing
   to translate. The portability problem is *where the directory lives*, not
   what is in it.
2. **Two symlink targets cover all four CLIs.** `~/.agents/skills/` is read by
   Codex, OpenCode, and (pending verification) Antigravity. `~/.claude/skills/`
   is read by Claude Code and also auto-loaded by OpenCode. Nothing else needs
   installing.

## Goals / Non-Goals

**Goals:**

- A canonical, unbranded location for skill sources in this repo, so a clone
  does not read as a Claude Code artifact.
- `just install` makes every skill visible to all four CLIs, with the existing
  live-edit property (edit `SKILL.md` here, the installed skill changes).
- `just status` / `just list` report per target, so a partially-installed state
  is visible rather than silent.
- The linter enforces the *intersection* of what all four harnesses accept, so
  a skill that lints clean here loads everywhere.
- This repo carries an `AGENTS.md`, so an agent working *on* the repo gets its
  conventions regardless of which CLI is driving.

**Non-Goals:**

- Changing the content of any existing `SKILL.md`. If this change edits a skill
  body beyond a path reference, something has gone wrong.
- Per-harness skill variants or a build/codegen step. The format is identical;
  generating four copies of an identical file is pure drift risk.
- Project-scoped installation (`.agents/skills/` inside some *other* repo).
  Global install is what is used today; per-project vendoring can come later
  and reopens none of the decisions here.
- Supporting harnesses beyond the four named. Cursor, Gemini CLI, and Amp all
  have skill directories, but adding them is a one-line target addition once
  the fan-out exists — not a design question.

## Decisions

### Canonical sources move to `skills/` at the repo root

`.claude/skills/` names one vendor in a repo whose whole point is that it
serves four. The content is already neutral; only the path lies. `skills/` and
`commands/` at the root say what they hold.

Rejected: **keep `.claude/skills/` and treat it as "just a name."** It is not
just a name — Claude Code *auto-loads* `.claude/skills/` from the working
directory, so every session started in this repo silently loads all seven skills
as project skills. That is noise while editing them, and it makes the repo's
behaviour differ by harness for no reason.

Rejected: **make `.agents/skills/` canonical**, which Codex and Antigravity
read directly from a repo root. Same defect as above, now for three harnesses
instead of one: working in this repo would auto-load every skill in it. This
repo is a *distribution source*, not a project whose agents should be governed
by its payload. The distinction is worth a symlink.

Rejected: `src/skills/`. A `src/` prefix implies a compile step that does not
exist.

### Install by symlink fan-out to a target list, not a copy or a generator

Keep the current symlink mechanism and change only its arity: loop the existing
install/uninstall/list/status logic over a list of target directories instead of
the single hardcoded `~/.claude/skills`.

Rejected: **copying skills into each harness directory.** It breaks live
editing, which is the property that makes this repo pleasant to iterate in, and
it introduces a stale-copy state that `status` would have to detect by content
hash rather than by `readlink`.

Rejected: **a generator that emits per-harness output from a neutral IR.** This
is the structurally tempting answer and it is wrong here: the four harnesses
consume byte-identical `SKILL.md` files. A generator would transform nothing,
and every skill would gain a build step to produce a copy of itself.

### Two targets — `~/.claude/skills` and `~/.agents/skills` — cover all four

Claude Code reads only `~/.claude/skills`. Codex and Antigravity read
`~/.agents/skills`. OpenCode auto-loads both. So two symlinks per skill reach
every CLI.

Rejected: **one target, with `~/.claude/skills` symlinked to `~/.agents/skills`.**
Collapses to a single install path, but Claude Code writes into
`~/.claude/skills` itself (plugin-converted skills, synced skills), so aliasing
the whole directory means harness-managed files land in a tree this repo claims
to own. Two targets, each holding per-skill symlinks, leaves both directories
shared.

Rejected: **adding `~/.config/opencode/skill/` as a third target.** Redundant —
OpenCode already auto-loads both targets — and a redundant symlink is one more
thing for `status` to report as broken.

Rejected: **registering the repo via OpenCode's `skills.paths` config key**,
which would need no symlinks at all for that harness. It requires this repo's
installer to edit a user config file it does not own (`opencode.jsonc`, which
here is itself a symlink into a Dotfiles repo). Mutating another repo's tracked
file as a side effect of `just install` is a worse trade than a symlink.

### Targets are a justfile list, not a harness manifest file

`targets := "~/.claude/skills ~/.agents/skills"` as a justfile variable,
overridable per invocation (`just install targets="..."`).

Rejected: **a `harnesses.toml` describing each harness's skills dir, commands
dir, and instruction filename.** Correct shape for a dozen harnesses; overbuilt
for two directories. It would add a TOML parse step to every recipe to express
what one space-separated string expresses now. Revisit if per-harness filtering
or the commands layer (below) grows beyond a handful of entries.

### Commands install per harness, with Antigravity getting nothing

`commands/<name>.md` is the source. Install to `~/.claude/commands/`,
`~/.codex/prompts/`, and `~/.config/opencode/command/`. Antigravity derives
slash commands from skills automatically and has no separate command directory,
so it is skipped.

This is the one layer where the harnesses genuinely differ: frontmatter keys
like `allowed-tools` and `disable-model-invocation` are Claude Code-specific.
The decision is to **accept superset frontmatter** — write the keys the
richest harness supports and let the others ignore what they do not know —
rather than reduce every command to the lowest common denominator.

Rejected: **per-harness command source files.** `commands/` is empty — the one
stub it held (`l-init`) was deleted during implementation as unstarted work —
so this would be three copies of nothing.
Reassess when there are commands worth diverging.

Rejected: **omitting Claude-specific keys for portability.** `allowed-tools` is
a real permissions narrowing on the harness that honours it; dropping it to
keep three files textually identical trades a safety property for tidiness.

Risk accepted: an unknown-key-strict parser in Codex or OpenCode would reject
these files. Task 6 verifies this before the layer is relied on.

### The linter enforces the cross-harness intersection

Generalize `scripts/lint_skills.py` off its hardcoded `.claude/skills` path and
tighten the rules to what *all four* accept: `name` matching the directory and
restricted to `[a-z0-9-]`, non-empty `description` under 1024 chars (Claude
Code's limit is the strictest known, so it governs), `SKILL.md` present.

Keep the existing TRIGGER-phrase check as a warning. It encodes how Claude Code
routes to a skill, and every other harness dispatches on the description too,
so the advice generalizes even though the exact phrasing is a local convention.

Rejected: **per-harness lint profiles** (`just lint --harness=codex`). A skill
that is valid for one harness and not another is a skill this repo should not
ship; one strict profile is the point.

### `AGENTS.md` is the instruction file; `CLAUDE.md` symlinks to it

All of Codex, OpenCode, and Antigravity read `AGENTS.md`. Claude Code reads
`CLAUDE.md`. Write the content once in `AGENTS.md` and commit `CLAUDE.md` as a
symlink to it.

Rejected: **two real files.** They drift, and the drift is invisible because no
single harness reads both.

Rejected: **`CLAUDE.md` containing only `@AGENTS.md`** (Claude Code's import
syntax). Works, but it is a Claude-only mechanism re-introducing a
Claude-shaped file at the root; a symlink is understood by every tool including
`cat`.

Note: the repo has no `AGENTS.md` or `CLAUDE.md` today, so this creates both
rather than migrating anything.

### No per-skill harness filtering in v1

Every skill installs to every target.

No alternative was genuinely considered here, because no current skill is
harness-specific — all seven are about Python, Terraform, Kubernetes, Helm,
Repomix, or planning, none about a harness's own configuration. If one is ever
added (a "configure Claude settings.json" skill, say), the natural extension is
a `metadata.harnesses` list in frontmatter, which Codex's own bundled skills
show is a safe place to put non-standard keys.

## Risks / Trade-offs

- **The path evidence is partly binary archaeology.** OpenCode's and Claude
  Code's directory lists came from strings in the shipped binaries, not docs.
  They are unambiguous, but they are also a snapshot of one version each →
  Task 7 adds `just doctor`, which reports which target directories actually
  exist on this machine, so a vendor moving a path shows up as a diagnostic
  rather than as skills silently not loading.
- **Antigravity is not installed here and cannot be tested.** Its global skills
  path is contested between two sources → see Open Questions. The fan-out
  design means adding it later is one entry in `targets`.
- **`~/.agents/skills` is a shared namespace.** Generic names like `python` and
  `kubernetes` could collide with skills installed there by another source.
  Mitigated by the existing guard, which refuses to overwrite a real directory
  and reports `occupied`; the collision surfaces at install time rather than as
  a mystery at dispatch time.
- **Moving `.claude/skills/` breaks every currently installed symlink**, since
  they point at the old path → `just uninstall` must run *before* the move, or
  the old symlinks become dangling and the new `uninstall` will not recognize
  them. This ordering is why it is Task 1.
- **Description length limits are only known for Claude Code.** If another
  harness has a tighter cap, skills with long TRIGGER/SKIP descriptions (the
  `claude-api`-style ones) could be truncated silently. Not blocking: a
  truncated description degrades routing, it does not break loading.

## Open Questions

- **Antigravity's global skills directory.** Still open. The official codelab's
  own example writes `~/.agents/skills/<name>/SKILL.md`, while secondary
  write-ups give `~/.gemini/antigravity-cli/skills/`. Both may be true (the
  latter being a CLI-specific dir in addition to the shared one). Deferrable:
  Antigravity is not installed on this machine, and `~/.agents/skills` is
  already a target for Codex regardless of the answer. If Antigravity turns out
  to need the Gemini path too, that is one string added to `skill_targets` and
  no decision above changes. Resolve by installing Antigravity and running
  `/skills`.
- ~~**Whether Codex still reads `$CODEX_HOME/skills` for user skills.**~~
  **Resolved, moot.** `codex debug prompt-input` shows all 7 skills loaded from
  `~/.agents/skills`, so installing there is correct whether or not the legacy
  path still works. `$CODEX_HOME/skills` holds only `.system/` bundled skills
  here, and this repo never writes to it.
- ~~**Whether Codex prompts and OpenCode commands tolerate Claude-specific
  frontmatter keys.**~~ **Partly resolved, then moot.** Tested during
  implementation with the `l-init.md` stub symlinked into `~/.codex/prompts/`
  and `~/.config/opencode/command/`: both CLIs started clean and ran their
  debug commands with no parse error and no warning — notable for OpenCode,
  which hard-fails on invalid config. So `allowed-tools` and
  `disable-model-invocation` are *ignored, not rejected*, which was the risk
  this decision carried. Whether either harness then *surfaces* the command was
  never verified (it needs an interactive TUI), and `l-init.md` has since been
  deleted, so `commands/` is empty and the fan-out is a no-op. Re-test when
  there is a real command.
