#!/bin/bash
# Claude Code Statusline — installer
# Created by Yaakov Moseri — https://github.com/moseri25/claude-code-statusline
#
# One-command install:
#   curl -fsSL https://raw.githubusercontent.com/moseri25/claude-code-statusline/main/install.sh | bash
#
# Idempotent: safe to re-run. Backs up settings.json and merges (never duplicates).
set -euo pipefail

REPO_URL="https://github.com/moseri25/claude-code-statusline.git"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"

say()  { printf '\033[36m▸\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

# ---- dependencies ----
command -v jq      >/dev/null 2>&1 || die "jq is required (install it, e.g. 'apt install jq' / 'brew install jq' / 'pkg install jq')."
command -v python3 >/dev/null 2>&1 || warn "python3 not found — the 🪙 token counts will show 0 until it's installed."

# ---- locate the source files (local checkout, else clone) ----
SCRIPT_SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/statusline.sh" ]; then
  SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  command -v git >/dev/null 2>&1 || die "git is required to fetch the files when piping the installer."
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  say "Cloning $REPO_URL ..."
  git clone --depth 1 "$REPO_URL" "$TMP/repo" >/dev/null 2>&1 || die "git clone failed."
  SCRIPT_SRC="$TMP/repo"
fi

# ---- copy files ----
say "Installing into $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills/mode"
cp "$SCRIPT_SRC/statusline.sh"   "$CLAUDE_DIR/statusline.sh"
cp "$SCRIPT_SRC/total_tokens.sh" "$CLAUDE_DIR/total_tokens.sh"
cp "$SCRIPT_SRC/toggle_mode.sh"  "$CLAUDE_DIR/toggle_mode.sh"
cp "$SCRIPT_SRC/hooks/auto_select.sh"   "$CLAUDE_DIR/hooks/auto_select.sh"
cp "$SCRIPT_SRC/hooks/cache_status.sh"  "$CLAUDE_DIR/hooks/cache_status.sh"
cp "$SCRIPT_SRC/hooks/caveman_state.sh" "$CLAUDE_DIR/hooks/caveman_state.sh"
cp "$SCRIPT_SRC/skills/mode/SKILL.md"   "$CLAUDE_DIR/skills/mode/SKILL.md"
chmod +x "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/total_tokens.sh" "$CLAUDE_DIR/toggle_mode.sh" "$CLAUDE_DIR"/hooks/*.sh
ok "Scripts, hooks and /mode skill installed."

# ---- wire settings.json (backup + idempotent merge) ----
SL="$CLAUDE_DIR/statusline.sh"
HA="$CLAUDE_DIR/hooks/auto_select.sh"
HV="$CLAUDE_DIR/hooks/caveman_state.sh"
HC="$CLAUDE_DIR/hooks/cache_status.sh"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
BACKUP="$SETTINGS.bak.$(date +%Y%m%d_%H%M%S)"
cp "$SETTINGS" "$BACKUP"
say "Backed up settings.json → $(basename "$BACKUP")"

tmp="$(mktemp)"
jq --arg sl "$SL" --arg a "$HA" --arg cv "$HV" --arg cc "$HC" '
  .statusLine = {type:"command", command:$sl}
  | .hooks = (.hooks // {})
  | .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // [])
  # remove any previous group that referenced our auto_select hook, then re-add (idempotent)
  | .hooks.UserPromptSubmit |= map(select(((.hooks // []) | map(.command) | index($a)) | not))
  | .hooks.UserPromptSubmit += [ { hooks: [
        {type:"command", command:$a},
        {type:"command", command:$cv},
        {type:"command", command:$cc}
    ] } ]
' "$SETTINGS" > "$tmp" || die "Failed to update settings.json (it was not modified; backup at $BACKUP)."
mv "$tmp" "$SETTINGS"
ok "settings.json wired (statusLine + UserPromptSubmit hooks)."

# default to AUTO model selection unless already set
[ -f "$CLAUDE_DIR/selection_mode" ] || echo auto > "$CLAUDE_DIR/selection_mode"

echo
ok "Done. Restart Claude Code (or open a new session) to see the status line."
echo "   Toggle model selection with: /mode  ·  /mode auto  ·  /mode manual"
