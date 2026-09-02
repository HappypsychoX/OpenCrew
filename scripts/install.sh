#!/usr/bin/env bash
#
# install.sh - Install OpenCrew agents into the global OpenCode agent directory.
#
# Usage:
#   ./scripts/install.sh          # prompt before overwriting existing files
#   ./scripts/install.sh --force  # overwrite existing files without prompting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

AGENTS_DIR="$HOME/.config/opencode/agents"

FORCE=0
if [ "${1:-}" = "--force" ]; then
    FORCE=1
fi

# Verify OpenCode appears installed (warn only, do not hard-fail).
opencode_installed=0
if command -v opencode >/dev/null 2>&1; then
    opencode_installed=1
elif [ -d "$HOME/.config/opencode" ]; then
    opencode_installed=1
fi

echo "OpenCrew installer"

if [ "$opencode_installed" -eq 0 ]; then
    echo "Warning: OpenCode does not appear to be installed (no 'opencode' on PATH and no ~/.config/opencode directory found)."
    echo "Continuing anyway; the agents will be installed into:"
    echo "  $AGENTS_DIR"
fi

# Create the agents directory if it does not exist.
if [ ! -d "$AGENTS_DIR" ]; then
    mkdir -p "$AGENTS_DIR"
    echo "Created directory: $AGENTS_DIR"
fi

installed=""
skipped=""

install_file() {
    src="$1"
    dst_name="$2"
    dst="$AGENTS_DIR/$dst_name"

    if [ ! -f "$src" ]; then
        echo "Warning: source file not found, skipping: $src"
        skipped="$skipped $dst_name"
        return
    fi

    if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
        printf "  %s already exists. Replace? [y/N] " "$dst_name"
        read -r answer || true
        case "$answer" in
            y|Y|yes|YES|Yes)
                ;;
            *)
                echo "  Skipped $dst_name."
                skipped="$skipped $dst_name"
                return
                ;;
        esac
    fi

    cp "$src" "$dst"
    installed="$installed $dst_name"
}

install_file "$REPO_ROOT/crew-lead/opencode.md" "crew-lead.md"
install_file "$REPO_ROOT/agents/repo-scout.md" "repo-scout.md"
install_file "$REPO_ROOT/agents/architect.md" "architect.md"
install_file "$REPO_ROOT/agents/implementer.md" "implementer.md"
install_file "$REPO_ROOT/agents/reviewer.md" "reviewer.md"
install_file "$REPO_ROOT/agents/grunt.md" "grunt.md"

echo ""

if [ -n "$installed" ]; then
    echo "Installed:"
    for name in $installed; do
        echo "  $name"
    done
fi

if [ -n "$skipped" ]; then
    echo "Skipped:"
    for name in $skipped; do
        echo "  $name"
    done
fi

echo ""
echo "OpenCrew installed successfully."
echo ""
echo "Try:"
echo ""
echo "  @crew-lead Explain how authentication works in this repository."
