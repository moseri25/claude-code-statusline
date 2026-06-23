# Claude Code Statusline

> Advanced, information-dense status line for [Claude Code](https://claude.com/claude-code) — model & thinking effort, context usage, 5h/7d rate-limit bars with token counts and reset countdowns, live git status, subscription/API mode, and an optional **AUTO** model selector that picks the right model per prompt.

Created by **Yaakov Moseri**.

```
👤 Created by Yaakov Moseri
[Opus 4.8] 🧠⚡ xhigh v2.0.14 🦧caveman - off 🔄 AUTO 📁 my-project 🌿 main 🟢0 🔴0 🟡2
5h  ████████░░░░ 64%  🪙 1.2M  ⏳2h 13m
7d  ███░░░░░░░░░ 28%  🪙 8.4M  ⏳5d 4h
✅ Subscription Active                              ⏱️ 1h 22m
```

Works everywhere Claude Code runs — desktop, and mobile (Termux / proot) where it was tuned to render cleanly on a ~40-column phone screen.

---

## What it shows

| Segment | Meaning |
| --- | --- |
| `[Opus 4.8]` | Live running model (`display_name` from the payload). Shows `→ Target` when AUTO has queued a different model for the next turn. |
| `🧠 / 🧠⚡` | Thinking effort (`low` / `medium` / `high` / `xhigh` / `max`), validated against what each model actually supports. |
| `v2.0.14` | Claude Code version. |
| `🦧 caveman` | Optional [caveman mode](#optional-caveman-mode) state. |
| `🔄 AUTO` / `🔒 MANUAL` | Model-selection mode (see [AUTO vs MANUAL](#auto-vs-manual-model-selection)). |
| `📁 dir 🌿 branch` | Current directory + git branch with three traffic lights: 🟢 ahead · 🔴 behind · 🟡 modified. |
| `5h` / `7d` bars | Rate-limit usage bars (green→yellow→red), `🪙` token totals for the window, and `⏳` countdown to reset. |
| `✅ Subscription` / `🔑 API` | Whether you're on a subscription or billing the API (auto-detected from `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL`). |
| `⏱️ 1h 22m` | Total session duration. |

All live data (cost, rate limits, context window) is cached to `~/.claude/token_cache.json` so the line never flashes zeros on idle refreshes.

---

## Requirements

- **Claude Code** (the line is wired through `settings.json`)
- **`jq`** — JSON parsing (required)
- **`python3`** — token summation across transcripts (required for the `🪙` counts)
- **`git`** — for the git segment (optional)

---

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/moseri25/claude-code-statusline/main/install.sh | bash
```

The installer:
1. Copies the scripts into `~/.claude/` (`statusline.sh`, `total_tokens.sh`, `toggle_mode.sh`), the hooks into `~/.claude/hooks/`, and the `/mode` skill into `~/.claude/skills/mode/`.
2. Backs up your existing `~/.claude/settings.json` (timestamped) and **merges** in the `statusLine` command and the `UserPromptSubmit` hooks — idempotently, so re-running it won't create duplicates.
3. Makes everything executable.

Then **restart Claude Code** (or start a new session) to see the line.

> Honors `CLAUDE_CONFIG_DIR` if you keep your config somewhere other than `~/.claude`.

---

## Manual install

```bash
git clone https://github.com/moseri25/claude-code-statusline.git
cd claude-code-statusline
./install.sh
```

Or wire it by hand — copy the files and add this to `~/.claude/settings.json`
(see [`settings.example.json`](settings.example.json)):

```jsonc
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  },
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [
        { "type": "command", "command": "~/.claude/hooks/auto_select.sh" },
        { "type": "command", "command": "~/.claude/hooks/caveman_state.sh" },
        { "type": "command", "command": "~/.claude/hooks/cache_status.sh" }
      ] }
    ]
  }
}
```

---

## How it works

- **`statusline.sh`** — the renderer. Claude Code pipes the live status payload to it on stdin every refresh; it parses with `jq`, merges in cached rate-limits (the live payload omits them on idle refreshes), and prints a width-aware, color-coded line.
- **`total_tokens.sh`** — sums `input + output + cache` tokens across all `~/.claude/projects/*/*.jsonl` transcripts into 5h / 7d / all-time totals (cached 60s).
- **`hooks/cache_status.sh`** — `UserPromptSubmit` hook that persists the working directory so the git segment resolves even on empty refreshes.
- **`hooks/auto_select.sh`** — the AUTO brain (below).
- **`hooks/caveman_state.sh`** — tracks optional caveman-mode state.

### AUTO vs MANUAL model selection

In **AUTO** mode, `auto_select.sh` scores each prompt (length, complexity keywords in English **and Hebrew**, file mentions, code fences, multi-step markers) and rewrites `model` + `effortLevel` in `settings.json` — small talk → Haiku, everyday work → Sonnet, heavy/complex work → Opus with higher effort.

Toggle with the bundled **`/mode`** skill:

```
/mode            # toggle
/mode auto       # let prompts pick the model
/mode manual     # freeze model/effort; you control /model and /effort
```

`🔒 MANUAL` in the line means auto-selection is off.

### Customization

Set these env vars in your shell:

| Variable | Effect |
| --- | --- |
| `CLAUDE_STATUSLINE_NARROW=1` | Compact layout for very narrow terminals. |
| `CLAUDE_STATUSLINE_COLS=100` | Wrap width (default `40`, tuned for phones; raise on desktop). |

### Optional: caveman mode

`caveman_state.sh` and the `🦧` segment integrate with a separate caveman-mode toolset. The statusline works fully without it — the segment just reads `off`.

---

## Uninstall

```bash
rm -f ~/.claude/statusline.sh ~/.claude/total_tokens.sh ~/.claude/toggle_mode.sh
rm -f ~/.claude/hooks/auto_select.sh ~/.claude/hooks/cache_status.sh ~/.claude/hooks/caveman_state.sh
rm -rf ~/.claude/skills/mode
```

Then remove the `statusLine` and `UserPromptSubmit` entries from `~/.claude/settings.json`
(a timestamped backup was saved at install time).

---

## License

[MIT](LICENSE) © Yaakov Moseri
