#!/usr/bin/env bash
#
# uninstall.sh - Remove OpenCrew-managed agent files from the global OpenCode
# agent directory. Only OpenCrew files are removed; the agents directory itself
# and any unrelated user-created agents are left untouched.

set -euo pipefail

AGENTS_DIR="$HOME/.config/opencode/agents"

managed_files="crew-lead.md repo-scout.md architect.md implementer.md reviewer.md grunt.md"

echo "OpenCrew uninstaller"

if [ ! -d "$AGENTS_DIR" ]; then
    echo "No OpenCode agents directory found. Nothing to remove."
    echo "  $AGENTS_DIR"
    exit 0
fi

removed=0
not_found=0

for name in $managed_files; do
    path="$AGENTS_DIR/$name"
    if [ -f "$path" ]; then
        rm -f "$path"
        echo "Removed: $name"
        removed=$((removed + 1))
    else
        echo "Not present: $name"
        not_found=$((not_found + 1))
    fi
done

echo ""

if [ "$removed" -eq 6 ]; then
    echo "All OpenCrew agent files removed."
elif [ "$removed" -gt 0 ]; then
    echo "OpenCrew agent files removed. Some files were not present."
else
    echo "No OpenCrew agent files were present."
fi

echo "The agents directory and any unrelated agents were left untouched."
