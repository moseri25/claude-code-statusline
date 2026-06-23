#!/bin/bash
# UserPromptSubmit hook. The UserPromptSubmit payload does NOT contain
# cost / rate_limits / context_window — only the statusLine payload does — so we
# do NOT try to cache those here (that only produced null caches). Cost/rate
# and git caching are handled by statusline.sh itself, which receives the full
# statusLine payload on every render.
#
# All we persist here is the working directory, so the statusline can resolve
# it (and its git status) when Claude Code refreshes the line with empty input.

input=$(cat)

DIR=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""' 2>/dev/null)
if [ -n "$DIR" ] && [ "$DIR" != "null" ]; then
  echo "$DIR" > "$HOME/.claude/workspace_cache.txt" 2>/dev/null
fi

# Pass input through unchanged
echo "$input"
exit 0
