---
name: mode
description: >
  Toggle the statusline selection mode between AUTO (model + effort auto-selected
  per prompt complexity by the auto_select hook) and MANUAL (user's /model and
  /effort choices stay frozen). Runs ~/.claude/toggle_mode.sh and reports the new state.
  Triggers: "/mode", "toggle mode", "switch auto/manual", "lock model".
---

Run `~/.claude/toggle_mode.sh` using the Bash tool and show the user the output verbatim (it already prints the new mode and current model/effort).

If the user passes an argument — `auto` or `manual` — set that mode directly instead of toggling:
- `auto`: `echo auto > ~/.claude/selection_mode`
- `manual`: `echo manual > ~/.claude/selection_mode`

Then print the resulting state: `cat ~/.claude/selection_mode` plus current model/effort from `~/.claude/settings.json`.

Keep the reply to one or two short lines. No preamble.
