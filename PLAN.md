# Improvements for `agent-lording-skills`

## Context

This repo packages four custom Claude Code skills (`python`, `terraform`,
`graphify-context`, `repomix-context`) and ships a justfile-based symlink
installer into `~/.claude/skills/`. The primitives work, but the repo is
still bare-bones: no validation, no scaffold for new skills, inconsistent
structure across the existing four, and the README leaves Claude Code
beginners without the "what is a skill" context. This plan suggests
improvements grouped by impact, so they can be picked off independently.

The goal is a repo where (a) adding a new skill is one command, (b) bad
skills can't get committed, and (c) the existing skills follow a
predictable shape that's easy to scan and extend.

---

## Tier 1 — Highest leverage (DONE)

### 1.1 Add a `just lint` / validation recipe

**Why:** Skills are parsed by Claude Code from YAML frontmatter. A typo
in `name:` or a missing `description:` silently breaks the skill at load
time. Today nothing catches that.

**What:**
- New `justfile` recipe `lint` (or `validate`) that, for each
  `.claude/skills/*/SKILL.md`:
  - Parses YAML frontmatter (e.g. via `yq` or a small `python -c`).
  - Verifies required keys: `name`, `description`.
  - Asserts `name` matches the directory name.
  - Asserts `description` is non-empty and ≤ ~1024 chars (Claude Code's
    practical limit for fast description-based routing).
  - Warns if `description` lacks a trigger phrase ("Use when…",
    "Triggered on…", "TRIGGER when:").
- Wire it into `default` (or add `just check` that runs `lint` + `status`).

**Files:** `justfile`.

### 1.2 GitHub Actions CI

**Why:** Validation only matters if it runs on every change. A 20-line
workflow blocks malformed frontmatter from landing on `main`.

**What:**
- `.github/workflows/ci.yml` that on push/PR:
  - Installs `just` (e.g. `extractions/setup-just@v2`).
  - Runs `just lint`.
  - Optionally runs a markdown linter (e.g. `markdownlint-cli2`) over
    `.claude/skills/**/*.md` and `README.md`.

**Files:** `.github/workflows/ci.yml` (new).

### 1.3 Skill scaffolding: `just new <name>`

**Why:** Today, adding a skill means copy-pasting an existing one and
hoping you don't forget the frontmatter shape. A scaffold encodes the
"good shape" once.

**What:**
- New justfile recipe `new NAME` that:
  - Creates `.claude/skills/<NAME>/SKILL.md` from a template.
  - Refuses if the directory already exists.
- A canonical template at `.claude/skills/_template/SKILL.md` (gitkeep
  the directory; `_`-prefix so the installer can ignore it — see 1.4).
- Template should include placeholder frontmatter, a "When this
  triggers / does NOT trigger" block, and an empty "Examples" section.

**Files:** `justfile`, `.claude/skills/_template/SKILL.md` (new).

### 1.4 Installer ignores `_`-prefixed dirs

**Why:** Once we add `_template/`, we don't want it symlinked into
`~/.claude/skills/_template/` and showing up as a real skill.

**What:** In each loop in the justfile (`install`, `uninstall`, `list`,
`status`), skip directories whose basename starts with `_`.

**Files:** `justfile`.

---

## Tier 2 — Skill content quality

### 2.1 Standardize skill structure (DONE)

**Why:** The four skills today use different heading shapes
(`## Python Development Rules`, `## Terraform rules`,
`## Repository Context & Navigation`, `# Codebase Navigation Policy`),
some have horizontal-rule footnotes, some don't. A consistent shape
makes them faster to read and easier to diff.

**Proposed canonical sections (also become the template):**
1. Frontmatter (`name`, `description`).
2. `## When this applies` — one paragraph, mirrors the description's
   trigger conditions.
3. `## Rules` — bulleted, imperative voice.
4. `## Examples` — DO / DON'T pairs (see 2.2).
5. `## Notes` — only if needed (e.g. graphify-context's "this is the
   *use* skill, not the *build* skill" footnote).

### 2.2 Add `Examples` (DO / DON'T) to every skill (DONE)

**Why:** Anthropic's own skill guidance recommends concrete examples.
None of the four skills currently have any. Without examples, the model
applies the rule by analogy to its training data, which loses the
project-specific nuance the skill is supposed to encode.

**Per skill, add at least one DO and one DON'T:**
- `python`: DO show a `pyproject.toml` dependency add via `uv add`;
  DON'T show `pip install foo`.
- `terraform`: DO show an `aws_iam_policy_document` data source for an
  IAM policy; DON'T show inline JSON via `jsonencode()` or `file()`.
- `graphify-context`: DO show a `graphify query …` invocation; DON'T
  show `grep -r 'class Foo' src/`.
- `repomix-context`: DO show consulting `repomix-output.xml` first;
  DON'T show reading `.terraform/modules/.../main.tf` directly.

### 2.3 Fix orphaned content in `terraform` skill (DONE)

**Why:** `.claude/skills/terraform/SKILL.md:12` says
"Also never use `kubectl` to modify anything in the Kubernetes cluster"
— that's not Terraform-scoped and won't fire when the user is editing
k8s manifests (the skill is gated on `.tf` edits).

**What:** Either move it to a new `kubernetes` skill (gated on
`.yaml`/`.yml` k8s manifests, or `kubectl` invocations) or drop it from
this skill. Recommend: extract to a new `kubernetes` skill.

### 2.4 Tighten skill descriptions for routing (DONE)

**Why:** Claude Code routes to skills based on the `description` field.
The built-in `claude-api` skill in this environment uses a very explicit
`TRIGGER when: …` / `SKIP: …` shape — that pattern is more reliable
than soft "Use when…" prose.

**What:** Refactor all four `description:` fields to include explicit
TRIGGER and SKIP clauses. Example for `python`:

> TRIGGER when: editing .py files, pyproject.toml, or asking about
> dependency/lint/test setup in a Python project.
> SKIP when: editing notebooks-only changes that don't touch deps, or
> non-Python repos.

### 2.5 Consider a `python` skill nuance (DONE)

`python` says "never global pip install". In a CI/Dockerfile context
that's exactly the right thing. Add a note clarifying this applies to
local dev — or accept the rule as written and document the exception
inline.

---

## Tier 3 — Repository hygiene

### 3.1 Add `.gitignore` (DONE)

Currently missing. At minimum: `.DS_Store`, `*.swp`, `.idea/`,
`.vscode/` (unless you ship workspace settings), Python/Node detritus
that might creep in (`__pycache__/`, `node_modules/`).

### 3.2 Add `.editorconfig` (DONE)

Two-space indent for markdown, LF line endings, final newline. Keeps
contributor diffs clean.

### 3.3 Add `CONTRIBUTING.md` (DONE)

Short. Points contributors at:
- `just new <name>` to scaffold.
- The canonical SKILL.md structure (Tier 2.1).
- The lint/CI gate they need to pass.
- How to test locally (`just install`, then trigger the skill in a
  scratch repo).

### 3.4 Expand `README.md` (DONE)

Currently 24 lines. Add:
- A "What is a Claude Code skill?" paragraph with a link to
  https://docs.claude.com/en/docs/claude-code (already present) and
  specifically the skills doc.
- Per-skill subsections explaining triggers + a one-line example of
  what the skill changes about Claude's behavior.
- An "Adding a new skill" section pointing at `just new`.
- A short "Repository layout" tree (.claude/skills/, justfile, etc.).

---

## Tier 4 — Optional / further out

### 4.1 Per-project install

A `just install-project <path>` recipe that symlinks skills into
`<path>/.claude/skills/` instead of `~/.claude/skills/`, for users who
want a skill on a single repo only.

### 4.2 Skill versioning

Add a `version:` field to frontmatter and a top-level `CHANGELOG.md`.
Only worth it once skills start being depended on by other tooling.

### 4.3 New skills suggested by the existing set

The memory index references `AGENTS_DBT.md` from an earlier session;
that didn't get converted to a skill. Candidates:
- `dbt` — dbt project conventions (similar shape to `python`).
- `kubernetes` — landing spot for the kubectl rule (see 2.3).
- `git-commit` — commit message conventions (only worth doing if the
  rules are non-obvious).

These should each only be added when there's a real, repeated rule to
encode — not speculatively.

---

## Recommended execution order

1. Tier 1 (1.1 → 1.2 → 1.3 → 1.4) — gives you the safety net and
   scaffolding to do everything else cleanly.
2. Tier 2.1 + 2.2 + 2.3 — applies the new shape to existing skills now
   that the template (1.3) defines what "the new shape" is.
3. Tier 2.4 — small description tightening, can ride alongside 2.1/2.2.
4. Tier 3 — repo hygiene; do alongside or after Tier 2.
5. Tier 4 — only as concrete needs surface.

## Verification

For each tier, before declaring done:

- **Tier 1.1/1.2:** `just lint` exits 0 on `main`; introduce a
  deliberately broken frontmatter on a branch and confirm CI fails.
- **Tier 1.3/1.4:** `just new demo` creates a working skill,
  `just install` symlinks it, `_template/` is *not* symlinked into
  `~/.claude/skills/`.
- **Tier 2:** Open each updated `SKILL.md` and confirm the four
  canonical sections are present; manually trigger one skill (e.g.
  edit a `.py` file in a scratch dir) and confirm Claude Code applies
  the rule.
- **Tier 3:** `git status` is clean after editor activity (gitignore);
  `just lint` still passes.

## Critical files

- `justfile` — recipes to extend (lint, new, ignore `_`-prefix).
- `.claude/skills/*/SKILL.md` — content updates (Tier 2).
- `README.md` — expand.
- `.github/workflows/ci.yml` — new.
- `.claude/skills/_template/SKILL.md` — new.
- `CONTRIBUTING.md` — new.
- `.gitignore` — new.
- `.editorconfig` — new.
