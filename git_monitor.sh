#!/bin/bash
# Real-time git status monitor - updates cache continuously
# Run in background: nohup ~/.claude/git_monitor.sh &

GIT_CACHE="$HOME/.claude/git_cache.json"
WORKSPACE_CACHE="$HOME/.claude/workspace_cache.txt"

update_git_cache() {
  local dir=$1
  [ -z "$dir" ] && return

  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    return
  fi

  GB=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$GB" ] && GB=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  GM=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l)
  GAB=$(git -C "$dir" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
  GAHEAD=0; GBEHIND=0
  if [ -n "$GAB" ]; then
    GBEHIND=$(echo "$GAB" | awk '{print $1}')
    GAHEAD=$(echo "$GAB" | awk '{print $2}')
  fi

  jq -n --arg branch "$GB" --arg files "$GM" --arg ahead "$GAHEAD" --arg behind "$GBEHIND" '{
    timestamp: (now | todate),
    branch: $branch,
    modified_files: ($files | tonumber),
    ahead: ($ahead | tonumber),
    behind: ($behind | tonumber)
  }' > "$GIT_CACHE" 2>/dev/null
}

# Monitor loop
while true; do
  # Read workspace from cache file (written by cache_status.sh)
  WORKSPACE=$(cat "$WORKSPACE_CACHE" 2>/dev/null)

  # Fallback: try token cache
  if [ -z "$WORKSPACE" ]; then
    WORKSPACE=$(jq -r '.workspace.current_dir // ""' "$HOME/.claude/token_cache.json" 2>/dev/null)
  fi

  if [ -n "$WORKSPACE" ] && [ -d "$WORKSPACE" ]; then
    update_git_cache "$WORKSPACE"
  fi

  # Update every 1 second for real-time feel
  sleep 1
done

exit 0
