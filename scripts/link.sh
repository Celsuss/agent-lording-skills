#!/usr/bin/env bash
# Symlink this repo's skills or commands into one or more harness directories.
#
# One source tree, N targets, no copies: editing a SKILL.md here changes the
# installed skill immediately. Skills and commands differ only in whether the
# linked entry is a directory or a .md file, so both go through this script.
#
# usage: link.sh <install|uninstall|list|status> <repo> <src> <dir|file> <target>...
#
# Targets may start with `~`; it is expanded here, since just does not expand
# it inside a variable.

set -euo pipefail

action=${1:?action required}
repo=${2:?repo required}
src=${3:?src required}
kind=${4:?kind required: dir or file}
shift 4
targets=("$@")

if [[ ${#targets[@]} -eq 0 ]]; then
    echo "error: no targets given" >&2
    exit 2
fi
case "$action" in
install | uninstall | list | status) ;;
*)
    echo "error: unknown action '$action'" >&2
    exit 2
    ;;
esac

# Collect what to link: directories for skills, *.md files for commands. A
# leading underscore marks a scaffold (skills/_template/) that never installs.
entries=()
shopt -s nullglob
if [[ "$kind" == dir ]]; then
    for d in "$src"/*/; do
        name=$(basename "$d")
        [[ "$name" == _* ]] && continue
        entries+=("$name")
    done
else
    for f in "$src"/*.md; do
        name=$(basename "$f")
        [[ "$name" == _* ]] && continue
        entries+=("$name")
    done
fi
shopt -u nullglob

# An empty source directory is a no-op, not an error: a repo may legitimately
# ship skills and no commands.
if [[ ${#entries[@]} -eq 0 ]]; then
    echo "note      nothing to link in ${src#"$repo"/}"
    exit 0
fi

# Report where a link points: ok (into this repo), external (a link we did not
# make), broken (dangling), occupied (a real file or directory), or missing.
classify() {
    local link=$1 resolved
    if [[ -L "$link" ]]; then
        if [[ ! -e "$link" ]]; then
            printf 'broken\t%s\n' "$(readlink "$link")"
            return
        fi
        resolved=$(readlink -f "$link")
        if [[ "$resolved" == "$repo"/* ]]; then
            printf 'ok\t%s\n' "$resolved"
        else
            printf 'external\t%s\n' "$resolved"
        fi
    elif [[ -e "$link" ]]; then
        printf 'occupied\t%s\n' "$link"
    else
        printf 'missing\t\n'
    fi
}

bad=0
for raw_target in "${targets[@]}"; do
    target_dir="${raw_target/#\~/$HOME}"
    for name in "${entries[@]}"; do
        source_path="$src/$name"
        link="$target_dir/$name"
        slot="$raw_target/$name"

        case "$action" in
        install)
            mkdir -p "$target_dir"
            # Never clobber something we did not create. ~/.claude/skills is
            # shared with skills the harness installs itself.
            if [[ -e "$link" && ! -L "$link" ]]; then
                echo "skipped   $slot (real $kind already there)"
                continue
            fi
            ln -sfn "$source_path" "$link"
            echo "installed $slot"
            ;;

        uninstall)
            if [[ ! -e "$link" && ! -L "$link" ]]; then
                echo "absent    $slot"
                continue
            fi
            if [[ ! -L "$link" ]]; then
                echo "skipped   $slot (not a symlink)"
                continue
            fi
            # Only remove links this repo owns.
            resolved=$(readlink -f "$link" || true)
            if [[ "$resolved" != "$repo"/* ]]; then
                echo "skipped   $slot (links outside repo: $resolved)"
                continue
            fi
            rm "$link"
            echo "removed   $slot"
            ;;

        list | status)
            IFS=$'\t' read -r state detail < <(classify "$link")
            if [[ "$action" == list ]]; then
                if [[ -n "$detail" ]]; then
                    printf '%-9s %s -> %s\n' "$state" "$slot" "$detail"
                else
                    printf '%-9s %s\n' "$state" "$slot"
                fi
            else
                printf '%-9s %s\n' "$state" "$slot"
                [[ "$state" == ok ]] || bad=1
            fi
            ;;
        esac
    done
done

exit $bad
