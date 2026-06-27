#!/bin/bash
# Sanbrain: harvest-whatsapp
# Turns the wa-capture daemon's daily message log into files the EXISTING
# pipelines already ingest — no new ingest logic anywhere:
#   - sanbrain:     one allowlisted-chat digest -> raw/whatsapp-DATE.md
#   - taxfreebrain: one file PER TAXBRAIN-ALLOWLISTED CHAT
#                   -> ~/Downloads/whatsapp-<chat>-DATE.md, which taxbrain's
#                   existing gated Downloads watch classifies.
# Per-chat granularity for taxbrain is deliberate: the relevance gate runs per
# file, so personal chats are dropped individually instead of one Tax-Free
# message dragging a whole day of private chatter into the Nico-shared repo.
# Allowlists are the privacy boundary: sanbrain gets its selected private-brain
# chats; taxbrain gets only the Tax-Free subset.
# Captures inbound AND outbound. Sibling of harvest-openclaw; wired in nightly.sh.

source "$(dirname "$0")/lib.sh"
WA_LOG_DIR="$HOME/wa-capture/log"
DL_DIR="$HOME/Downloads"
TODAY=$(date +%Y-%m-%d)
LOG="$SANBRAIN/logs/whatsapp.log"
WA_LOG="$WA_LOG_DIR/${TODAY}.jsonl"
OUTPUT="$VAULT/raw/whatsapp-${TODAY}.md"
ALLOWLIST="$HOME/.sanbrain-whatsapp-allowlist.txt"
TAXBRAIN_ALLOWLIST="$HOME/.taxfreebrain-whatsapp-allowlist.txt"

# ── Pre-flight ──────────────────────────────────────────────────
if [ ! -d "$WA_LOG_DIR" ]; then
  log "=== WhatsApp harvest SKIPPED: $WA_LOG_DIR not found (daemon not set up?) ==="
  echo "WhatsApp harvest: SKIPPED (no wa-capture log dir)"
  heartbeat harvest-whatsapp skip "no wa-capture log dir"; exit 0
fi
if [ ! -s "$WA_LOG" ]; then
  log "No WhatsApp activity for $TODAY (no/empty $WA_LOG)"
  echo "WhatsApp harvest: no activity today"
  heartbeat harvest-whatsapp ok "no activity today"; exit 0
fi
if [ ! -s "$ALLOWLIST" ]; then
  log "WhatsApp harvest skipped: allowlist missing/empty ($ALLOWLIST)"
  echo "WhatsApp harvest: SKIPPED (missing allowlist)"
  heartbeat harvest-whatsapp skip "missing allowlist"; exit 0
fi

log "=== WhatsApp harvest started ==="

# Prune old per-chat drops so ~/Downloads doesn't accumulate (taxbrain's ledger
# dedupes by content-hash anyway, so a lingering copy is never reprocessed).
find "$DL_DIR" -maxdepth 1 -name 'whatsapp-*.md' -mtime +2 -delete 2>/dev/null || true

# ── Build digests via python3 ───────────────────────────────────
# Group by chat, resolve display names, render readable transcripts. Writes the
# per-chat files to Downloads as a side effect; prints the selected-chat digest.
RESULT=$(WA_LOG="$WA_LOG" TODAY="$TODAY" DL_DIR="$DL_DIR" ALLOWLIST="$ALLOWLIST" TAXBRAIN_ALLOWLIST="$TAXBRAIN_ALLOWLIST" python3 -c "
import json, os, re, sys, unicodedata

path=os.environ['WA_LOG']; today=os.environ['TODAY']; dl=os.environ['DL_DIR']
allow_path=os.environ['ALLOWLIST']
tax_allow_path=os.environ['TAXBRAIN_ALLOWLIST']
chats={}; names={}; total=0; skipped=0
KIND={'conversation':'','extendedTextMessage':'','imageMessage':'[image]',
      'videoMessage':'[video]','audioMessage':'[voice note]','documentMessage':'[document]',
      'stickerMessage':'[sticker]','contactMessage':'[contact]','locationMessage':'[location]',
      'pollCreationMessage':'[poll]','reactionMessage':'[reaction]'}

def load_allowlist(path):
    exact=set(); bare=set()
    try:
        lines=open(path, errors='replace')
    except OSError:
        return exact, bare
    with lines:
        for raw in lines:
            item=raw.split('#',1)[0].strip().lower()
            if not item: continue
            if '@' in item: exact.add(item)
            digits=re.sub(r'[^0-9]', '', item.split('@',1)[0])
            if digits: bare.add(digits)
    return exact, bare

allow_exact, allow_bare = load_allowlist(allow_path)
tax_exact, tax_bare = load_allowlist(tax_allow_path)

if not allow_exact and not allow_bare:
    print('NO_ALLOWLIST'); sys.exit(0)

def jid_bare(jid):
    return re.sub(r'[^0-9]', '', jid.split('@',1)[0].split(':',1)[0])
def allowed_by(jid, exact, bare):
    j=(jid or '').lower()
    return j in exact or jid_bare(j) in bare
def number(jid):
    n=jid.split('@',1)[0].split(':',1)[0]
    return '+'+n if n.isdigit() else jid
def slug(s):
    s=unicodedata.normalize('NFKD',s); s=''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'[^A-Za-z0-9]+','-',s).strip('-').lower() or 'chat'

with open(path,errors='replace') as f:
    for line in f:
        line=line.strip()
        if not line: continue
        try: r=json.loads(line)
        except json.JSONDecodeError: continue
        jid=r.get('chat_jid','')
        if not jid: continue
        if not allowed_by(jid, allow_exact, allow_bare):
            skipped+=1
            continue
        chats.setdefault(jid,[]).append(r); total+=1
        if not r.get('from_me') and not r.get('group'):
            nm=(r.get('chat_name') or r.get('sender') or '').strip()
            if nm and not nm.endswith('whatsapp.net') and nm!='me': names[jid]=nm

if not chats:
    print('NO_SELECTED:'+str(skipped)); sys.exit(0)

def label(jid):
    if jid.endswith('@g.us'): return 'Group '+jid.split('@',1)[0][-6:]
    return names.get(jid) or number(jid)

def render(jid):
    out=[]
    for m in sorted(chats[jid], key=lambda r: r.get('ts','')):
        t=m.get('ts',''); hhmm=t[11:16] if len(t)>=16 else ''
        arrow='→' if m.get('from_me') else '←'
        who='me' if m.get('from_me') else (m.get('sender') or label(jid))
        text=(m.get('text') or '').strip()
        tag=KIND.get(m.get('kind',''), '['+m.get('kind','msg')+']')
        body=(tag+(' '+text if text else '')).strip() if tag else text
        if not body: continue
        if len(body)>4000: body=body[:4000]+' …(truncated)'
        out.append((('['+hhmm+'] ') if hhmm else '') + arrow + ' **' + who + '**: ' + body)
    return out

def last_ts(jid): return max((r.get('ts','') for r in chats[jid]), default='')

# Per-chat files -> Downloads (taxbrain gets only its Tax-Free allowlist).
tax_written=0
for jid in chats:
    if not allowed_by(jid, tax_exact, tax_bare):
        continue
    lines=render(jid)
    if not lines: continue
    lab=label(jid)
    with open(os.path.join(dl, 'whatsapp-'+slug(lab)+'-'+today+'.md'),'w') as f:
        f.write('---\nsource: whatsapp (wa-capture)\ndate: '+today+'\nchat: '+jid+'\n---\n\n')
        f.write('# WhatsApp with '+lab+' — '+today+'\n\n')
        if jid.endswith('@g.us'): f.write('*(group · '+jid+')*\n\n')
        f.write('\n'.join(lines)+'\n')
    tax_written+=1

# Selected-chat digest -> stdout (sanbrain raw/).
out=['TOTAL:'+str(total), 'SANBRAIN_CHATS:'+str(len(chats)), 'TAXBRAIN_CHATS:'+str(tax_written), 'SKIPPED:'+str(skipped)]
for jid in sorted(chats, key=last_ts, reverse=True):
    lines=render(jid)
    if not lines: continue
    out.append('\n## '+label(jid))
    if jid.endswith('@g.us'): out.append('*(group · '+jid+')*')
    out.append(''); out.extend(lines); out.append('')
print('\n'.join(out))
" 2>>"$LOG")

# ── Check result ────────────────────────────────────────────────
if [ "$RESULT" = "NO_ALLOWLIST" ]; then
  log "WhatsApp harvest skipped: allowlist parsed empty ($ALLOWLIST)"
  echo "WhatsApp harvest: SKIPPED (empty allowlist)"
  heartbeat harvest-whatsapp skip "empty allowlist"; exit 0
fi
if [[ "$RESULT" == NO_SELECTED:* ]]; then
  SKIPPED_COUNT="${RESULT#NO_SELECTED:}"
  log "No selected WhatsApp activity for $TODAY ($SKIPPED_COUNT non-allowlisted messages ignored)"
  echo "WhatsApp harvest: no selected activity today ($SKIPPED_COUNT ignored)"
  heartbeat harvest-whatsapp ok "no selected activity, $SKIPPED_COUNT ignored"; exit 0
fi
if [ -z "$RESULT" ]; then
  log "No WhatsApp activity parsed for $TODAY"
  echo "WhatsApp harvest: no activity today"
  heartbeat harvest-whatsapp ok "no activity today"; exit 0
fi

MSG_COUNT=$(echo "$RESULT" | head -1 | sed 's/TOTAL://')
SANBRAIN_CHATS=$(echo "$RESULT" | sed -n '2s/SANBRAIN_CHATS://p')
TAXBRAIN_CHATS=$(echo "$RESULT" | sed -n '3s/TAXBRAIN_CHATS://p')
SKIPPED_COUNT=$(echo "$RESULT" | sed -n '4s/SKIPPED://p')
BODY=$(echo "$RESULT" | tail -n +5)

# ── Selected-chat digest to raw/ (sanbrain) ─────────────────────
{
  echo "---"
  echo "type: whatsapp-conversations"
  echo "date: $TODAY"
  echo "source: harvest-whatsapp"
  echo "filter: whatsapp-allowlist"
  echo "auto_process: true"
  echo "---"
  echo ""
  echo "# WhatsApp — $TODAY"
  echo ""
  echo "Selected WhatsApp conversations today ($MSG_COUNT messages across $SANBRAIN_CHATS chats), inbound and outbound."
  echo ""
  echo "Ignored $SKIPPED_COUNT non-allowlisted messages before rendering."
  echo ""
  echo "$BODY"
} > "$OUTPUT"

log "Wrote $OUTPUT ($MSG_COUNT selected messages); $TAXBRAIN_CHATS TaxBrain per-chat files -> Downloads; ignored $SKIPPED_COUNT"
echo "WhatsApp harvest: $MSG_COUNT selected messages ($TAXBRAIN_CHATS TaxBrain chats -> Downloads; $SKIPPED_COUNT ignored)"
heartbeat harvest-whatsapp ok "$MSG_COUNT selected messages, $TAXBRAIN_CHATS taxbrain chats, $SKIPPED_COUNT ignored"
