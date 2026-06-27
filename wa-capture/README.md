# wa-capture

Tracked source lives here in `~/sanbrain/wa-capture`. Runtime state lives in
`~/wa-capture` and must stay local: `auth_info/`, `log/`, `run/`, and
`node_modules/` are not source of truth.

Local WhatsApp **linked-device** capture daemon for the Mac mini. Logs inbound +
outbound messages only for chats selected in `~/.sanbrain-whatsapp-allowlist.txt`
to a daily JSONL. Non-allowlisted chats are ignored before writing.

## Pair (one time)

```bash
cd ~/sanbrain/wa-capture
npm install
./install-launchd.sh
cd ~/wa-capture
node daemon.mjs          # first pairing only: scan QR in WhatsApp -> Linked Devices
```

After "connection OPEN", send yourself a test message and check:

```bash
tail -f log/$(TZ=America/Mexico_City date +%F).jsonl
```

`install-launchd.sh` copies tracked source into `~/wa-capture`, installs deps
there, and loads the launchd job.

## What it does / doesn't

- Captures **text + captions + message type** only for allowlisted chats, both directions.
- Does **not** download media, mark you online, or steal notifications
  (`markOnlineOnConnect: false`).
- `auth_info/` (the linked-device session) and `log/` never leave this machine —
  not a git repo, gitignored defensively.

## Consumers

Both brains use their **existing** ingest — this project only drops files where
they already look:

| Brain | Lands in | Picked up by | Filter |
|---|---|---|---|
| sanbrain | `VAULT/raw/whatsapp-DATE.md` (selected chats only) | nightly `ingest` (22:00) | `~/.sanbrain-whatsapp-allowlist.txt` |
| taxfreebrain | `~/Downloads/whatsapp-<chat>-DATE.md` (Tax-Free selected chats only) | existing `com.taxfreebrain.watch` (every 20 min) | `~/.taxfreebrain-whatsapp-allowlist.txt`, then relevance gate |

`harvest-whatsapp.sh` (wired into sanbrain's `nightly.sh`) is the only mover: it
reads the daemon's JSONL and writes those files. Per-chat for taxbrain so the
relevance gate sees one allowed chat at a time, never the whole day at once.

## Re-pair

If WhatsApp drops the linked device: `rm -rf auth_info && node daemon.mjs`.
