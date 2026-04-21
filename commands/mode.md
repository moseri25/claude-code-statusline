---
allowed-tools: Bash(~/.claude/toggle_mode.sh), Bash(cat:*), Bash(echo:*), Bash(jq:*)
description: Toggle statusline selection mode between AUTO and MANUAL
argument-hint: "[auto|manual]"
---

## Context

- Current mode: !`cat ~/.claude/selection_mode 2>/dev/null || echo auto`
- Current model: !`jq -r '.model' ~/.claude/settings.json`
- Current effort: !`jq -r '.effortLevel' ~/.claude/settings.json`

## Your task

Argument passed: `$ARGUMENTS`

- If argument is `auto`: run `echo auto > ~/.claude/selection_mode`
- If argument is `manual`: run `echo manual > ~/.claude/selection_mode`
- If argument is empty: run `~/.claude/toggle_mode.sh` to flip the current mode

Then report the new mode in one short line along with current model/effort.
