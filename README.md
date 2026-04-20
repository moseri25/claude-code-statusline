# Claude Code Statusline

**👤 Created by Yaakov Moseri**

Advanced terminal status line for Claude Code with real-time compression mode display, token tracking, git integration, cost monitoring, and full tool autonomy.

Built for developers using Claude Code in Termux and other terminal environments.

## 🎯 Features

### 🦧 Caveman Mode Display
Shows active compression level in real-time:
- `lite` — Ultra-compressed, minimal tokens
- `full` — Balanced compression
- `ultra` — Maximum compression (default)
- `wenyan-lite` — Ancient Chinese style, lite
- `wenyan-full` — Ancient Chinese style, full  
- `wenyan-ultra` — Ancient Chinese style, ultra

### 📊 Real-time Status Information
- **Model** — Current Claude model (Haiku, Sonnet, Opus)
- **Effort Level** — Request complexity level (low, medium, high, xhigh)
- **Directory** — Current working directory
- **Git Branch** — Active git branch with status indicators
- **Token Usage** — 5-hour and 7-day rate limit display with visual bars
- **Cost Monitor** — API spend tracking or subscription status
- **Duration** — Total session runtime

### ⚙️ Full Tool Autonomy
- Bypass permission prompts for non-destructive operations
- Announces destructive actions before execution
- Streamlined workflow without constant approvals

### 🎨 Visual Indicators
- Colored segments for quick status scanning
- Progress bars for rate limits (█░ format)
- Git status icons (±modified, ↑ahead, ↓behind)
- Emoji indicators for mode and features

## 📦 Quick Install

```bash
git clone https://github.com/moseri25/claude-code-statusline.git
cd claude-code-statusline
bash install.sh
```

Then restart Claude Code to see the statusline in action.

## 📋 What Gets Installed

The installation script automatically:
- ✅ Copies `statusline.sh` to `~/.claude/`
- ✅ Creates `~/.claude/caveman_state` (defaults to `ultra`)
- ✅ Updates `~/.claude/settings.json` with statusline command
- ✅ Enables full tool autonomy in `settings.local.json`
- ✅ Sets proper permissions (755) on scripts

## 🎮 Using Caveman Compression Modes

Switch compression level anytime by asking Claude:

```
"caveman ultra"      # Maximum compression
"caveman full"       # Balanced (medium compression)
"caveman lite"       # Minimal compression
"caveman wenyan-ultra" # Ancient Chinese, maximum
```

The statusline updates instantly showing your active mode:
```
🦧caveman - ultra
```

## 📊 Status Line Display

### Example Output
```
[Opus 4.7] 🧠xhigh | 📁 project | 🌿 main ±0 ↑0 ↓0
5h ███░░░░░░ 35% 🪙156.2K
7d █████░░░░ 50% 🪙1.2M
✅ Subscription Active | ⏱️ 45m
```

### Color Scheme
- 🟢 **Green** — Normal/optimal state
- 🟡 **Yellow** — Warnings (high usage, git changes)
- 🔴 **Red** — Critical (>90% rate limit)
- ⚪ **Gray** — Disabled/unavailable features

## 🔧 Configuration

### Customize Colors
Edit `~/.claude/statusline.sh` lines 10-11:
```bash
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
```

### Change Default Caveman Level
Edit `install.sh` before running:
```bash
echo "lite" > "$CLAUDE_DIR/caveman_state"  # or "full", "ultra"
```

### Modify Status Segments
Edit the `add` commands in `statusline.sh` (lines 163-186) to customize what displays.

## 🛠️ Manual Setup (if install.sh fails)

### 1. Copy Statusline Script
```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### 2. Add to Settings
Create/edit `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

### 3. Setup Caveman State
```bash
echo "ultra" > ~/.claude/caveman_state
```

### 4. Enable Tool Autonomy
Create/edit `~/.claude/settings.local.json`:
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

## 📋 Requirements

- **Claude Code** (web, desktop, or CLI)
- **bash** 4.0+
- **jq** (JSON query tool)
- **git** (for branch display)
- **tput** (terminal info - usually included)

## 🐛 Troubleshooting

### Status line not showing
- Restart Claude Code completely
- Verify `~/.claude/statusline.sh` has execute permission: `ls -la ~/.claude/statusline.sh`
- Check `settings.json` points to correct path

### Caveman mode not displaying
- Create file: `touch ~/.claude/caveman_state`
- Add content: `echo "ultra" > ~/.claude/caveman_state`
- Ask Claude to switch: "caveman ultra"

### Permissions still prompting
- Ensure `settings.local.json` has `"defaultMode": "bypassPermissions"`
- Check syntax is valid JSON
- Restart Claude Code

### Rate limit bars not showing
- Ensure `jq` is installed: `command -v jq`
- Check `~/.claude/settings.json` has rate limit tracking enabled

## 🔐 Security Notes

- statusline.sh is read-only and non-destructive
- No credentials stored in statusline
- Token display is always truncated for security
- Install script creates proper file permissions (600 for state files)

## 📚 Files Included

- `statusline.sh` — Main status line display script (11KB)
- `install.sh` — Automated installation script
- `README.md` — This documentation
- `LICENSE` — MIT license
- `.gitignore` — Standard git ignore rules

## 🤝 Contributing

Found a bug or want to improve it? 
1. Fork the repo
2. Create a feature branch
3. Submit a pull request

## 📄 License

MIT License — Free to use and modify

## 💡 Tips & Tricks

### Use with Multiple Terminals
Each terminal runs its own Claude Code session, so each gets its own statusline display. Perfect for parallel work!

### Combine with Aliases
```bash
alias cc='claude-code'  # Quick launch
alias ccf='claude --model opus-4-7 --effort xhigh'  # Fast mode
```

### Monitor Rate Limits
Watch the 5h and 7d bars in the statusline to stay under rate limits. Red means you're above 90% usage.

### Switch Models on the Fly
Set `model` in settings.json to switch Claude models between sessions. Statusline shows the active model.

## 🆘 Support

- **Issues**: Open a GitHub issue with details about your setup
- **Questions**: Check this README for troubleshooting section first
- **Feature Requests**: Describe your use case in a GitHub discussion

## 🌟 Highlights

- **Tiny & Fast** — Single bash script, minimal overhead
- **Works Everywhere** — Termux, macOS, Linux, Windows (WSL)
- **Zero Dependencies** — Just bash, jq, and git
- **Fully Customizable** — Edit colors, layout, segments
- **Privacy First** — No external APIs, all local

---

## 👤 Author

**👤 Created by Yaakov Moseri** ([GitHub](https://github.com/moseri25))

Made for developers who want full control and visibility over their Claude Code workflow.
