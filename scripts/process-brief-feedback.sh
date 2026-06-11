#!/bin/bash
# Sanbrain: process brief feedback (written edits + voice recordings)
#
# Santiago reads the brief on his desktop each morning. Feedback arrives two ways:
#   1. Written: checked boxes, inline comments, free text in the brief file.
#   2. Voice: ⌘⇧R (Obsidian audio recorder) — he talks while reading; the
#      recording embeds into the note (`![[Recording ....webm]]`).
#
# Trigger: launchd (com.sanbrain.brief-watcher) — WatchPaths on wiki/daily/
# fires within seconds of any save, plus a 30-min StartInterval backstop.
# See scripts/install-launchd.sh. NOT cron.
#
# TCC REALITY (tested 2026-06-10): launchd-spawned bash/python are DENIED
# vault CONTENT reads ("Operation not permitted") — only stat/metadata works.
# The claude binary and its children ARE allowed. Therefore this wrapper only
# gates (stat), locks, and notifies; ALL content work — reading the brief,
# Whisper transcription (via transcribe-brief-audio.sh), propagation, writing
# Respuestas — happens inside the claude run.
#
# Feedback contract (Santiago must always know what the system did):
#   - recording transcribed   → 🎙️ Telegram ping (from transcribe-brief-audio.sh)
#   - feedback propagated     → 📝 Telegram ping with claude's summary
#   - run failed              → ⚠️ Telegram ping with the log path
#   - persistent breakage     → daily notify_once (API key, stat denied)
#   - every poll              → heartbeat (ok/skip/error) for vault-doctor + brief-status.sh

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/brief-feedback.log"
TODAY=$(date +%Y-%m-%d)
BRIEF="${BRIEF_OVERRIDE:-$VAULT/wiki/daily/${TODAY}-brief.md}"
SUMMARY="$STATE_DIR/brief-feedback-summary.txt"
PENDING="$STATE_DIR/brief-feedback.pending"
LOCKFILE="$SANBRAIN/logs/.brief-feedback.pid"

# Only run if today's brief exists ([ -f ] is metadata — works under launchd)
[ -f "$BRIEF" ] || exit 0

# ── Single-instance lock ────────────────────────────────────────
# A claude run takes minutes; WatchPaths keeps firing meanwhile (his edits,
# our own Respuestas write). A concurrent fire leaves a pending flag and the
# running instance loops once more when it finishes — no event is lost.
if [ -f "$LOCKFILE" ]; then
  old_pid=$(cat "$LOCKFILE" 2>/dev/null)
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    touch "$PENDING"
    log "busy (PID $old_pid) — left pending flag"
    exit 0
  fi
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")

pass=1
while [ "$pass" -le 3 ]; do
  # ── Change gate (stat = metadata, allowed under launchd) ──────
  brief_mtime=$(stat -f %m "$BRIEF" 2>/dev/null || stat -c %Y "$BRIEF" 2>/dev/null)
  if [ -z "$brief_mtime" ]; then
    heartbeat brief-feedback error "stat failed on brief"
    notify_once stat-denied "⚠️ sanbrain: el watcher no puede ni hacer stat del brief — revisa permisos de disco (brief-status.sh)."
    exit 1
  fi
  last_processed=$(state_get brief-feedback.mtime)
  queued=$(ls "$STATE_DIR/brief-voice-queue" 2>/dev/null | head -1)
  if [ -n "$last_processed" ] && [ "$brief_mtime" = "$last_processed" ] && [ -z "$queued" ]; then
    heartbeat brief-feedback skip "no changes (mtime $brief_mtime)"
    break
  fi

  if ! claude_ok; then
    heartbeat brief-feedback error "claude not logged in"
    notify_once claude-auth "⚠️ sanbrain: claude CLI sin autenticar — el feedback del brief no se está procesando. Corre 'claude login' en Terminal."
    exit 1
  fi

  log "processing pass $pass (mtime $brief_mtime, last $last_processed)"
  rm -f "$SUMMARY"

  "$CLAUDE" -p "You are processing Santiago's feedback on today's morning brief.
The Obsidian vault is at: $VAULT
Today's brief file is: $BRIEF

IMPORTANT — file access: this prompt runs under launchd, where the calling
bash could NOT read the brief's content (macOS TCC). YOU can. Read all vault
files with your own tools; helper scripts must run via your Bash tool.

# Project Context
$CONTEXT

---

## Your Task

**Step 0 — transcribe voice feedback.** Run via your Bash tool:
\`bash $SANBRAIN/scripts/transcribe-brief-audio.sh\`
It prints Whisper transcripts of any new recordings (or '[no new recordings]'):
- \`### Recording: ...\` — recorded inside the brief note (always brief feedback)
- \`### Voice memo (global recording): ...\` — recorded anywhere via the ⌘⇧R
  global hotkey. May be brief feedback OR an unrelated memo (a meeting, an
  idea, a note-to-self). Route by content: if it responds to the brief's
  questions/items, process as feedback; if unrelated, do NOTHING with it —
  it is already delivered to raw/ and tonight's ingest handles it.
It handles caching, retries, and its own Telegram pings — just capture stdout.

**Step 1 — read the brief.** Read $BRIEF with your Read tool.

**Step 2 — process all feedback** (written edits + transcripts):

1. **Checked items** (\`- [x]\`, including \`> - [x]\` inside callouts): resolved.
   Update the relevant entity or context page if the resolution changes
   compiled truth.

2. **Added comments/text**: new information. If it contains decisions, entity
   updates, or context, propagate to the appropriate wiki page.

3. **Voice transcripts**: Santiago talks while reading, usually Spanish,
   English, or both mixed. He may:
   - Answer the numbered questions (\"Q1 sí... la dos...\"). Match by number or
     content. For each answered question: check its box in the brief
     (\`> - [x] **Q1.** ...\`) and add his answer in one indented line below it.
   - Ask his own questions. Answer them from vault knowledge in Respuestas —
     direct, compressed, cite [[pages]].
   - Give updates, decisions, plans. Propagate like written feedback.
   Names may be mis-transcribed — match phonetically against known entities
   before creating anything new.

4. **Respuestas**: Append a \`### HH:MM\` block under a \`## Respuestas\` section
   at the END of the brief (create the section once, never duplicate it):
   (a) answers to questions Santiago asked, (b) one line per propagation made.
   If a transcript was already answered in Respuestas (crash recovery), do not
   duplicate — just proceed to Step 3.

5. **Today's Plan entries**: if Santiago said or wrote what he's doing today,
   create timeline entries in the relevant entity pages.

**Step 3 — close the loop (REQUIRED, even when there was nothing to do):**
- If Step 0 printed ANY transcript (brief feedback, unrelated global memo, or
  already-answered), run:
  \`bash $SANBRAIN/scripts/transcribe-brief-audio.sh --mark-processed\`
  This also consumes the global-memo queue — skipping it would re-feed the
  same memos on every run.
- If you made ANY change (propagation, checked boxes, Respuestas): write a
  1-5 line plain-text summary of what you did — answers given, pages updated —
  to $SUMMARY (overwrite). This text is sent to Santiago on Telegram verbatim:
  write it to him, in his Spanish/English mix, no markdown links.
- If there was genuinely nothing to process: do NOT create $SUMMARY, do NOT
  write to any page, do NOT log. Silence is the correct output for no input.

## Rules
- Log all changes to $VAULT/log.md: \`- YYYY-MM-DDTHH:MM:SS [brief-feedback] action\`
- Use [[wikilinks]] for entity/concept/project references
- Only update pages where Santiago's input provides NEW information
- Do not rewrite context files (context-maintain's job) — only entity timelines and compiled truth
- Never modify audio embed lines (\`![[Recording ...]]\`) or regenerate brief sections — only check boxes, add answer lines, append to Respuestas
- Be surgical: small targeted updates, not rewrites" >> "$LOG" 2>&1
  CLAUDE_RC=$?

  if [ $CLAUDE_RC -ne 0 ]; then
    heartbeat brief-feedback error "claude run failed (rc=$CLAUDE_RC)"
    notify "⚠️ sanbrain: el procesamiento del feedback del brief FALLÓ (rc=$CLAUDE_RC). Log: ~/sanbrain/logs/brief-feedback.log"
    exit 1   # mtime not stored — next fire or the 30-min backstop retries
  fi

  # Store POST-run mtime: claude's own writes (Respuestas, checked boxes) must
  # not retrigger the gate. Edits Santiago makes DURING the run are picked up
  # on his next save (new fire) or by tomorrow's Phase 0.5 — never lost.
  new_mtime=$(stat -f %m "$BRIEF" 2>/dev/null || stat -c %Y "$BRIEF" 2>/dev/null)
  state_set brief-feedback.mtime "${new_mtime:-$brief_mtime}"

  [ -x "$SANBRAIN/scripts/vault-git.sh" ] && \
    "$SANBRAIN/scripts/vault-git.sh" checkpoint "post-brief-feedback" >> "$LOG" 2>&1

  if [ -s "$SUMMARY" ]; then
    notify "📝 sanbrain — feedback procesado:
$(head -c 800 "$SUMMARY")"
    heartbeat brief-feedback ok "processed; summary sent"
  else
    heartbeat brief-feedback ok "ran; nothing to process"
  fi
  log "pass $pass done (rc=0, summary: $([ -s "$SUMMARY" ] && echo yes || echo no))"

  # A fire arrived while we were running? Go around once more.
  if [ -f "$PENDING" ]; then
    rm -f "$PENDING"
    pass=$((pass + 1))
    continue
  fi
  break
done

exit 0
