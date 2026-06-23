#!/bin/bash
# Sum tokens across Claude Code transcripts. Output: day|week|total (sums).
# Cache 60s.
CACHE="$HOME/.cache/claude-statusline/total_tokens"
mkdir -p "$(dirname "$CACHE")" 2>/dev/null

AGE=9999
[ -f "$CACHE" ] && AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))

if [ $AGE -gt 60 ]; then
  python3 - <<'PY' > "$CACHE" 2>/dev/null
import json, glob, os, datetime as dt
now = dt.datetime.now(dt.timezone.utc)
cut_5h = now - dt.timedelta(hours=5)
cut_7d = now - dt.timedelta(days=7)
day_sum = week_sum = tot_sum = 0
def parse_ts(s):
    try: return dt.datetime.fromisoformat(s.replace('Z','+00:00'))
    except: return None
for f in glob.glob(os.path.expanduser('~/.claude/projects/*/*.jsonl')):
    try:
        with open(f) as fh:
            for l in fh:
                try:
                    d=json.loads(l)
                    m=d.get('message')
                    if not isinstance(m, dict): continue
                    u=m.get('usage')
                    if not u: continue
                    n = (u.get('input_tokens',0) or 0) + (u.get('output_tokens',0) or 0) \
                        + (u.get('cache_creation_input_tokens',0) or 0) \
                        + (u.get('cache_read_input_tokens',0) or 0)
                    tot_sum += n
                    ts = parse_ts(d.get('timestamp',''))
                    if ts:
                        if ts >= cut_5h: day_sum += n
                        if ts >= cut_7d: week_sum += n
                except: pass
    except: pass
print(f"{day_sum}|{week_sum}|{tot_sum}")
PY
fi

cat "$CACHE" 2>/dev/null || echo "0|0|0"
