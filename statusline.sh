#!/bin/bash
# Claude Code Statusline - Advanced Terminal Status Display
# Created by Yaakov Moseri
# https://github.com/moseri25/claude-code-statusline

# Try to read cached status first (for real-time display without messages)
CACHE="$HOME/.claude/token_cache.json"
if [ -f "$CACHE" ] && [ -s "$CACHE" ]; then
  # Only use cache if it has real data (not nulls)
  COST=$(jq -r '.cost.total_cost_usd // null' "$CACHE" 2>/dev/null)
  if [ "$COST" != "null" ] && [ -n "$COST" ]; then
    input=$(cat "$CACHE")
  else
    input=$(cat)  # Cache is empty, read from stdin
  fi
else
  input=$(cat)
fi

# ---- terminal width ----
COLS=${COLUMNS:-0}
[ "$COLS" -eq 0 ] && COLS=$(tput cols 2>/dev/null || echo 40)
[ "$COLS" -lt 20 ] && COLS=40

# ---- colors ----
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
MAGENTA='\033[35m'; GRAY='\033[90m'; RESET='\033[0m'

j() { echo "$input" | jq -r "$1"; }

# ---- fields ----
MODEL=$(j '.model.display_name')
VERSION=$(j '.version // ""')
DIR=$(j '.workspace.current_dir')
COST=$(j '.cost.total_cost_usd // 0')
PCT=$(j '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(j '.cost.total_duration_ms // 0')
RL5=$(j '.rate_limits.five_hour.resets_at // empty')
RL7=$(j '.rate_limits.seven_day.resets_at // empty')
RL5_PCT=$(j '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
RL7_PCT=$(j '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)

EFFORT=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
THINKING=$(jq -r '.alwaysThinkingEnabled // true' ~/.claude/settings.json 2>/dev/null)

# Get current model from settings.json (authoritative source)
MODEL_FROM_SETTINGS=$(jq -r '.model // empty' ~/.claude/settings.json 2>/dev/null)
# Fall back to input JSON if settings doesn't have it
MODEL_ID=$([ -n "$MODEL_FROM_SETTINGS" ] && echo "$MODEL_FROM_SETTINGS" || j '.model.id // ""')

# Validate effort level against model capabilities (Claude official docs)
validate_effort() {
  local model=$1 effort=$2
  case "$model" in
    *haiku*)   echo "none" ;;  # Haiku: NO thinking support
    *sonnet*)  # Sonnet: low/medium/high/max (NO xhigh)
      case "$effort" in
        low|medium|high|max) echo "$effort" ;;
        xhigh) echo "high" ;;  # xhigh not available for Sonnet, downgrade to high
        *) echo "low" ;;
      esac ;;
    *opus*)    # Opus: low/medium/high/xhigh/max
      case "$effort" in
        none) echo "low" ;;  # Opus supports thinking, use low minimum
        low|medium|high|xhigh|max) echo "$effort" ;;
        *) echo "low" ;;
      esac ;;
    *) echo "$effort" ;;
  esac
}

EFFORT=$(validate_effort "$MODEL_ID" "$EFFORT")

# adaptive thinking display mapping (Claude official)
thinking_label() {
  case "$1" in
    none)   echo "" ;;  # Haiku: no thinking support
    low)    echo "🧠 low" ;;
    medium) echo "🧠 medium" ;;
    high)   echo "🧠 high" ;;
    xhigh)  echo "🧠⚡ xhigh" ;;
    max)    echo "🧠⚡⚡ max" ;;
    *)      echo "" ;;
  esac
}
THINKING_LABEL=$(thinking_label "$EFFORT")

CAVEMAN_LEVEL=""
if [ -f ~/.claude/caveman_state ]; then
  CAVEMAN_LEVEL=$(cat ~/.claude/caveman_state 2>/dev/null)
fi

# Auto-picked target model (written by UserPromptSubmit hook)
CUR_MODEL_ID_RAW=$(j '.model.id // ""')
TARGET_ID=$(jq -r '.model // empty' ~/.claude/settings.json 2>/dev/null)
target_display() {
  case "$1" in
    *haiku*)  echo "Haiku 4.5" ;;
    *sonnet*) echo "Sonnet 4.6" ;;
    *opus*)   echo "Opus 4.7" ;;
    *)        echo "$1" ;;
  esac
}
TARGET_DISPLAY=$(target_display "$TARGET_ID")
if [ -n "$TARGET_ID" ] && [ "$TARGET_ID" != "$CUR_MODEL_ID_RAW" ]; then
  MODEL_LABEL="$MODEL → $TARGET_DISPLAY"
else
  MODEL_LABEL="$MODEL"
fi

# ---- API vs Subscription mode ----
if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$ANTHROPIC_AUTH_TOKEN" ] || [ -n "$ANTHROPIC_BASE_URL" ]; then
  API_ACTIVE=1
  API_PLAIN="🔑 API Active"
  API_COL="${YELLOW}🔑 API Active${RESET}"
  SUB_PLAIN="📡 Subscription Inactive"
  SUB_COL="${GRAY}📡 Subscription Inactive${RESET}"
else
  API_ACTIVE=0
  API_PLAIN="🔑 API Inactive"
  API_COL="${GRAY}🔑 API Inactive${RESET}"
  SUB_PLAIN="✅ Subscription Active"
  SUB_COL="${GREEN}✅ Subscription Active${RESET}"
fi

# ---- token sums (5h / 7d / all-time) ----
TOK_RAW=$(~/.claude/total_tokens.sh 2>/dev/null)
IFS='|' read -r T_DAY T_WEEK T_TOTAL <<< "$TOK_RAW"
T_DAY=${T_DAY:-0}; T_WEEK=${T_WEEK:-0}; T_TOTAL=${T_TOTAL:-0}
fmt_tok() {
  awk -v n="$1" 'BEGIN{
    if (n>=1e9)      printf "%.1fB", n/1e9
    else if (n>=1e6) printf "%.1fM", n/1e6
    else if (n>=1e3) printf "%.1fK", n/1e3
    else             printf "%d", n
  }'
}
TOK_DAY_F=$(fmt_tok $T_DAY)
TOK_WEEK_F=$(fmt_tok $T_WEEK)

make_bar() {
  local pct=$1
  local f=$(( pct*7/100 )); [ $f -gt 7 ] && f=7; local e=$((7-f))
  printf -v FP "%${f}s" ""; printf -v EP "%${e}s" ""
  echo "${FP// /█}${EP// /░}"
}
bar_color() {
  local p=$1
  if   [ "$p" -ge 90 ]; then echo "$RED"
  elif [ "$p" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}
BAR5=$(make_bar ${RL5_PCT:-0})
BAR7=$(make_bar ${RL7_PCT:-0})
BC5=$(bar_color ${RL5_PCT:-0})
BC7=$(bar_color ${RL7_PCT:-0})

# ---- duration ----
TOTAL_M=$((DURATION_MS/60000))
H=$((TOTAL_M/60)); M=$((TOTAL_M%60))
if [ $H -gt 0 ]; then DUR_STR="${H}h ${M}m"; else DUR_STR="${M}m"; fi

# ---- git ---- (read from cache first for real-time updates)
GIT_CACHE="$HOME/.claude/git_cache.json"
GB=""; GM=0; GAHEAD=0; GBEHIND=0

if [ -f "$GIT_CACHE" ] && [ -s "$GIT_CACHE" ]; then
  # Try to read from cache
  GB=$(jq -r '.branch // ""' "$GIT_CACHE" 2>/dev/null)
  GM=$(jq -r '.modified_files // 0' "$GIT_CACHE" 2>/dev/null)
  GAHEAD=$(jq -r '.ahead // 0' "$GIT_CACHE" 2>/dev/null)
  GBEHIND=$(jq -r '.behind // 0' "$GIT_CACHE" 2>/dev/null)
fi

# Fallback to live git check if cache missing
if [ -z "$GB" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GB=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -z "$GB" ] && GB=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  GM=$(git -C "$DIR" status --porcelain 2>/dev/null | wc -l)
  GAB=$(git -C "$DIR" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
  GAHEAD=0; GBEHIND=0
  if [ -n "$GAB" ]; then
    GBEHIND=$(echo "$GAB" | awk '{print $1}')
    GAHEAD=$(echo "$GAB" | awk '{print $2}')
  fi
fi

if [ -n "$GB" ]; then
  GX=" ±${GM} ↑${GAHEAD} ↓${GBEHIND}"
  # color: ± yellow, ↑ green, ↓ red
  GX_COL=" ${YELLOW}±${GM}${RESET} ${GREEN}↑${GAHEAD}${RESET} ${RED}↓${GBEHIND}${RESET}"
  GB_PLAIN="🌿 ${GB:-?}${GX}"
  GB_COL="${GREEN}🌿 ${GB:-?}${RESET}${GX_COL}"
else
  GB_PLAIN="🌿 —"
  GB_COL="${GRAY}🌿 —${RESET}"
fi

fmt_until() {
  local diff=$(( $1 - $(date +%s) ))
  [ $diff -le 0 ] && { echo "now"; return; }
  local d=$((diff/86400)) h=$(( (diff%86400)/3600 )) mm=$(( (diff%3600)/60 ))
  if   [ $d -gt 0 ]; then printf "%dd %dh" $d $h
  elif [ $h -gt 0 ]; then printf "%dh %dm" $h $mm
  else                    printf "%dm" $mm
  fi
}

# Convert ISO timestamp (or epoch) to "Xh Ym" countdown, or empty.
reset_in() {
  local v=$1
  [ -z "$v" ] && return
  local ep
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    ep=$v
  else
    ep=$(date -d "$v" +%s 2>/dev/null)
  fi
  [ -z "$ep" ] && return
  fmt_until "$ep"
}
RL5_IN=$(reset_in "$RL5")
RL7_IN=$(reset_in "$RL7")

COST=${COST:-0}
COST_FMT=$(printf '$%.2f' "$COST")

# ---- segments: PLAIN  COLORED ----
# each emoji displays as ~2 cols on most terms; we count it as 2
seg_plain=()
seg_color=()
add() { seg_plain+=("$1"); seg_color+=("$2"); }
brk() { seg_plain+=("__BREAK__"); seg_color+=("__BREAK__"); }

add "👤 Created by Yaakov Moseri" "${GRAY}👤 Created by Yaakov Moseri${RESET}"
brk
# show actual current model (from settings.json after auto_select hook)
# + project recommendation for future prompts
if [ -n "$TARGET_DISPLAY" ]; then
  add "[$TARGET_DISPLAY]" "${CYAN}[$TARGET_DISPLAY]${RESET}"
else
  add "[$MODEL]" "${CYAN}[$MODEL]${RESET}"
fi
if [ -n "$THINKING_LABEL" ]; then
  if [ "$EFFORT" = "max" ]; then
    add "$THINKING_LABEL" "${RED}$THINKING_LABEL${RESET}"
  elif [ "$EFFORT" = "xhigh" ]; then
    add "$THINKING_LABEL" "${YELLOW}$THINKING_LABEL${RESET}"
  else
    add "$THINKING_LABEL" "${MAGENTA}$THINKING_LABEL${RESET}"
  fi
fi
[ -n "$VERSION" ] && add "v$VERSION" "${GRAY}v$VERSION${RESET}"
[ -n "$CAVEMAN_LEVEL" ] && add "🦧caveman - $CAVEMAN_LEVEL" "${YELLOW}🦧caveman - $CAVEMAN_LEVEL${RESET}"
add "📁 ${DIR##*/}" "${CYAN}📁 ${DIR##*/}${RESET}"
add "$GB_PLAIN" "$GB_COL"
brk
RL5_TIME=""; RL5_DATE=""
if [ -n "$RL5" ]; then
  RL5_TIME=$(date -d "$RL5" +%H:%M 2>/dev/null)
fi
RL5_IN_DISPLAY=""; RL5_IN_COL=""
[ -n "$RL5_IN" ] && RL5_IN_DISPLAY="⏳${RL5_IN}" && RL5_IN_COL="${GRAY}⏳${RL5_IN}${RESET}"

RL7_DATE_SHORT=""
if [ -n "$RL7" ]; then
  RL7_DATE_SHORT=$(date -d "$RL7" +%d/%m 2>/dev/null)
fi
RL7_IN_DISPLAY=""; RL7_IN_COL=""
[ -n "$RL7_IN" ] && RL7_IN_DISPLAY="⏳${RL7_IN}" && RL7_IN_COL="${GRAY}⏳${RL7_IN}${RESET}"

# add_rr: right-aligned solo line
add_rr() { seg_plain+=("__RR__${1}"); seg_color+=("__RR__${2}"); }

add "5h ${BAR5}${RL5_PCT:-0}% 🪙${TOK_DAY_F} ${RL5_IN_DISPLAY}" "${CYAN}5h${RESET} ${BC5}${BAR5}${BC5}${RL5_PCT:-0}%${RESET} 🪙${TOK_DAY_F} ${RL5_IN_COL}"
brk
add "7d ${BAR7}${RL7_PCT:-0}% 🪙${TOK_WEEK_F} ${RL7_IN_DISPLAY}" "${MAGENTA}7d${RESET} ${BC7}${BAR7}${BC7}${RL7_PCT:-0}%${RESET} 🪙${TOK_WEEK_F} ${RL7_IN_COL}"
if [ "$API_ACTIVE" = "1" ]; then
  add "${COST_FMT} ${API_PLAIN}" "${YELLOW}${COST_FMT}${RESET} ${API_COL}"
else
  add "${SUB_PLAIN}" "${SUB_COL}"
fi
add "⏱️ ${DUR_STR}" "⏱️ ${DUR_STR}"

# ---- recommendation: cache codebase complexity (1h) ----
# Real Claude thinking: Haiku (no thinking) → Sonnet (low/med/high) → Opus (high/xhigh/max)
CACHE_DIR="$HOME/.cache/claude-statusline"
mkdir -p "$CACHE_DIR" 2>/dev/null
HASH=$(echo -n "$DIR" | md5sum 2>/dev/null | cut -c1-8)
HEUR_CACHE="$CACHE_DIR/heur-$HASH"

HC_AGE=9999
[ -f "$HEUR_CACHE" ] && HC_AGE=$(( $(date +%s) - $(stat -c %Y "$HEUR_CACHE" 2>/dev/null || echo 0) ))
if [ $HC_AGE -gt 3600 ]; then
  NF=$(find "$DIR" -maxdepth 6 -type f \( \
    -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' \
    -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.cpp' -o -name '*.c' \
    -o -name '*.rb' -o -name '*.php' -o -name '*.swift' -o -name '*.kt' -o -name '*.sh' \
    -o -name '*.lua' -o -name '*.cs' -o -name '*.scala' -o -name '*.clj' -o -name '*.ex' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/venv/*' \
    -not -path '*/__pycache__/*' -not -path '*/dist/*' -not -path '*/build/*' \
    2>/dev/null | head -3000 | wc -l)
  KB=$(find "$DIR" -maxdepth 6 -type f \( \
    -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' \
    -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.cpp' -o -name '*.c' \
    -o -name '*.rb' -o -name '*.php' -o -name '*.swift' -o -name '*.kt' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/venv/*' \
    -not -path '*/__pycache__/*' -not -path '*/dist/*' -not -path '*/build/*' \
    -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{print int(s/1024)}')
  KB=${KB:-0}
  LANG_COUNT=$(find "$DIR" -maxdepth 4 -type f -name '*.*' \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null \
    | sed 's/.*\.//' | sort -u | head -20 | wc -l)
  HAS_CI=0; HAS_TEST=0; HAS_DOCKER=0; HAS_MONO=0; HAS_TS=0; HAS_INFRA=0; HAS_DB=0; HAS_AI=0
  { [ -d "$DIR/.github/workflows" ] || [ -f "$DIR/.gitlab-ci.yml" ] || [ -f "$DIR/.circleci/config.yml" ]; } && HAS_CI=1
  { [ -d "$DIR/tests" ] || [ -d "$DIR/test" ] || [ -d "$DIR/__tests__" ] || [ -d "$DIR/spec" ]; } && HAS_TEST=1
  { [ -f "$DIR/Dockerfile" ] || [ -f "$DIR/docker-compose.yml" ] || [ -f "$DIR/compose.yaml" ]; } && HAS_DOCKER=1
  { [ -f "$DIR/pnpm-workspace.yaml" ] || [ -f "$DIR/lerna.json" ] || [ -f "$DIR/turbo.json" ] || [ -f "$DIR/rush.json" ]; } && HAS_MONO=1
  [ -f "$DIR/tsconfig.json" ] && HAS_TS=1
  { [ -d "$DIR/terraform" ] || [ -d "$DIR/k8s" ] || [ -d "$DIR/kubernetes" ] || [ -d "$DIR/helm" ]; } && HAS_INFRA=1
  { [ -d "$DIR/migrations" ] || [ -d "$DIR/db" ] || [ -f "$DIR/prisma/schema.prisma" ] || [ -f "$DIR/schema.sql" ]; } && HAS_DB=1
  { grep -qlE "anthropic|openai|langchain|llm" "$DIR"/*.{py,js,ts,json,toml} 2>/dev/null; } && HAS_AI=1

  SCORE=0
  SCORE=$((SCORE + NF))
  SCORE=$((SCORE + KB / 10))
  [ $LANG_COUNT -ge 3 ] && SCORE=$((SCORE + 15))
  [ $LANG_COUNT -ge 5 ] && SCORE=$((SCORE + 15))
  [ $HAS_CI -eq 1 ] && SCORE=$((SCORE + 20))
  [ $HAS_TEST -eq 1 ] && SCORE=$((SCORE + 15))
  [ $HAS_DOCKER -eq 1 ] && SCORE=$((SCORE + 10))
  [ $HAS_MONO -eq 1 ] && SCORE=$((SCORE + 60))
  [ $HAS_TS -eq 1 ] && SCORE=$((SCORE + 10))
  [ $HAS_INFRA -eq 1 ] && SCORE=$((SCORE + 30))
  [ $HAS_DB -eq 1 ] && SCORE=$((SCORE + 15))
  [ $HAS_AI -eq 1 ] && SCORE=$((SCORE + 25))

  if   [ $SCORE -lt 10  ]; then H_MODEL="Haiku 4.5";  H_EFFORT="—";  H_TIER=1
  elif [ $SCORE -lt 50  ]; then H_MODEL="Sonnet 4.6"; H_EFFORT="low"; H_TIER=2
  elif [ $SCORE -lt 120 ]; then H_MODEL="Sonnet 4.6"; H_EFFORT="high"; H_TIER=3
  elif [ $SCORE -lt 180 ]; then H_MODEL="Opus 4.7";   H_EFFORT="high"; H_TIER=4
  elif [ $SCORE -lt 250 ]; then H_MODEL="Opus 4.7";   H_EFFORT="xhigh"; H_TIER=5
  else                          H_MODEL="Opus 4.7";   H_EFFORT="max";  H_TIER=6
  fi
  echo "$H_MODEL|$H_EFFORT|$H_TIER|score=$SCORE" > "$HEUR_CACHE"
fi
IFS='|' read -r REC_MODEL REC_EFFORT REC_TIER REC_REASON < "$HEUR_CACHE" 2>/dev/null

CUR_MODEL_ID=$(j '.model.id // ""')
CUR_TIER=0
case "$CUR_MODEL_ID" in
  *haiku*)  CUR_TIER=1 ;;
  *sonnet*) CUR_TIER=$([[ "$EFFORT" == "high" ]] && echo 3 || echo 2) ;;
  *opus*)   case "$EFFORT" in
              high)  CUR_TIER=4 ;;
              xhigh) CUR_TIER=5 ;;
              max)   CUR_TIER=6 ;;
              *)     CUR_TIER=4 ;;
            esac ;;
esac

# Recommendation display removed per user request
# [ -n "$REC_MODEL" ] && add "💡 rec: $REC_MODEL/$REC_EFFORT" "${REC_COL}💡 rec: $REC_MODEL/$REC_EFFORT${RESET}"

pctcol() {
  local p=$1
  if   [ "$p" -ge 90 ]; then echo "$RED"
  elif [ "$p" -ge 70 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}


# emoji width-adjust: each emoji counts as 2 cols, bash ${#var} counts 1
emoji_extra() {
  local s=$1 n=0 ch
  # count known emoji
  for e in 🧠 📁 🌿 ⏱️ 🔄 🔑 📡 💡 🦧; do
    local t=${s//$e/}
    local diff=$(( (${#s} - ${#t}) / ${#e} ))
    n=$((n + diff))
  done
  echo $n
}

SEP=" | "
SEP_LEN=3
line_plain=""
line_color=""
flush() {
  [ -n "$line_color" ] && echo -e "$line_color"
  line_plain=""
  line_color=""
}

for i in "${!seg_plain[@]}"; do
  p="${seg_plain[$i]}"
  c="${seg_color[$i]}"
  if [ "$p" = "__BREAK__" ]; then
    flush
    continue
  fi
  if [[ "$p" == __RR__* ]]; then
    flush
    rp="${p#__RR__}"; rc="${c#__RR__}"
    pad=$(( COLS - ${#rp} ))
    [ $pad -lt 1 ] && pad=1
    printf -v SP "%${pad}s" ""
    echo -e "${SP}${rc}"
    continue
  fi
  extra=$(emoji_extra "$p")
  plen=$(( ${#p} + extra ))
  if [ -z "$line_plain" ]; then
    line_plain="$p"
    line_color="$c"
  else
    cur_extra=$(emoji_extra "$line_plain")
    cur_len=$(( ${#line_plain} + cur_extra ))
    if [ $((cur_len + SEP_LEN + plen)) -le $COLS ]; then
      line_plain="$line_plain$SEP$p"
      line_color="$line_color ${GRAY}|${RESET} $c"
    else
      flush
      line_plain="$p"
      line_color="$c"
    fi
  fi
done
flush
