#!/usr/bin/env python3
"""Validate frontmatter in every skills/*/SKILL.md.

The rules are the intersection of what Claude Code, Codex, OpenCode, and
Antigravity accept, so a skill that lints clean here loads in all four.

`_`-prefixed directories (skills/_template/) are skipped, matching the install
recipes: they are scaffolds, never installed, and never seen by a harness.

Errors (exit 1):
  - missing SKILL.md, or missing / malformed frontmatter block
  - missing `name` or `description`
  - `name` does not match the directory basename
  - `name` is not lowercase [a-z0-9-]
  - `description` is empty or longer than 1024 chars (Claude Code's limit is
    the strictest known, so it governs)

Warnings (exit 0):
  - `description` lacks any of: "Use when", "Triggered on", "TRIGGER when"
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

DESCRIPTION_MAX = 1024
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
TRIGGER_PHRASES = ("use when", "triggered on", "trigger when")


def parse_frontmatter(text: str) -> tuple[dict[str, str] | None, str | None]:
    """Return (fields, error). On success, error is None."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "missing opening '---' on line 1"

    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return None, "missing closing '---'"

    fields: dict[str, str] = {}
    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if ":" not in raw:
            return None, f"malformed frontmatter line: {raw!r}"
        key, _, value = raw.partition(":")
        fields[key.strip()] = value.strip()
    return fields, None


def lint_skill(skill_dir: Path) -> tuple[list[str], list[str]]:
    """Return (errors, warnings) for a single skill directory."""
    errors: list[str] = []
    warnings: list[str] = []
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        return [f"missing SKILL.md in {skill_dir}"], []

    fields, err = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    if err is not None:
        return [err], []
    assert fields is not None

    name = fields.get("name")
    if not name:
        errors.append("missing 'name' in frontmatter")
    else:
        if name != skill_dir.name:
            errors.append(
                f"name '{name}' does not match directory '{skill_dir.name}'"
            )
        if not NAME_RE.match(name):
            errors.append(
                f"name '{name}' is not lowercase kebab-case [a-z0-9-]; "
                "not every harness accepts other characters"
            )

    desc = fields.get("description")
    if desc is None:
        errors.append("missing 'description' in frontmatter")
    elif not desc:
        errors.append("'description' is empty")
    else:
        if len(desc) > DESCRIPTION_MAX:
            errors.append(
                f"'description' is {len(desc)} chars (max {DESCRIPTION_MAX})"
            )
        lowered = desc.lower()
        if not any(phrase in lowered for phrase in TRIGGER_PHRASES):
            warnings.append(
                "'description' has no trigger phrase "
                "('Use when' / 'Triggered on' / 'TRIGGER when')"
            )

    return errors, warnings


def main(argv: list[str]) -> int:
    repo = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    skills_root = repo / "skills"
    if not skills_root.is_dir():
        print(f"error: {skills_root} is not a directory", file=sys.stderr)
        return 2

    # `_`-prefixed directories are scaffolds (skills/_template/). Every
    # install recipe skips them, so no harness ever sees them and the rules
    # below -- which describe what a harness accepts -- do not apply.
    skill_dirs = sorted(
        p
        for p in skills_root.iterdir()
        if p.is_dir() and not p.name.startswith("_")
    )
    if not skill_dirs:
        print(f"error: no skills found under {skills_root}", file=sys.stderr)
        return 2

    total_errors = 0
    for skill in skill_dirs:
        errors, warnings = lint_skill(skill)
        if errors:
            total_errors += len(errors)
            for msg in errors:
                print(f"error  {skill.name}: {msg}")
        else:
            print(f"ok     {skill.name}")
        for msg in warnings:
            print(f"warn   {skill.name}: {msg}")

    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
