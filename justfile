repo := justfile_directory()
link := repo / "scripts/link.sh"

skills_src   := repo / "skills"
commands_src := repo / "commands"

# Where each harness looks. Claude Code reads ~/.claude/skills; Codex and
# Antigravity read ~/.agents/skills; OpenCode auto-loads both, so two targets
# reach all four CLIs. Override per invocation:
#   just install skill_targets="~/.agents/skills"
skill_targets := "~/.claude/skills ~/.agents/skills"

# Antigravity derives its slash commands from skills and has no command
# directory, so it is absent here.
command_targets := "~/.claude/commands ~/.codex/prompts ~/.config/opencode/command"

# Show available recipes.
default:
    @just --list

# Symlink every skill and command into each harness directory.
install:
    @bash "{{link}}" install "{{repo}}" "{{skills_src}}"   dir  {{skill_targets}}
    @bash "{{link}}" install "{{repo}}" "{{commands_src}}" file {{command_targets}}

# Remove only the symlinks this repo installed.
uninstall:
    @bash "{{link}}" uninstall "{{repo}}" "{{skills_src}}"   dir  {{skill_targets}}
    @bash "{{link}}" uninstall "{{repo}}" "{{commands_src}}" file {{command_targets}}

# Show install state of every skill and command, per target.
list:
    @bash "{{link}}" list "{{repo}}" "{{skills_src}}"   dir  {{skill_targets}}
    @bash "{{link}}" list "{{repo}}" "{{commands_src}}" file {{command_targets}}

# Verify install state; exit non-zero if anything is missing or hijacked.
status:
    #!/usr/bin/env bash
    set -uo pipefail
    bad=0
    bash "{{link}}" status "{{repo}}" "{{skills_src}}"   dir  {{skill_targets}}  || bad=1
    bash "{{link}}" status "{{repo}}" "{{commands_src}}" file {{command_targets}} || bad=1
    exit $bad

# Report which harnesses and target directories exist on this machine.
# Diagnostic only: always exits 0. `just status` is the enforcing recipe.
doctor:
    #!/usr/bin/env bash
    set -uo pipefail
    echo "harnesses on PATH:"
    for cli in claude codex opencode antigravity; do
        path=$(command -v "$cli" 2>/dev/null || true)
        if [[ -n "$path" ]]; then
            printf '  found     %-12s %s\n' "$cli" "$path"
        else
            printf '  absent    %s\n' "$cli"
        fi
    done
    echo
    echo "target directories:"
    for raw in {{skill_targets}} {{command_targets}}; do
        dir="${raw/#\~/$HOME}"
        if [[ ! -d "$dir" ]]; then
            printf '  absent    %s\n' "$raw"
            continue
        fi
        # Count entries in this target that point back into this repo.
        n=0
        shopt -s nullglob
        for entry in "$dir"/*; do
            [[ -L "$entry" ]] || continue
            resolved=$(readlink -f "$entry" 2>/dev/null || true)
            [[ "$resolved" == "{{repo}}"/* ]] && n=$((n + 1))
        done
        shopt -u nullglob
        printf '  present   %-36s %d linked from this repo\n' "$raw" "$n"
    done

# Validate every SKILL.md frontmatter; exit non-zero on errors.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 "{{repo}}/scripts/lint_skills.py" "{{repo}}"

# Scaffold a new skill from skills/_template/.
new NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    template="{{skills_src}}/_template"
    target="{{skills_src}}/{{NAME}}"
    if [[ ! -d "$template" ]]; then
        echo "error: template not found at $template" >&2
        exit 1
    fi
    if [[ -e "$target" ]]; then
        echo "error: $target already exists" >&2
        exit 1
    fi
    cp -r "$template" "$target"
    sed -i 's/^name: _template$/name: {{NAME}}/' "$target/SKILL.md"
    echo "created $target/SKILL.md (edit description + body, then 'just lint')"
