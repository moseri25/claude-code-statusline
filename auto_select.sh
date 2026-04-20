#!/bin/bash
# UserPromptSubmit hook: auto-pick model + effort based on prompt complexity.
# Uses Claude's official adaptive thinking: effort levels per model.
# Reads JSON from stdin, scores prompt, rewrites ~/.claude/settings.json.

SETTINGS="$HOME/.claude/settings.json"
LOG="$HOME/.claude/hooks/auto_select.log"

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')
[ -z "$prompt" ] && exit 0

len=$(echo -n "$prompt" | wc -c)
lc=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

score=0
score=$((score + len / 15))

# high-complexity keywords → +3
for kw in implement refactor architect design debug optimize build create add fix \
          migrate deploy integrate analyze review benchmark test \
          תקן תכתוב בנה תבנה תיצור תעצב תכנן תשפר תוסיף תבדוק \
          תנתח תפתח תחקור תחשב תמפה תמד תממש; do
  echo "$lc" | grep -q "$kw" && score=$((score + 3))
done

# moderate-complexity words → +2
for kw in explain understand describe summarize compare \
          "how does" "how do" "what is" "why does" \
          thorough complete comprehensive full deep detailed \
          תסביר תאר השווה "איך עובד" "מה זה" "למה" "כיצד" \
          מעמיק מקיף מפורט מורכב עמוק שלם; do
  echo "$lc" | grep -q "$kw" && score=$((score + 2))
done

# simple/chit-chat keywords → -3
for kw in "^hi$" "^hey$" "^hello$" "^thanks" "^thank you" "^ok$" "^yes$" "^no$" \
          "היי" "שלום" "תודה" "אוקיי"; do
  echo "$lc" | grep -qE "$kw" && score=$((score - 3))
done

# file mentions → +2 each
file_hits=$(echo "$prompt" | grep -oE '\.(py|js|ts|tsx|jsx|go|rs|java|cpp|c|rb|php|sh|json|yaml|yml|toml|md)\b' | wc -l)
score=$((score + file_hits * 2))

# code fence → +5
echo "$prompt" | grep -q '```' && score=$((score + 5))

# multi-step markers → +1 each
for m in " then " " also " " and also" " וגם " "step 1" "1\." "first," "second," \
         "לאחר מכן" "בנוסף" "ולאחר" "שלב 1" "שלב ראשון"; do
  echo "$lc" | grep -q "$m" && score=$((score + 1))
done

# Real Claude adaptive thinking tiers:
# Haiku 4.5: NO thinking support (simple queries only)
# Sonnet 4.6: adaptive thinking with effort: low, medium, high, max
# Opus 4.7: adaptive thinking with effort: low, medium, high, xhigh, max

if   [ $score -le  3 ]; then
  MODEL="claude-haiku-4-5-20251001"
  EFFORT="none"  # Haiku: no thinking support
elif [ $score -le  7 ]; then
  MODEL="claude-sonnet-4-6"
  EFFORT="low"   # Sonnet: minimal thinking
elif [ $score -le 12 ]; then
  MODEL="claude-sonnet-4-6"
  EFFORT="medium"  # Sonnet: moderate thinking
elif [ $score -le 19 ]; then
  MODEL="claude-sonnet-4-6"
  EFFORT="high"  # Sonnet: deep thinking
elif [ $score -le 26 ]; then
  MODEL="claude-sonnet-4-6"
  EFFORT="max"  # Sonnet: maximum thinking
elif [ $score -le 32 ]; then
  MODEL="claude-opus-4-7"
  EFFORT="low"  # Opus: starting complexity
elif [ $score -le 38 ]; then
  MODEL="claude-opus-4-7"
  EFFORT="medium"  # Opus: moderate complexity
elif [ $score -le 39 ]; then
  MODEL="claude-opus-4-7"
  EFFORT="high"  # Opus: complex problems
elif [ $score -le 48 ]; then
  MODEL="claude-opus-4-7"
  EFFORT="xhigh"  # Opus: very complex
else
  MODEL="claude-opus-4-7"
  EFFORT="max"  # Opus: maximum thinking
fi

# rewrite settings.json atomically
tmp=$(mktemp)
jq --arg m "$MODEL" --arg e "$EFFORT" \
   '.model = $m | .effortLevel = $e' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "$(date -Iseconds) score=$score len=$len model=$MODEL effort=$EFFORT prompt=${prompt:0:60}" >> "$LOG"

exit 0
