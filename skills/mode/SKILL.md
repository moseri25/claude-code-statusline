---
name: mode
description: >
  Toggle statusline model-selection mode between AUTO and MANUAL. Writes to
  ~/.claude/selection_mode, which the auto_select hook and statusline read.
  Use when user says "/mode", "mode auto", "mode manual", "toggle selection mode",
  or wants to lock/unlock automatic model picking.
---

Set or toggle the model-selection mode used by `~/.claude/hooks/auto_select.sh`
and shown in the statusline (🔄 AUTO / 🔒 MANUAL).

## Argument handling

The argument arrives as `$ARGUMENTS` in the slash-command context. Treat an empty
argument as "toggle".

Run exactly one of:

- `$ARGUMENTS` = `auto`   → `echo auto > ~/.claude/selection_mode`
- `$ARGUMENTS` = `manual` → `echo manual > ~/.claude/selection_mode`
- empty / anything else   → `~/.claude/toggle_mode.sh`

## After the change

Read back the current state and report one terse line:

```bash
MODE=$(cat ~/.claude/selection_mode 2>/dev/null || echo auto)
MODEL=$(jq -r '.model // "?"' ~/.claude/settings.json 2>/dev/null)
EFFORT=$(jq -r '.effortLevel // "?"' ~/.claude/settings.json 2>/dev/null)
```

Format:
- AUTO   → `🔄 AUTO — model=$MODEL effort=$EFFORT`
- MANUAL → `🔒 MANUAL — model=$MODEL effort=$EFFORT`

Do not explain further unless the user asks. Statusline refreshes on next prompt.
