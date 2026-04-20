#!/bin/bash
# UserPromptSubmit hook: auto-pick model + effort based on prompt complexity.
# Reads JSON from stdin, scores the prompt, rewrites ~/.claude/settings.json.

SETTINGS="$HOME/.claude/settings.json"
LOG="$HOME/.claude/hooks/auto_select.log"

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')
[ -z "$prompt" ] && exit 0

# use byte count so Hebrew (2 bytes/char) scores proportionally
len=$(echo -n "$prompt" | wc -c)
lc=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

score=0
score=$((score + len / 15))

# high-complexity action keywords (English + Hebrew) → +3 each
for kw in implement refactor architect design debug optimize build create add fix \
          migrate deploy integrate analyze review benchmark test \
          תקן תכתוב בנה תבנה תיצור תעצב תכנן תשפר תוסיף תבדוק \
          תנתח תפתח תחקור תחשב תמפה תמד תממש; do
  echo "$lc" | grep -q "$kw" && score=$((score + 3))
done

# moderate-complexity words (explain, deep, thorough) → +2 each
for kw in explain understand describe summarize compare \
          "how does" "how do" "what is" "why does" \
          thorough complete comprehensive full deep detailed \
          תסביר תאר השווה "איך עובד" "מה זה" "למה" "כיצד" \
          מעמיק מקיף מפורט מורכב עמוק שלם; do
  echo "$lc" | grep -q "$kw" && score=$((score + 2))
done

# simple / chit-chat keywords → -3 each
for kw in "^hi$" "^hey$" "^hello$" "^thanks" "^thank you" "^ok$" "^yes$" "^no$" \
          "היי" "שלום" "תודה" "אוקיי"; do
  echo "$lc" | grep -qE "$kw" && score=$((score - 3))
done

# file mentions → +2 each
file_hits=$(echo "$prompt" | grep -oE '\.(py|js|ts|tsx|jsx|go|rs|java|cpp|c|rb|php|sh|json|yaml|yml|toml|md)\b' | wc -l)
score=$((score + file_hits * 2))

# code fence → +5
echo "$prompt" | grep -q '```' && score=$((score + 5))

# multi-step / compound markers → +1 each
for m in " then " " also " " and also" " וגם " "step 1" "1\." "first," "second," \
         "לאחר מכן" "בנוסף" "ולאחר" "שלב 1" "שלב ראשון"; do
  echo "$lc" | grep -q "$m" && score=$((score + 1))
done

# map to tier: 9 levels
if   [ $score -le 0 ]; then MODEL="claude-haiku-4-5-20251001"; EFFORT="low"    # trivial
elif [ $score -lt 2 ]; then MODEL="claude-haiku-4-5-20251001"; EFFORT="medium" # simple
elif [ $score -lt 4 ]; then MODEL="claude-sonnet-4-6";         EFFORT="low"    # moderate
elif [ $score -lt 6 ]; then MODEL="claude-sonnet-4-6";         EFFORT="medium" # moderate+
elif [ $score -lt 8 ]; then MODEL="claude-sonnet-4-6";         EFFORT="high"   # moderate-high
elif [ $score -lt 10 ]; then MODEL="claude-opus-4-7";          EFFORT="low"    # complex
elif [ $score -lt 12 ]; then MODEL="claude-opus-4-7";          EFFORT="medium" # complex
elif [ $score -lt 14 ]; then MODEL="claude-opus-4-7";          EFFORT="high"   # very complex
else                        MODEL="claude-opus-4-7";           EFFORT="xhigh"  # extremely complex
fi

# rewrite settings.json atomically
tmp=$(mktemp)
jq --arg m "$MODEL" --arg e "$EFFORT" \
   '.model = $m | .effortLevel = $e' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "$(date -Iseconds) score=$score len=$len model=$MODEL effort=$EFFORT prompt=${prompt:0:60}" >> "$LOG"

exit 0
