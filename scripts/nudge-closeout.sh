#!/bin/bash
# Sanbrain: nudge-closeout
# 9:30 PM Telegram nudge — the chat windows (ChatGPT, Claude.ai, Grok) are
# Santiago's primary input channel and can only be captured via the "wiki this"
# summary habit. This makes the habit time-bound: summaries pasted now land in
# tonight's 10 PM ingest instead of evaporating.
# Schedule: 9:30 PM daily (30 min before nightly).

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/reminders.log"

notify "🧠 Nightly run in 30 min. Cierre del día:
- Sesiones de ChatGPT/Claude/Grok que valieron la pena → 'wiki this' y pega el resumen aquí
- Notas sueltas → VAULT/raw/
- Audios de hoy → iCloud/Meetings/"

heartbeat nudge-closeout ok "sent"
log "Close-out nudge sent"
