#!/bin/bash
# Toggle between auto (model auto-selected by prompt complexity) and manual (user controls model/effort)
MODE_FILE="$HOME/.claude/selection_mode"
SETTINGS="$HOME/.claude/settings.json"

current=$(cat "$MODE_FILE" 2>/dev/null || echo "auto")

if [ "$current" = "auto" ]; then
  echo "manual" > "$MODE_FILE"
  echo "🔒 MANUAL mode — model/effort frozen, auto-selection disabled."
  echo "   Use /model and /effort in Claude Code to change manually."
  echo "   Current: model=$(jq -r '.model' "$SETTINGS") effort=$(jq -r '.effortLevel' "$SETTINGS")"
else
  echo "auto" > "$MODE_FILE"
  echo "🔄 AUTO mode — model/effort will be auto-selected per prompt complexity."
fi
