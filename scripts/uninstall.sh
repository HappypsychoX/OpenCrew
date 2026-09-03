#!/usr/bin/env bash
# uninstall.sh - Remove OpenCrew-managed agent files for a chosen runtime.
# Only OpenCrew files are removed; the agents directory itself and any
# unrelated user-created agents are left untouched.
#
# Usage:
#   ./scripts/uninstall.sh                    # prompts for runtime
#   ./scripts/uninstall.sh --runtime claude

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RUNTIME=""

while [ $# -gt 0 ]; do
    case "$1" in
        --runtime) RUNTIME="${2:-}"; shift 2 ;;
        --runtime=*) RUNTIME="${1#*=}"; shift ;;
        -h|--help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

MANAGED_FILES="crew-lead.md repo-scout.md architect.md implementer.md reviewer.md grunt.md"

expand_home() {
    case "$1" in
        "~"/*) echo "$HOME/${1#\~/}" ;;
        *) echo "$1" ;;
    esac
}

echo "OpenCrew uninstaller"
echo

if [ -z "$RUNTIME" ]; then
    echo "Which runtime should OpenCrew be removed from?"
    echo "  [1] Claude Code"
    echo "  [2] OpenCode"
    echo
    printf 'Select [1/2]: '
    read -r choice
    case "$choice" in
        1) RUNTIME="claude" ;;
        2) RUNTIME="opencode" ;;
        *) echo "Unrecognized selection. Re-run with --runtime claude or --runtime opencode." >&2; exit 1 ;;
    esac
fi

CONF="$REPO_ROOT/runtimes/$RUNTIME/runtime.conf"
[ -f "$CONF" ] || { echo "No runtime manifest found at $CONF" >&2; exit 1; }

target="$(sed -n 's/^[[:space:]]*target=//p' "$CONF" | head -n 1 | sed 's/[[:space:]]*$//')"
[ -n "$target" ] || { echo "No 'target' declared in $CONF" >&2; exit 1; }

AGENTS_DIR="$(expand_home "$target")"
echo "Target: $AGENTS_DIR"
echo

if [ ! -d "$AGENTS_DIR" ]; then
    echo "No agents directory found. Nothing to remove."
    exit 0
fi

removed=0
total=0

for name in $MANAGED_FILES; do
    total=$((total + 1))
    if [ -f "$AGENTS_DIR/$name" ]; then
        rm -f "$AGENTS_DIR/$name"
        echo "Removed: $name"
        removed=$((removed + 1))
    else
        echo "Not present: $name"
    fi
done

echo
if [ "$removed" -eq "$total" ]; then
    echo "All OpenCrew agent files removed."
elif [ "$removed" -gt 0 ]; then
    echo "OpenCrew agent files removed. Some files were not present."
else
    echo "No OpenCrew agent files were present."
fi

echo "The agents directory and any unrelated agents were left untouched."
echo
echo "Note: git-safety rules added to settings.json are left in place."
echo "Remove them by hand if you no longer want them."
