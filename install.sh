#!/bin/bash
set -e

echo "📦 Installing Claude Code Statusline..."

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Copy statusline script
echo "📋 Installing statusline.sh..."
cp statusline.sh "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"

# Create caveman state file
echo "🦧 Setting up caveman state..."
touch "$CLAUDE_DIR/caveman_state"
echo "full" > "$CLAUDE_DIR/caveman_state"

# Update settings.json
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "⚙️  Updating settings.json with statusline..."
  if ! grep -q '"statusLine"' "$CLAUDE_DIR/settings.json"; then
    # Add statusline config before closing brace
    sed -i '/"permissions"/a\  "statusLine": {\n    "type": "command",\n    "command": "~/.claude/statusline.sh"\n  },' "$CLAUDE_DIR/settings.json"
  fi
else
  echo "⚠️  settings.json not found, creating minimal config..."
  cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-opus-4-7",
  "effortLevel": "xhigh",
  "tui": "fullscreen",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  },
  "env": {
    "CLAUDE_CODE_NO_FLICKER": "1"
  }
}
EOF
fi

# Update settings.local.json for permissions
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
  echo "⚙️  Updating settings.local.json with bypassPermissions..."
  if ! grep -q '"defaultMode"' "$CLAUDE_DIR/settings.local.json"; then
    sed -i '/"permissions"/a\    "defaultMode": "bypassPermissions",' "$CLAUDE_DIR/settings.local.json"
  fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Features installed:"
echo "  🦧 Caveman mode display (compression level)"
echo "  📊 Status line with model, effort, git, tokens, cost"
echo "  ⚙️  Full tool autonomy (bypassPermissions)"
echo ""
echo "Next: Restart Claude Code to see the statusline in action"
