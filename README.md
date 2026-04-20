# Claude Code Statusline

Advanced status line for Claude Code with compression mode display, token tracking, git info, cost monitoring, and full tool autonomy.

## Features

- 🦧 **Caveman Mode Display** — Shows active compression level (lite, full, ultra, wenyan-*)
- 📊 **Real-time Status** — Model, effort level, working directory, git branch
- 🪙 **Token Tracking** — 5-hour and 7-day rate limit display with visual bars
- 💰 **Cost Monitoring** — Track API spend or subscription status
- ⏱️ **Duration** — Session runtime
- ⚙️ **Full Tool Autonomy** — Bypass permission prompts (announces destructive actions)

## Installation

### Quick Start

```bash
git clone https://github.com/moseri25/claude-code-statusline.git
cd claude-code-statusline
bash install.sh
```

### Manual Setup

1. Copy `statusline.sh` to `~/.claude/`:
```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

3. Create caveman state file:
```bash
echo "full" > ~/.claude/caveman_state
```

4. For full tool autonomy, add to `~/.claude/settings.local.json`:
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

## Usage

### Switch Caveman Compression Level

Ask Claude: "caveman [level]"

Supported levels:
- `lite` — Ultra-compressed, minimal tokens
- `full` — Balanced compression (default)
- `ultra` — Maximum compression
- `wenyan-lite` — Ancient Chinese style, lite
- `wenyan-full` — Ancient Chinese style, full
- `wenyan-ultra` — Ancient Chinese style, ultra

### Status Line Display

Example output:
```
[Opus 4.7] 🧠xhigh | 📁 project | 🌿 main ±0 ↑0 ↓0
5h ███░░░░░░ 35% 🪙156.2K
7d █████░░░░ 50% 🪙1.2M
✅ Subscription Active | ⏱️ 45m
```

Colored segments:
- 🦧caveman - ultra (yellow)
- Rate limit bars (green/yellow/red by usage)
- Git status (green/yellow by modifications)

## Configuration

Edit `~/.claude/statusline.sh` to customize:
- Colors (CYAN, GREEN, YELLOW, etc.)
- Emoji choices
- Segment layout
- Bar styles

## Requirements

- Claude Code
- `jq` (JSON query tool)
- `git` (for branch info)
- bash 4+

## Troubleshooting

**Status line not showing:**
- Restart Claude Code
- Check that `~/.claude/statusline.sh` has execute permission
- Verify `settings.json` has correct path

**Caveman mode not displaying:**
- Create `~/.claude/caveman_state` with content: `full`
- Request compression change: "caveman ultra"

**Permissions still prompting:**
- Ensure `settings.local.json` has `"defaultMode": "bypassPermissions"`
- Restart Claude Code

## License

MIT

## Author

Created for Claude Code on Termux (works on any terminal)
