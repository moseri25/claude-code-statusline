#!/bin/bash
# Token/Cost Monitor - writes live status to ~/.claude/token_status.json
# Run continuously: while true; do ~/.claude/token_monitor.sh; sleep 5; done

OUTFILE="$HOME/.claude/token_status.json"

# Try to read last known status from statusline
# (This is a fallback - ideally Claude Code would expose this via API)
# For now, we write placeholder data that gets updated when messages flow

# If statusline output exists and is recent, extract token counts
if [ -f "$HOME/.claude/hooks/auto_select.log" ]; then
  LAST_LOG=$(tail -1 "$HOME/.claude/hooks/auto_select.log" 2>/dev/null)
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Write minimal status to file for statusline to read
  jq -n --arg ts "$TIMESTAMP" '{
    timestamp: $ts,
    source: "background_monitor",
    note: "Real-time updates via hook"
  }' > "$OUTFILE" 2>/dev/null
fi

exit 0
