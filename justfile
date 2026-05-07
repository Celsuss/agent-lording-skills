repo := justfile_directory()
src  := repo / ".claude/skills"
dst  := env_var('HOME') / ".claude/skills"

# Show available recipes.
default:
    @just --list

# Symlink every skill in this repo into ~/.claude/skills/.
install:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{dst}}"
    shopt -s nullglob
    for d in "{{src}}"/*/; do
        name=$(basename "$d")
        [[ "$name" == _* ]] && continue
        target="{{dst}}/$name"
        if [[ -e "$target" && ! -L "$target" ]]; then
            echo "skipped  $name (real dir exists at $target)"
            continue
        fi
        ln -sfn "${d%/}" "$target"
        echo "installed $name"
    done

# Remove only the symlinks this repo installed.
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    for d in "{{src}}"/*/; do
        name=$(basename "$d")
        [[ "$name" == _* ]] && continue
        target="{{dst}}/$name"
        if [[ ! -e "$target" && ! -L "$target" ]]; then
            echo "absent    $name"
            continue
        fi
        if [[ ! -L "$target" ]]; then
            echo "skipped   $name (not a symlink)"
            continue
        fi
        resolved=$(readlink -f "$target" || true)
        if [[ "$resolved" != "{{repo}}"/* ]]; then
            echo "skipped   $name (links outside repo: $resolved)"
            continue
        fi
        rm "$target"
        echo "removed   $name"
    done

# Show install state of each skill in this repo.
list:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    for d in "{{src}}"/*/; do
        name=$(basename "$d")
        [[ "$name" == _* ]] && continue
        target="{{dst}}/$name"
        if [[ -L "$target" ]]; then
            resolved=$(readlink -f "$target" || echo "<broken>")
            if [[ ! -e "$target" ]]; then
                echo "broken    $name -> $(readlink "$target")"
            elif [[ "$resolved" == "{{repo}}"/* ]]; then
                echo "installed $name -> $resolved"
            else
                echo "external  $name -> $resolved"
            fi
        elif [[ -e "$target" ]]; then
            echo "occupied  $name (real dir at $target)"
        else
            echo "missing   $name"
        fi
    done

# Verify install state; exit non-zero if anything is wrong.
status:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    bad=0
    for d in "{{src}}"/*/; do
        name=$(basename "$d")
        [[ "$name" == _* ]] && continue
        target="{{dst}}/$name"
        if [[ -L "$target" && -e "$target" ]]; then
            resolved=$(readlink -f "$target")
            if [[ "$resolved" == "{{repo}}"/* ]]; then
                echo "ok       $name"
                continue
            fi
            echo "external $name -> $resolved"
            bad=1
        elif [[ -L "$target" ]]; then
            echo "broken   $name -> $(readlink "$target")"
            bad=1
        elif [[ -e "$target" ]]; then
            echo "occupied $name (real dir)"
            bad=1
        else
            echo "missing  $name"
            bad=1
        fi
    done
    exit $bad

# Validate every SKILL.md frontmatter; exit non-zero on errors.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 "{{repo}}/scripts/lint_skills.py" "{{repo}}"

# Scaffold a new skill from .claude/skills/_template/.
new NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    template="{{src}}/_template"
    target="{{src}}/{{NAME}}"
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
