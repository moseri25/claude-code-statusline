---
description: Toggle statusline selection mode between AUTO and MANUAL
argument-hint: [auto|manual]
---

Toggle or set the selection mode that controls whether the auto_select hook auto-picks model/effort.

Argument passed: $ARGUMENTS

Steps:
1. If `$ARGUMENTS` is `auto`, run: `echo auto > ~/.claude/selection_mode`
2. If `$ARGUMENTS` is `manual`, run: `echo manual > ~/.claude/selection_mode`
3. Otherwise run: `~/.claude/toggle_mode.sh`

After the change, read `~/.claude/selection_mode` and print one short line like:
`🔒 MANUAL — model=claude-opus-4-7 effort=max` (or AUTO), using values from `~/.claude/settings.json`.
