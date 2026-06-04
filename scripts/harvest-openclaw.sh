#!/bin/bash
# Sanbrain: harvest-openclaw
# Reads today's OpenClaw conversations directly from session .jsonl files
# across all agents, extracts user/assistant exchanges, and writes a
# consolidated digest to raw/ for the ingest skill.
#
# Session structure:
#   ~/.openclaw/agents/{agent}/sessions/{uuid}.jsonl  — current conversation
#   ~/.openclaw/agents/{agent}/sessions/{uuid}.jsonl.reset.{ISO_DATE}  — compacted snapshots
#   Messages have ISO 8601 timestamps — we filter by today's date.
#
# Called by nightly.sh before the 4-skill chain.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
OPENCLAW_DIR="$HOME/.openclaw/agents"
TODAY=$(date +%Y-%m-%d)
LOG="$SANBRAIN/logs/openclaw.log"
OUTPUT="$VAULT/raw/openclaw-conversations-${TODAY}.md"

ts() { date +%Y-%m-%dT%H:%M:%S; }
log() { echo "$(ts) $1" >> "$LOG"; }

# ── Pre-flight ──────────────────────────────────────────────────
if [ ! -d "$OPENCLAW_DIR" ]; then
  log "=== OpenClaw harvest SKIPPED: $OPENCLAW_DIR not found ==="
  echo "OpenClaw harvest: SKIPPED (no .openclaw dir)"
  exit 0
fi

log "=== OpenClaw harvest started ==="

# ── Extract today's conversations via python3 ───────────────────
# Reads all .jsonl files (current + reset snapshots with today's date),
# filters messages timestamped today, groups by agent+channel.

RESULT=$(python3 -c "
import json, os, sys, glob
from datetime import datetime

today = '${TODAY}'
agents_dir = '${OPENCLAW_DIR}'
conversations = {}  # key: 'agent:channel' -> list of messages

def extract_messages(filepath, agent_name):
    \"\"\"Read a .jsonl file and yield today's user/assistant text messages.\"\"\"
    try:
        with open(filepath, 'r', errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if obj.get('type') != 'message':
                    continue

                ts = obj.get('timestamp', '')
                if not ts.startswith(today):
                    continue

                msg = obj.get('message', {})
                role = msg.get('role', '')
                if role not in ('user', 'assistant'):
                    continue

                # Extract text content
                content = msg.get('content', '')
                text_parts = []
                if isinstance(content, str):
                    text_parts.append(content)
                elif isinstance(content, list):
                    for part in content:
                        if isinstance(part, dict):
                            if part.get('type') == 'text':
                                text_parts.append(part.get('text', ''))
                            elif part.get('type') == 'toolCall' and part.get('name') == 'message':
                                # OpenClaw sends messages via tool calls
                                args = part.get('arguments', part.get('input', {}))
                                if isinstance(args, dict) and 'message' in args:
                                    text_parts.append(args['message'])

                text = '\n'.join(t for t in text_parts if t).strip()
                if not text:
                    continue

                # Determine channel from message metadata
                channel = msg.get('sourceChannel', 'cli')
                sender = msg.get('senderName', '')

                time_str = ts[11:16] if len(ts) > 16 else ''

                yield {
                    'time': time_str,
                    'role': role,
                    'sender': sender,
                    'text': text,
                    'channel': channel,
                }
    except Exception as e:
        print(f'  (error reading {os.path.basename(filepath)}: {e})', file=sys.stderr)

total_messages = 0

for agent_dir in sorted(glob.glob(os.path.join(agents_dir, '*', 'sessions'))):
    agent_name = os.path.basename(os.path.dirname(agent_dir))

    # Current session files
    session_files = glob.glob(os.path.join(agent_dir, '*.jsonl'))
    # Reset files that might contain today's messages (reset timestamp is today or later)
    reset_files = glob.glob(os.path.join(agent_dir, '*.jsonl.reset.*'))
    today_resets = [f for f in reset_files if today in f]

    all_files = session_files + today_resets

    for filepath in all_files:
        for msg in extract_messages(filepath, agent_name):
            key = f'{agent_name}:{msg[\"channel\"]}'
            if key not in conversations:
                conversations[key] = []
            conversations[key].append(msg)
            total_messages += 1

# Sort each conversation by time
for key in conversations:
    conversations[key].sort(key=lambda m: m['time'])

# Output as structured text
if not conversations:
    print('NO_ACTIVITY')
    sys.exit(0)

print(f'TOTAL:{total_messages}')
for key in sorted(conversations.keys()):
    msgs = conversations[key]
    agent, channel = key.split(':', 1)
    print(f'\\n## {agent} ({channel})')
    print()
    for m in msgs:
        prefix = f'**{m[\"sender\"]}**' if m['sender'] else f'**{m[\"role\"]}**'
        time_tag = f'[{m[\"time\"]}] ' if m['time'] else ''
        # Truncate very long messages (tool outputs etc)
        text = m['text']
        if len(text) > 2000:
            text = text[:2000] + '\\n\\n*(truncated)*'
        print(f'{time_tag}{prefix}: {text}')
        print()
" 2>>"$LOG")

# ── Check result ────────────────────────────────────────────────
if [ "$RESULT" = "NO_ACTIVITY" ] || [ -z "$RESULT" ]; then
  log "No OpenClaw activity for $TODAY"
  echo "OpenClaw harvest: no activity today"
  exit 0
fi

# Extract message count from first line
MSG_COUNT=$(echo "$RESULT" | head -1 | sed 's/TOTAL://')
BODY=$(echo "$RESULT" | tail -n +2)

# ── Write frontmattered markdown to raw/ ────────────────────────
{
  echo "---"
  echo "type: openclaw-conversations"
  echo "date: $TODAY"
  echo "source: harvest-openclaw"
  echo "auto_process: true"
  echo "---"
  echo ""
  echo "# OpenClaw Conversations — $TODAY"
  echo ""
  echo "All conversations across OpenClaw agents today ($MSG_COUNT messages)."
  echo ""
  echo "$BODY"
} > "$OUTPUT"

log "Wrote $OUTPUT ($MSG_COUNT messages)"
echo "OpenClaw harvest: $MSG_COUNT messages written to raw/"
