#!/bin/bash
# Sanbrain: evening-debrief
# Cron-driven elicitation: asks Santiago about the day to extract decisions
# and ideas that never made it into any captured channel — the thoughts that
# only exist in his head. He replies in the sanbrain Telegram topic; that
# conversation is captured verbatim by harvest-openclaw (window includes
# late-evening messages) and ingested. sanbrain-admin may ask ONE follow-up
# (see openclaw/AGENTS.md workflow 5).
#
# Replies before 10 PM land in tonight's ingest; later replies land tomorrow.
# Schedule: 9:30 PM daily (30 min before nightly).

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/reminders.log"

notify "🧠 Cierre del día — contesta aquí mismo, queda capturado:

1. ¿Qué decidiste o construiste hoy?
2. ¿Alguna idea que valga la pena guardar? (negocio, producto, personal)
3. ¿Qué quedó abierto o trabado?

Además: sesiones de ChatGPT/Claude/Grok → 'wiki this' y pega los resúmenes aquí. Audios → iCloud/Meetings. Notas → VAULT/raw."

heartbeat evening-debrief ok "sent"
log "Evening debrief sent"
