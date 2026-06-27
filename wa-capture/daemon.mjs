/**
 * wa-capture — WhatsApp linked-device capture daemon.
 *
 * Pairs once (QR or 8-digit code), then runs forever on the Mac mini logging
 * only allowlisted private contacts — inbound and outbound (incl. ones sent from the
 * phone) — to a daily JSONL: log/YYYY-MM-DD.jsonl (America/Mexico_City day).
 *
 * That log is the single shared interface. harvest-whatsapp.sh turns it into
 * files the brains' EXISTING pipelines already ingest:
 *   - sanbrain:      raw/whatsapp-DATE.md (whole day)  -> nightly ingest
 *   - taxfreebrain:  per-chat -> ~/Downloads -> taxbrain's existing gated watch
 *
 * Nothing here leaves the machine. auth_info/ and log/ are local only.
 *
 * Pinned to baileys@6.7.23 (`legacy` stable tag) — the 7.x rc fails to link.
 *
 * Lifecycle rules (learned the hard way):
 *   - NEVER delete auth_info. A paired multi-device session reports
 *     creds.registered=false; the wipe-on-failure heuristic destroyed a good
 *     pairing and crashed saveCreds. The daemon must never wipe its own auth.
 *   - saveCreds is wrapped — a transient FS error must not crash the process.
 *   - Under launchd (no TTY) with no pairing, exit(0) instead of QR-looping.
 *   - loggedOut => exit(0) (no restart loop); everything else => reconnect.
 */
import makeWASocket, { useMultiFileAuthState, fetchLatestBaileysVersion, DisconnectReason } from 'baileys'
import qrTerminal from 'qrcode-terminal'
import QRImage from 'qrcode'
import pino from 'pino'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { exec } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const AUTH_DIR = path.join(__dirname, 'auth_info')
const LOG_DIR = path.join(__dirname, 'log')
const QR_PNG = path.join(__dirname, 'run', 'qr.png')
const ALLOWLIST_PATH = process.env.WA_CAPTURE_ALLOWLIST
  || path.join(os.homedir(), '.sanbrain-whatsapp-allowlist.txt')
fs.mkdirSync(LOG_DIR, { recursive: true })
fs.mkdirSync(path.dirname(QR_PNG), { recursive: true })

const logger = pino({ level: 'silent' })
const interactive = !!process.stdout.isTTY // a human is watching a terminal

const PAIR_NUMBER = (process.env.WA_PAIR_NUMBER || '').replace(/[^0-9]/g, '')
let pairingRequested = false
let qrOpened = false
let reconnecting = false
let allowlistCache = { mtimeMs: -1, exact: new Set(), bare: new Set() }

const say = (...a) => console.log(`[${new Date().toISOString()}]`, ...a)

function scheduleReconnect(ms = 3000) {
  if (reconnecting) return // never stack reconnect loops
  reconnecting = true
  setTimeout(() => { reconnecting = false; start().catch(e => say('reconnect failed:', e?.message)) }, ms)
}

function localDate(date = new Date()) {
  const o = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Mexico_City', year: 'numeric', month: '2-digit', day: '2-digit',
    }).formatToParts(date).map(p => [p.type, p.value]))
  return `${o.year}-${o.month}-${o.day}`
}

function bareId(jid) {
  return String(jid || '').split('@', 1)[0].split(':', 1)[0].replace(/[^0-9]/g, '')
}

function privateContactJid(jid) {
  const normalized = String(jid || '').toLowerCase()
  if (!normalized || normalized === 'status@broadcast' || normalized.endsWith('@g.us')) return false
  if (!normalized.includes('@')) return !!bareId(normalized)
  const domain = normalized.split('@').pop()
  return domain === 's.whatsapp.net' || domain === 'lid'
}

function loadAllowlist() {
  try {
    const st = fs.statSync(ALLOWLIST_PATH)
    if (allowlistCache.mtimeMs === st.mtimeMs) return allowlistCache
    const exact = new Set()
    const bare = new Set()
    for (const raw of fs.readFileSync(ALLOWLIST_PATH, 'utf8').split(/\r?\n/)) {
      const item = raw.split('#', 1)[0].trim().toLowerCase()
      if (!item) continue
      if (!privateContactJid(item)) continue
      if (item.includes('@')) exact.add(item)
      const digits = bareId(item)
      if (digits) bare.add(digits)
    }
    allowlistCache = { mtimeMs: st.mtimeMs, exact, bare }
    say(`allowlist loaded: ${exact.size + bare.size} entries from ${ALLOWLIST_PATH}`)
    return allowlistCache
  } catch (e) {
    allowlistCache = { mtimeMs: -1, exact: new Set(), bare: new Set() }
    return allowlistCache
  }
}

function allowlisted(jid) {
  if (!privateContactJid(jid)) return false
  const list = loadAllowlist()
  if (!list.exact.size && !list.bare.size) return false
  const normalized = String(jid || '').toLowerCase()
  return list.exact.has(normalized) || list.bare.has(bareId(normalized))
}

function extractText(message) {
  if (!message) return ''
  return message.conversation
    || message.extendedTextMessage?.text
    || message.imageMessage?.caption
    || message.videoMessage?.caption
    || message.documentMessage?.caption
    || message.buttonsResponseMessage?.selectedDisplayText
    || message.listResponseMessage?.title
    || (message.ephemeralMessage && extractText(message.ephemeralMessage.message))
    || (message.viewOnceMessage && extractText(message.viewOnceMessage.message))
    || (message.viewOnceMessageV2 && extractText(message.viewOnceMessageV2.message))
    || ''
}

function messageKind(message) {
  let m = message || {}
  if (m.ephemeralMessage) m = m.ephemeralMessage.message || {}
  if (m.viewOnceMessage) m = m.viewOnceMessage.message || {}
  if (m.viewOnceMessageV2) m = m.viewOnceMessageV2.message || {}
  const keys = Object.keys(m).filter(k => k !== 'messageContextInfo')
  return keys[0] || 'unknown'
}

function logMessage(msg) {
  try {
    if (!msg.message) return
    const jid = msg.key?.remoteJid || ''
    if (!allowlisted(jid)) return
    const tsSec = Number(msg.messageTimestamp?.toNumber?.() ?? msg.messageTimestamp ?? 0)
    const when = tsSec ? new Date(tsSec * 1000) : new Date()
    const fromMe = !!msg.key?.fromMe
    const group = jid.endsWith('@g.us')
    const rec = {
      ts: when.toISOString(),
      date: localDate(when),
      chat_jid: jid,
      chat_name: group ? '' : (fromMe ? '' : (msg.pushName || '')),
      from_me: fromMe,
      sender: fromMe ? 'me' : (msg.pushName || msg.key?.participant || jid),
      group,
      participant: msg.key?.participant || '',
      kind: messageKind(msg.message),
      text: extractText(msg.message),
    }
    fs.appendFileSync(path.join(LOG_DIR, `${rec.date}.jsonl`), JSON.stringify(rec) + '\n')
  } catch (e) {
    say('log error:', e?.message)
  }
}

async function start() {
  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR)
  const paired = !!state.creds?.me?.id

  // Under launchd (no terminal) with no pairing, don't loop on an un-scannable
  // QR — exit cleanly. launchd (KeepAlive SuccessfulExit:false) won't restart.
  if (!paired && !interactive && !PAIR_NUMBER) {
    say('no pairing found and no terminal to scan a QR. Pair interactively first:')
    say('  cd ~/wa-capture && node daemon.mjs')
    process.exit(0)
  }

  const { version, isLatest } = await fetchLatestBaileysVersion().catch(() => ({ version: undefined, isLatest: false }))
  if (version) say(`WA Web version ${version.join('.')} (latest=${isLatest})`)

  const sock = makeWASocket({
    version,
    auth: state,
    logger,
    qrTimeout: 60000,
    markOnlineOnConnect: false,
    syncFullHistory: false,
    browser: ['wa-capture', 'Chrome', '1.0.0'],
  })

  // Persisting creds must never crash the daemon.
  sock.ev.on('creds.update', async () => {
    try { await saveCreds() } catch (e) { say('saveCreds error (non-fatal):', e?.message) }
  })

  // Pairing-code path: request ONE code, only when genuinely unpaired.
  if (PAIR_NUMBER && !paired && !pairingRequested) {
    pairingRequested = true
    setTimeout(async () => {
      try {
        const code = await sock.requestPairingCode(PAIR_NUMBER)
        const pretty = code?.match(/.{1,4}/g)?.join('-') || code
        console.log(`\n── WhatsApp -> Settings -> Linked Devices -> Link a Device -> Link with phone number ──`)
        console.log(`── Enter this code NOW (expires in ~60s):  ${pretty}  ──\n`)
      } catch (e) { say('pairing code request failed:', e?.message) }
    }, 3000)
  }

  sock.ev.on('connection.update', (u) => {
    const { connection, lastDisconnect, qr } = u
    if (qr && !PAIR_NUMBER) {
      qrTerminal.generate(qr, { small: true })
      if (interactive) { // only pop a Preview window when a human can scan it
        QRImage.toFile(QR_PNG, qr, { width: 600, margin: 2 })
          .then(() => {
            if (!qrOpened) {
              qrOpened = true
              exec(`open "${QR_PNG}"`)
              say(`clean QR opened in Preview — scan from INSIDE WhatsApp > Linked Devices (not the Camera app)`)
            }
          })
          .catch(e => say('QR png error:', e?.message))
      }
    }
    if (connection === 'open') say('connection OPEN — capturing allowlisted private contacts inbound + outbound')
    if (connection === 'close') {
      const code = lastDisconnect?.error?.output?.statusCode
      if (code === DisconnectReason.loggedOut) {
        // WhatsApp invalidated the session. Do NOT wipe (leave creds for
        // inspection) and do NOT loop — exit so a human re-pairs deliberately.
        say('LOGGED OUT by WhatsApp. Re-pair: `rm -rf auth_info && node daemon.mjs`. Exiting.')
        process.exit(0)
      }
      // restartRequired (normal after connect), connectionLost, timedOut,
      // connectionReplaced, etc. — just reconnect. NEVER delete auth_info.
      say(`connection closed (code=${code}) — reconnecting`)
      scheduleReconnect(code === DisconnectReason.restartRequired ? 1000 : 3000)
    }
  })

  sock.ev.on('messages.upsert', ({ messages, type }) => {
    if (type !== 'notify') return
    for (const m of messages) logMessage(m)
  })
}

say(`wa-capture starting… (${interactive ? 'interactive' : 'launchd/non-tty'}; allowlist=${ALLOWLIST_PATH})`)
start().catch(e => { console.error('fatal:', e); process.exit(1) })
