#!/usr/bin/env bash
# install.sh - Render and install OpenCrew agents for a chosen runtime.
#
# Usage:
#   ./scripts/install.sh                    # prompts for runtime
#   ./scripts/install.sh --runtime claude
#   ./scripts/install.sh --runtime opencode --force
#   ./scripts/install.sh --runtime claude --permission-scope user
#
# --permission-scope: project (default) | user | none

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RUNTIME=""
FORCE=0
# Where runtime-level permission rules are written:
#   project - <current directory>/.claude/settings.json  (default)
#   user    - the runtime's user-global settings.json
#   none    - do not write permission rules at all
PERMISSION_SCOPE="project"

while [ $# -gt 0 ]; do
    case "$1" in
        --runtime) RUNTIME="${2:-}"; shift 2 ;;
        --runtime=*) RUNTIME="${1#*=}"; shift ;;
        --permission-scope) PERMISSION_SCOPE="${2:-}"; shift 2 ;;
        --permission-scope=*) PERMISSION_SCOPE="${1#*=}"; shift ;;
        -f|--force) FORCE=1; shift ;;
        -h|--help)
            sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Agent name -> source file, in install order.
AGENT_NAMES="crew-lead repo-scout architect implementer reviewer grunt"

agent_source() {
    case "$1" in
        crew-lead) echo "crew-lead/body.md" ;;
        *) echo "agents/$1.md" ;;
    esac
}

expand_home() {
    case "$1" in
        "~"/*) echo "$HOME/${1#\~/}" ;;
        *) echo "$1" ;;
    esac
}

conf_get() {
    # conf_get <file> <key> ; prints value or empty
    sed -n "s/^[[:space:]]*$(printf '%s' "$2" | sed 's/[.[\*^$]/\\&/g')=//p" "$1" | head -n 1 | sed 's/[[:space:]]*$//'
}

echo "OpenCrew installer"
echo

# --- Runtime selection -------------------------------------------------------

if [ -z "$RUNTIME" ]; then
    echo "Which runtime should fill the crew-lead role?"
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

case "$PERMISSION_SCOPE" in
    project|user|none) ;;
    *) echo "Invalid --permission-scope '$PERMISSION_SCOPE' (expected project, user, or none)" >&2; exit 1 ;;
esac

RUNTIME_DIR="$REPO_ROOT/runtimes/$RUNTIME"
[ -d "$RUNTIME_DIR" ] || { echo "No runtime manifest found at $RUNTIME_DIR" >&2; exit 1; }

CONF="$RUNTIME_DIR/runtime.conf"
AGENTS_DIR="$(expand_home "$(conf_get "$CONF" target)")"
DISPLAY_NAME="$(conf_get "$CONF" display)"

echo "Runtime: $DISPLAY_NAME"
echo "Target:  $AGENTS_DIR"
echo

# --- Runtime detection -------------------------------------------------------

detect_cmd="$(conf_get "$CONF" detect_command)"
detect_dir="$(conf_get "$CONF" detect_dir)"
found=0
[ -n "$detect_cmd" ] && command -v "$detect_cmd" >/dev/null 2>&1 && found=1
[ "$found" -eq 0 ] && [ -n "$detect_dir" ] && [ -d "$(expand_home "$detect_dir")" ] && found=1
if [ "$found" -eq 0 ]; then
    echo "Warning: $DISPLAY_NAME does not appear to be installed. Continuing anyway." >&2
fi

if [ ! -d "$AGENTS_DIR" ]; then
    mkdir -p "$AGENTS_DIR"
    echo "Created directory: $AGENTS_DIR"
fi

# --- Render ------------------------------------------------------------------

DELEGATION=""
if [ -f "$RUNTIME_DIR/delegation.md" ]; then
    DELEGATION="$(cat "$RUNTIME_DIR/delegation.md")"
fi
DELEGATION_INLINE="$(conf_get "$CONF" delegation_inline)"

installed=""
skipped=""

for name in $AGENT_NAMES; do
    src="$REPO_ROOT/$(agent_source "$name")"
    if [ ! -f "$src" ]; then
        echo "Warning: source not found, skipping: $src" >&2
        skipped="$skipped $name"
        continue
    fi

    fm_block="$(awk 'NR==1 && $0=="---" {next} /^---$/ {exit} NR>1 {print}' "$src")"
    # awk keeps the blank line that follows the closing '---'; strip leading
    # blanks so output matches install.ps1 byte for byte.
    body="$(awk 'f {print} /^---$/ {c++; if (c==2) f=1}' "$src" | sed '/./,$!d')"

    description="$(printf '%s\n' "$fm_block" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"
    capability="$(printf '%s\n' "$fm_block" | sed -n 's/^capability:[[:space:]]*//p' | head -n 1)"

    if [ -z "$capability" ]; then
        echo "No 'capability' declared in $src" >&2
        exit 1
    fi

    # A runtime may override a single agent's frontmatter by name when the
    # capability class is not precise enough (e.g. grunt is deliberately
    # narrower than implementer). Per-agent file wins; class is the default.
    fm_tpl="$RUNTIME_DIR/frontmatter/$name.yml"
    [ -f "$fm_tpl" ] || fm_tpl="$RUNTIME_DIR/frontmatter/$capability.yml"
    if [ ! -f "$fm_tpl" ]; then
        echo "Runtime '$RUNTIME' has no template for '$name' or capability '$capability'" >&2
        exit 1
    fi

    model="$(conf_get "$CONF" "model.$name")"
    if [ -z "$model" ]; then
        echo "Runtime '$RUNTIME' does not assign a model for '$name' (missing model.$name)" >&2
        exit 1
    fi

    temperature="$(conf_get "$CONF" "temperature.$name")"
    [ -n "$temperature" ] || temperature="0.1"

    frontmatter="$(cat "$fm_tpl")"
    frontmatter="${frontmatter//\{\{NAME\}\}/$name}"
    frontmatter="${frontmatter//\{\{DESCRIPTION\}\}/$description}"
    frontmatter="${frontmatter//\{\{MODEL\}\}/$model}"
    frontmatter="${frontmatter//\{\{TEMPERATURE\}\}/$temperature}"

    rendered_body="${body//\{\{DELEGATION\}\}/$DELEGATION}"
    rendered_body="${rendered_body//\{\{DELEGATION_INLINE\}\}/$DELEGATION_INLINE}"
    rendered_body="${rendered_body//\{\{RUNTIME\}\}/$DISPLAY_NAME}"

    dst="$AGENTS_DIR/$name.md"
    if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
        printf '  %s.md already exists. Replace? [y/N]: ' "$name"
        read -r answer
        case "$answer" in
            y|Y|yes|YES) ;;
            *) echo "  Skipped $name.md."; skipped="$skipped $name"; continue ;;
        esac
    fi

    rendered="$(printf -- '---\n%s\n---\n\n%s' "$frontmatter" "$rendered_body")"

    # A typo'd or unknown token would otherwise ship verbatim into an agent
    # file, silently. Fail loudly instead.
    leftover="$(printf '%s' "$rendered" | grep -o '{{[A-Z_]*}}' | head -n 1 || true)"
    if [ -n "$leftover" ]; then
        echo "Unsubstituted token $leftover while rendering '$name' for runtime '$RUNTIME'" >&2
        exit 1
    fi

    printf '%s\n' "$rendered" > "$dst"
    installed="$installed $name"
done

# --- Runtime-level permissions ----------------------------------------------

PERM_FILE="$RUNTIME_DIR/settings-permissions.json"
if [ -f "$PERM_FILE" ] && [ "$PERMISSION_SCOPE" != "none" ]; then
    # Project scope keeps the deny rules confined to the repository you are
    # working in. User scope applies them to every session on the machine,
    # which is rarely what you want for a tool-scoped safety rule.
    if [ "$PERMISSION_SCOPE" = "project" ]; then
        settings_dir="$(pwd)/.claude"
    else
        settings_dir="$(dirname "$AGENTS_DIR")"
    fi
    mkdir -p "$settings_dir"
    settings_path="$settings_dir/settings.json"
    if command -v jq >/dev/null 2>&1; then
        if [ -f "$settings_path" ]; then
            tmp="$(mktemp)"
            jq -s '.[0] as $cur | .[1] as $new
                   | $cur
                   | .permissions //= {}
                   | .permissions.deny = (((.permissions.deny // []) + $new.permissions.deny) | unique)' \
               "$settings_path" "$PERM_FILE" > "$tmp" && mv "$tmp" "$settings_path"
        else
            cp "$PERM_FILE" "$settings_path"
        fi
        echo
        echo "Added git-safety rules ($PERMISSION_SCOPE scope):"
        echo "  $settings_path"
        if [ "$PERMISSION_SCOPE" = "project" ]; then
            echo "  Re-run in each repository where you want these rules."
        fi
    else
        echo
        echo "Warning: jq not found - could not merge git-safety rules." >&2
        echo "Add the following to $settings_path by hand:" >&2
        cat "$PERM_FILE" >&2
    fi
fi

# --- Report ------------------------------------------------------------------

echo
if [ -n "$installed" ]; then
    echo "Installed:"
    for name in $installed; do echo "  $name"; done
fi
if [ -n "$skipped" ]; then
    echo "Skipped:"
    for name in $skipped; do echo "  $name"; done
fi

echo
echo "OpenCrew installed for $DISPLAY_NAME."
echo
echo "Try:"
echo
echo "  @crew-lead Explain how authentication works in this repository."
