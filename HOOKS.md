# Auto-Select Hook

Automatic model and thinking mode selection based on prompt complexity.

## Installation

Copy `auto_select.sh` to `~/.claude/hooks/` and make it executable:

```bash
cp auto_select.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/auto_select.sh
```

## Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/auto_select.sh"
          }
        ]
      }
    ]
  }
}
```

## How It Works

Scores each prompt based on complexity indicators:

### Scoring Factors

- **Length:** +1 per 40 characters
- **Engineering keywords:** +3 each (implement, refactor, architect, design, debug, optimize, build, create, add, fix, migrate, deploy, integrate, analyze, review, benchmark, תקן, תכתוב, בנה, תבנה, תיצור, תממש, תעצב, תכנן, תשפר, תוסיף, תבדוק)
- **Simple keywords:** -3 each (hi, hey, hello, thanks, thank you, ok, yes, no, היי, שלום, תודה, אוקיי)
- **File extensions:** +2 each (.py, .js, .ts, .tsx, .jsx, .go, .rs, .java, .cpp, .c, .rb, .php, .sh, .json, .yaml, .yml, .toml, .md)
- **Code fences:** +5
- **Multi-step markers:** +1 each (then, also, and also, וגם, step N, first, second)

### Complexity Tiers

| Score | Model | Thinking | Purpose |
|-------|-------|----------|---------|
| ≤0 | Haiku 4.5 | low | Trivial (greetings, simple Q&A) |
| 0-2 | Haiku 4.5 | medium | Simple (basic questions) |
| 2-4 | Sonnet 4.6 | low | Moderate (coding, no deep thought) |
| 4-6 | Sonnet 4.6 | medium | Moderate+ (balanced) |
| 6-8 | Sonnet 4.6 | high | Moderate-high (needs deep thinking) |
| 8-10 | Opus 4.7 | low | Complex (preserve token context) |
| 10-12 | Opus 4.7 | medium | Complex (balanced power) |
| 12-14 | Opus 4.7 | high | Very complex (maximum thinking) |
| 14+ | Opus 4.7 | xhigh | Extremely complex (extreme reasoning) |

### Continuity

Once a model/thinking mode is selected, the next prompt starts from that setting. The hook only changes the model if the NEW prompt's complexity differs from the previous selection.

**Example Flow:**
1. Default: Opus 4.7 xhigh
2. User asks "hi" (score -3) → Haiku low
3. Statusline shows: "Haiku 4.5"
4. User asks complex question (score 11) → Opus medium
5. Statusline shows: "Opus 4.7"
6. User asks simple question (score 1) → Haiku medium
7. Continues from Haiku until complexity changes again

## Logging

Hook logs all selections to `~/.claude/hooks/auto_select.log`:

```
2026-04-20T16:13:35+03:00 score=-3 len=2 model=claude-haiku-4-5-20251001 effort=low prompt=hi
2026-04-20T16:13:36+03:00 score=3 len=28 model=claude-sonnet-4-6 effort=medium prompt=implement a function...
```

## Testing

```bash
# Test simple prompt (should select Haiku low)
echo '{"prompt":"hi"}' | bash ~/.claude/hooks/auto_select.sh
jq '.model, .effortLevel' ~/.claude/settings.json

# Test complex prompt (should select Opus xhigh)
echo '{"prompt":"design implement optimize benchmark distributed system. step 1 2 3"}' | bash ~/.claude/hooks/auto_select.sh
jq '.model, .effortLevel' ~/.claude/settings.json
```

## Disabling

Remove from settings.json or rename the hook file:
```bash
mv ~/.claude/hooks/auto_select.sh ~/.claude/hooks/auto_select.sh.disabled
```
