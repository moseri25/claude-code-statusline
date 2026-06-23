#!/bin/bash
# Detect /caveman skill invocation and write level to ~/.claude/caveman_state

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null)

# Extract /caveman command + level from prompt
if [[ "$prompt" =~ ^/caveman([[:space:]]+([a-z-]+))?$ ]]; then
  level="${BASH_REMATCH[2]}"

  # Default to "full" if no level specified
  if [ -z "$level" ]; then
    level="full"
  fi

  # Validate level
  if [[ "$level" =~ ^(lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra)$ ]]; then
    echo "$level" > ~/.claude/caveman_state 2>/dev/null
  elif [[ "$level" =~ ^(off|stop|disable)$ ]]; then
    rm -f ~/.claude/caveman_state 2>/dev/null
  fi
fi
