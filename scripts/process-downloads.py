#!/usr/bin/env python3
"""Sanbrain: Downloads as a true working directory — deterministic lifecycle.

Replaces the old approve-then-permanently-delete flow. No checkbox ritual, no
irreversible `os.remove`. Santiago saves/downloads/processes; this clears the
residue the only safe way, and the default is fail-safe: when in doubt, SAVE.

The rule, in Santiago's own frame — never lose a one-way door:

  An idle file leaves Downloads only by a recoverable path:
    * VERIFIED SAVED   — a verbatim copy is recorded in the provenance ledger
                         (or found in the vault) -> trash (macOS Trash, ~30d).
    * DISPOSABLE        — a POSITIVE allowlist of cheap/re-acquirable types
                         (images, installers, archives, media) -> trash on idle.
    * EVERYTHING ELSE   — treated as VALUABLE. Never idle-trashed unsaved.
                         When idle, it is PROMOTED (verbatim copy into the vault:
                         raw/legal/ for fiscal-legal names, raw/needs-review/
                         otherwise), the fresh copy is hash-verified, recorded,
                         and only THEN is the desk original trashed.

  The danger direction — destroying an unsaved file — requires a POSITIVE
  disposable match. A document the classifier doesn't recognize is saved, not
  destroyed. Crypto material (.cer/.key/.pem/... or fiel/csd/llave names) is
  never touched. Fresh files (idle < threshold) always stay — it's a working
  directory. Directories, symlinks, partial downloads, and iCloud-evicted
  (dataless) files are never auto-trashed.

Why a LOCAL provenance ledger and not the vault index: under launchd, plain
python cannot read pre-existing iCloud-vault content (TCC) — but it CAN write
into the vault and read back its own writes, and it can always read
~/sanbrain/.state. So "saved" is judged from the local ledger (populated by
harvest for .md/.txt, by promote() here, and by `--reconcile` for the backlog).
The vault hash index is a best-effort bonus when run with Full Disk Access.

Every move/promote is logged to the Obsidian-visible audit ledger
(wiki/logs/downloads-trash-YYYY-MM.md) and a machine state summary the brief reads.

Usage:
  process-downloads.py [--downloads DIR] [--vault DIR] [--state DIR] [--log FILE]
                       [--idle-days N] [--max-mb N] [--dry-run] [--json]
  process-downloads.py --reconcile     # seed provenance ledger from vault copies
                                       # (run once from an FDA Terminal at deploy)
"""
import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

EMPTY_SHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
UF_DATALESS = 0x40000000  # macOS: iCloud-evicted placeholder (sys/stat.h)

# ── Classification ────────────────────────────────────────────────
# Crypto material: never touched. Over-broad on purpose — a benign file kept on
# the desk costs nothing; a lost FIEL/CSD key is catastrophic.
KEY_EXTS = (".cer", ".key", ".p12", ".pfx", ".pem", ".req", ".csr", ".crt",
            ".der", ".jks", ".keystore", ".asc", ".gpg", ".kdbx")
CRYPTO_NAME_RE = re.compile(
    r"\bfiel\b|\bcsd\b|\bllave\b|sello digital|private[- ]?key|clave privada|\bprivada\b",
    re.IGNORECASE)

# .md/.txt are harvest-downloads.sh's domain (it copies them to raw/ for ingest).
# The engine never promotes them — it waits until they're verified-saved, then trashes.
HARVESTABLE_EXTS = (".md", ".txt")

# Partial / in-progress downloads: noise. harvest deletes them; we never act on them.
PARTIAL_EXTS = (".part", ".crdownload", ".download", ".partial", ".tmp", ".!ut")

# One-way doors: irreplaceable documents. Never idle-aged; promoted to raw/legal/
# if unsaved, then trashed once a verified copy exists. Matched against a basename
# normalized so '_' / '-' / '.' / digits become spaces — so `\b` is reliable and
# `acta_constitutiva_2024.pdf` matches `acta`.
ONE_WAY_PATTERNS = [
    # SAT / Mexican fiscal
    r"factura", r"cfdi", r"acuse", r"\bcsf\b", r"constancia", r"\bsat\b",
    r"declarac", r"complemento", r"retenc", r"\brfc\b", r"comprobante",
    r"nomina", r"recibo", r"deducc", r"\bppd\b", r"\bpue\b",
    # Legal
    r"contrat", r"contract", r"convenio", r"acuerdo", r"\bnda\b", r"agreement",
    r"escritura", r"\bpoder\b", r"\bacta\b", r"\blegal\b", r"amparo", r"demanda",
    r"pagar", r"titulo", r"cedula", r"testamento", r"fianza", r"fideicomiso",
    r"estatutos", r"clausula", r"\bsafe\b", r"term sheet", r"\bdeed\b", r"\blease\b",
    r"arrendamiento", r"predial",
    # Identity / travel — judge flagged "untouched != don't need"
    r"visa", r"pasaporte", r"passport", r"boarding", r"\bine\b", r"\bcurp\b",
    r"licencia", r"identificacion", r"apostille", r"\bi 94\b", r"nacimiento",
    # Financial
    r"estado de cuenta", r"statement", r"\bbanco\b", r"\bbank\b", r"\bw 2\b",
    r"\bw 9\b", r"\b1099\b", r"cheque", r"\bcheck\b", r"transferencia",
    r"deposito", r"\bspei\b", r"comprobante de pago",
]
ONE_WAY_RE = re.compile("|".join(ONE_WAY_PATTERNS), re.IGNORECASE)

# Disposable: cheap to lose / re-acquirable. The ONLY class trashed unsaved on idle.
DISPOSABLE_EXTS = (
    ".png", ".jpg", ".jpeg", ".heic", ".heif", ".webp", ".gif", ".bmp", ".tif",
    ".tiff", ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm", ".mp3", ".wav",
    ".aac", ".ogg", ".flac", ".dmg", ".pkg", ".iso", ".app", ".zip", ".tar",
    ".gz", ".tgz", ".bz2", ".rar", ".7z", ".xz",
)
DISPOSABLE_NAME_RE = re.compile(
    r"screenshot|screen shot|captura de pantalla|simulator screen|screen recording|\bimg \d",
    re.IGNORECASE)


def normalize(name):
    return " " + re.sub(r"[^a-z0-9]+", " ", name.lower()).strip() + " "


def classify(name):
    base = name.rstrip("/")
    ext = os.path.splitext(base)[1].lower()
    norm = normalize(base)
    if ext in KEY_EXTS or CRYPTO_NAME_RE.search(norm):
        return "key"
    if ext in HARVESTABLE_EXTS and not ONE_WAY_RE.search(norm):
        return "harvestable"
    if ONE_WAY_RE.search(norm):
        return "oneway"
    if ext in DISPOSABLE_EXTS or DISPOSABLE_NAME_RE.search(norm):
        return "disposable"
    return "valuable"


def is_partial(name):
    return os.path.splitext(name)[1].lower() in PARTIAL_EXTS


# ── LLM triage proposal (UNTRUSTED advisory input) ──────────────────
# An optional `claude -p` stage (skills/downloads-triage) reads Downloads + the
# vault and proposes a per-file recommendation. It NEVER touches files. We treat
# its output as untrusted: validated here, and the engine only ever acts on real
# directory entries (a hallucinated filename in the proposal can never trigger
# anything), with every recommendation CLAMPED so the model can only make a file
# safer — never less protected.
ALLOWED_RECS = {"keep", "disposable", "save-review", "save-legal", "crypto"}


def load_proposal(path, log):
    """Return {filename: recommendation} from a fresh, valid proposal, else {}."""
    if not path or not os.path.isfile(path):
        return {}
    try:
        data = json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError) as e:
        log(f"PROPOSAL-IGNORED (unreadable/invalid JSON: {e})")
        return {}
    gen = str(data.get("generated", ""))[:10]
    today = dt.date.today().isoformat()
    if gen != today:
        log(f"PROPOSAL-IGNORED (stale: generated {gen!r} != today {today})")
        return {}
    out = {}
    for it in data.get("files", []):
        if isinstance(it, dict) and isinstance(it.get("name"), str) \
                and it.get("recommendation") in ALLOWED_RECS:
            out[it["name"]] = it["recommendation"]
    log(f"proposal: {len(out)} valid recommendations loaded")
    return out


def resolve_kind(det_kind, rec):
    """Clamp an LLM recommendation against the deterministic kind. The model may
    only make a file SAFER (more protected). It may downgrade to 'disposable'
    ONLY a genuinely-ambiguous 'valuable' file; crypto and pattern-matched
    one-way docs can never be downgraded. Returns (effective_kind, force_keep)."""
    if det_kind == "key":
        return "key", False                       # crypto floor — immovable
    if rec is None:
        return det_kind, False
    if rec == "crypto":
        return "key", False                       # model caught a key we missed
    if rec == "keep":
        return det_kind, True                     # don't clear even if idle
    if det_kind == "oneway":
        return "oneway", False                    # legal floor — no downgrade
    if det_kind == "harvestable":
        return ("oneway", False) if rec == "save-legal" else ("harvestable", False)
    if det_kind == "disposable":
        if rec == "save-legal":
            return "oneway", False
        if rec == "save-review":
            return "valuable", False
        return "disposable", False
    # det_kind == "valuable" — the ambiguous bucket; the model has latitude here
    if rec == "save-legal":
        return "oneway", False
    if rec == "disposable":
        return "disposable", False                # the one permitted downgrade
    return "valuable", False                       # save-review / unknown -> save


# ── Filesystem helpers ────────────────────────────────────────────
def ts():
    return dt.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")


def is_dataless(st):
    return bool(getattr(st, "st_flags", 0) & UF_DATALESS)


def sha256_file(path, max_bytes):
    """sha256 of a real local file, else None ("not usable as proof of a save").

    None for: non-files, 0-byte files (emptiness is never proof of anything),
    dataless/evicted placeholders, .icloud stubs, over-cap files, read errors.
    """
    try:
        st = os.stat(path)
    except OSError:
        return None
    if not os.path.isfile(path) or st.st_size == 0 or is_dataless(st):
        return None
    if path.endswith(".icloud"):
        return None
    if max_bytes and st.st_size > max_bytes:
        return None
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
    except OSError:
        return None
    digest = h.hexdigest()
    return None if digest == EMPTY_SHA256 else digest


# ── Provenance ledger (LOCAL — always readable, even under launchd) ──
def load_provenance(state_dir):
    path = os.path.join(state_dir, "downloads-provenance.jsonl")
    hashes = set()
    if os.path.isfile(path):
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                sh = rec.get("source_sha256")
                if sh:
                    hashes.add(sh)
    return hashes, path


def record_provenance(prov_path, rec, dry_run):
    if dry_run:
        return
    os.makedirs(os.path.dirname(prov_path), exist_ok=True)
    with open(prov_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


# ── Best-effort vault index (only when this process has FDA) ─────────
def build_vault_hash_index(vault, max_bytes, log):
    """Hash verbatim-copy stores in the vault. Best-effort: under launchd this
    process lacks FDA and reads fail — we make that LOUD (not silent) and return
    a `denied` flag so the caller can warn instead of pretending all is well.
    """
    index = set()
    denied = {"hit": False}

    def on_err(e):
        denied["hit"] = True
        log(f"VAULT-READ-DENIED (FDA?) {e}")

    for sub in ("raw", "raw/archive", "raw/legal", "raw/needs-review",
                "books-pdf", "attachments"):
        root = os.path.join(vault, sub)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root, onerror=on_err):
            for fn in files:
                if fn.startswith("."):
                    continue
                digest = sha256_file(os.path.join(dirpath, fn), max_bytes)
                if digest:
                    index.add(digest)
    log(f"vault hash index: {len(index)} copies"
        + (" [READS DENIED — relying on provenance ledger]" if denied["hit"] else ""))
    return index, denied["hit"]


# ── Audit ledger (Obsidian-visible) ─────────────────────────────────
def audit_path(vault):
    return os.path.join(vault, "wiki", "logs",
                        f"downloads-trash-{dt.date.today().strftime('%Y-%m')}.md")


def append_audit(vault, line, dry_run, log):
    if dry_run:
        return True
    path = audit_path(vault)
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        new = not os.path.exists(path)
        with open(path, "a", encoding="utf-8") as f:
            if new:
                month = dt.date.today().strftime("%Y-%m")
                f.write(f"---\ntype: downloads-trash-ledger\nmonth: {month}\n---\n")
                f.write(f"# Downloads -> Trash ledger - {month}\n\n")
                f.write("Append-only. Every line is a file that left Downloads "
                        "(recoverable in macOS Trash ~30d) or was saved into the "
                        "vault. Nothing here was permanently deleted by sanbrain.\n\n")
            f.write(line + "\n")
        return True
    except OSError as e:
        log(f"AUDIT-LEDGER-FAIL ({e}) for line: {line}")
        sys.stderr.write(f"{ts()} [process-downloads] AUDIT-LEDGER-FAIL {e}\n")
        return False


# ── Actions ─────────────────────────────────────────────────────────
def trash_file(abs_path, log):
    """Move to macOS Trash via /usr/bin/trash. True only on exit 0. Pass an
    absolute path (always '/'-leading, never mistakable for a flag — trash(8)
    has no '--' separator)."""
    cmd = os.environ.get("SANBRAIN_TRASH_CMD", "/usr/bin/trash")
    if not (os.path.isabs(cmd) and os.path.exists(cmd)) and shutil.which(cmd) is None:
        log(f"TRASH-SKIP (trash command '{cmd}' missing) for {abs_path}")
        return False
    try:
        r = subprocess.run([cmd, "-v", abs_path], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"TRASH-ERROR ({e}) for {abs_path}")
        return False
    if r.returncode != 0:
        log(f"TRASH-FAIL rc={r.returncode} for {abs_path}: {r.stderr.strip()[:200]}")
        return False
    return True


def promote(src_abs, name, vault, subdir, src_sha, dry_run, log):
    """Copy a valuable/one-way file verbatim into vault/<subdir>/, verify by
    hash, return the vault-relative copy path. None (caller will NOT trash) on
    any failure. Collision-safe: never overwrites an existing file."""
    dest_dir = os.path.join(vault, subdir)
    dest = os.path.join(dest_dir, name)
    if os.path.exists(dest):
        stem, ext = os.path.splitext(name)
        dest = os.path.join(dest_dir, f"{stem}-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}{ext}")
    rel = os.path.relpath(dest, vault)
    if dry_run:
        log(f"DRY-RUN would save {name} -> {rel}")
        return rel
    try:
        os.makedirs(dest_dir, exist_ok=True)
        shutil.copy2(src_abs, dest)
    except OSError as e:
        log(f"PROMOTE-FAIL ({e}) for {name} — original kept on desk")
        return None
    if sha256_file(dest, None) != src_sha:
        log(f"PROMOTE-VERIFY-FAIL for {name} (copy hash != source) — original kept")
        try:
            os.remove(dest)  # don't leave an unverified copy littering the vault
        except OSError:
            pass
        return None
    log(f"SAVED {name} -> {rel} (verified)")
    return rel


def human_mb(size):
    return round(size / (1024 * 1024), 1)


def reconcile(args, log):
    """Seed the provenance ledger from verbatim copies already in the vault, so
    launchd runs (which can't read the vault) recognize the backlog as saved.
    Run once from an FDA Terminal at deploy. Idempotent."""
    max_bytes = args.max_mb * 1024 * 1024
    index, denied = build_vault_hash_index(args.vault, max_bytes, log)
    if denied:
        print("reconcile: vault reads were DENIED (run from a Full-Disk-Access "
              "Terminal, not under launchd). Nothing seeded.")
        return 1
    have, prov_path = load_provenance(args.state)
    added = 0
    for digest in index:
        if digest not in have:
            record_provenance(prov_path, {"ts": ts(), "source_sha256": digest,
                                          "origin": "reconcile"}, args.dry_run)
            added += 1
    msg = f"reconcile: {added} vault copies recorded in provenance ledger ({len(index)} scanned)"
    log(msg)
    print(msg)
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--downloads", default=os.path.expanduser("~/Downloads"))
    ap.add_argument("--vault", default=os.path.expanduser(
        "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"))
    ap.add_argument("--state", default=os.path.expanduser("~/sanbrain/.state"))
    ap.add_argument("--log", default=os.path.expanduser("~/sanbrain/logs/downloads.log"))
    ap.add_argument("--idle-days", type=int,
                    default=int(os.environ.get("DOWNLOADS_IDLE_DAYS", "14") or 14))
    ap.add_argument("--max-mb", type=int,
                    default=int(os.environ.get("DOWNLOADS_TRASH_MAX_MB", "500") or 500))
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--reconcile", action="store_true")
    ap.add_argument("--proposal", default="", help="path to an LLM triage proposal (advisory)")
    ap.add_argument("--json", action="store_true", help="print machine summary to stdout")
    args = ap.parse_args()

    log = lambda m: log_line(args.log, m)

    # Clamp foot-gun config: a typo'd 0 must not mass-trash or silently disable.
    if args.idle_days < 1:
        log(f"WARN: idle-days={args.idle_days} invalid; using 14")
        args.idle_days = 14
    if args.max_mb < 1:
        log(f"WARN: max-mb={args.max_mb} invalid; using 500")
        args.max_mb = 500

    if args.reconcile:
        return reconcile(args, log)

    max_bytes = args.max_mb * 1024 * 1024
    now = dt.datetime.now().timestamp()

    if not os.path.isdir(args.downloads):
        log(f"SKIP: Downloads not accessible at {args.downloads}")
        print("process-downloads: SKIP (no Downloads access)")
        return 0

    vault_ok = os.path.isdir(args.vault)
    if not vault_ok:
        log(f"WARN: vault not accessible at {args.vault} — cannot save/verify; "
            "valuable unsaved files will be flagged, not trashed")

    index, reads_denied = (build_vault_hash_index(args.vault, max_bytes, log)
                           if vault_ok else (set(), False))
    prov_hashes, prov_path = load_provenance(args.state)
    saved_hashes = index | prov_hashes
    log(f"saved-signal: {len(prov_hashes)} ledger + {len(index)} vault index"
        + (" (vault reads denied)" if reads_denied else ""))

    proposal = load_proposal(args.proposal, log)

    summary = {"date": dt.date.today().isoformat(), "dry_run": args.dry_run,
               "idle_days": args.idle_days, "max_mb": args.max_mb,
               "vault_reads_denied": reads_denied,
               "trashed": [], "promoted": [], "flagged": [], "aging": [],
               "kept_keys": [], "errors": []}

    def flag(name, reason, **kw):
        summary["flagged"].append(dict(name=name, reason=reason, **kw))
        log(f"FLAG {name}: {reason}")

    def do_trash(name, src_abs, kind, reason, size, idle_days, saved_to=None):
        if not (args.dry_run or trash_file(src_abs, log)):
            summary["errors"].append({"name": name, "reason": "trash failed"})
            return
        dest = f"saved→ {saved_to} | " if saved_to else ""
        line = (f"- {ts()} | **{name}** | {kind} | {reason} | {human_mb(size)} MB | "
                f"{dest}trashed→ ~/.Trash/{name} | recoverable ~30d")
        if not append_audit(args.vault, line, args.dry_run, log):
            summary["errors"].append({"name": name, "reason": "audit-ledger write failed"})
        summary["trashed"].append({"name": name, "kind": kind, "reason": reason,
                                    "idle_days": idle_days, "size_mb": human_mb(size)})
        log(f"TRASHED {name} ({kind}, {reason})")

    for entry in sorted(os.listdir(args.downloads)):
        if entry.startswith("."):
            continue  # hidden/noise is harvest-downloads.sh's job
        src_abs = os.path.join(args.downloads, entry)
        if os.path.islink(src_abs):
            continue  # never reclaim a symlink (target may live outside the desk)
        if os.path.isdir(src_abs):
            continue  # v1: never auto-trash directories
        if is_partial(entry):
            continue  # in-progress download; harvest cleans these

        # Deterministic classification is the floor; the LLM proposal may only
        # make a file SAFER (resolve_kind clamps it). The model never deletes.
        kind, force_keep = resolve_kind(classify(entry), proposal.get(entry))
        if kind == "key":
            summary["kept_keys"].append(entry)
            continue

        try:
            st = os.stat(src_abs)
        except OSError:
            continue
        if is_dataless(st):
            flag(entry, "iCloud-evicted — download locally before it can be cleared")
            continue

        size = st.st_size
        idle_days = max(0, int((now - st.st_mtime) // 86400))
        idle = idle_days >= args.idle_days
        too_big = size > max_bytes

        if force_keep:
            # The triage model says this is in use / wanted — never clear it.
            summary["aging"].append({"name": entry, "idle_days": idle_days,
                                     "days_left": max(0, args.idle_days - idle_days),
                                     "kind": kind, "note": "triage: keep"})
            continue

        if too_big:
            if idle:
                flag(entry, f"idle {idle_days}d but > {args.max_mb}MB — clear manually",
                     size_mb=human_mb(size))
            continue

        src_sha = sha256_file(src_abs, max_bytes)
        verified = bool(src_sha and src_sha in saved_hashes)

        if not idle:
            # Working directory: fresh files always stay. Show what's on the clock.
            summary["aging"].append({"name": entry, "idle_days": idle_days,
                                     "days_left": args.idle_days - idle_days,
                                     "kind": kind})
            continue

        # ── idle from here ──
        if verified:
            do_trash(entry, src_abs, kind, "verified saved", size, idle_days)
        elif kind == "disposable":
            do_trash(entry, src_abs, "disposable", f"idle {idle_days}d", size, idle_days)
        elif kind == "harvestable":
            # .md/.txt: harvest will copy to raw/; wait until it's verified-saved.
            summary["aging"].append({"name": entry, "idle_days": idle_days,
                                     "days_left": 0, "kind": kind,
                                     "note": "pending harvest/ingest"})
        else:
            # valuable / oneway, not yet saved -> SAVE first, then trash.
            if not vault_ok or src_sha is None:
                flag(entry, "valuable & unsaved, cannot save (vault/hash unavailable) — kept")
                continue
            subdir = os.path.join("raw", "legal") if kind == "oneway" \
                else os.path.join("raw", "needs-review")
            rel = promote(src_abs, entry, args.vault, subdir, src_sha, args.dry_run, log)
            if not rel:
                flag(entry, "save failed — kept on desk")
                continue
            record_provenance(prov_path, {
                "ts": ts(), "source_name": entry, "source_sha256": src_sha,
                "size": size, "copy_path": rel, "copy_sha256": src_sha,
                "origin": "promote"}, args.dry_run)
            summary["promoted"].append({"name": entry, "copy_path": rel, "kind": kind})
            do_trash(entry, src_abs, kind, "saved & cleared", size, idle_days, saved_to=rel)

    if not args.dry_run:
        try:
            os.makedirs(args.state, exist_ok=True)
            with open(os.path.join(args.state, "downloads-last-action.json"), "w",
                      encoding="utf-8") as f:
                json.dump(summary, f, ensure_ascii=False, indent=2)
        except OSError as e:
            log(f"STATE-SUMMARY-FAIL ({e})")

    msg = (f"process-downloads: {len(summary['trashed'])} trashed, "
           f"{len(summary['promoted'])} saved+cleared, {len(summary['aging'])} aging, "
           f"{len(summary['flagged'])} flagged, {len(summary['kept_keys'])} keys kept, "
           f"{len(summary['errors'])} errors"
           + (" [dry-run]" if args.dry_run else "")
           + (" [VAULT READS DENIED]" if reads_denied else ""))
    log(msg)
    print(json.dumps(summary, ensure_ascii=False) if args.json else msg)
    return 0


def log_line(log_path, msg):
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"{ts()} [process-downloads] {msg}\n")
    except OSError:
        sys.stderr.write(f"{ts()} [process-downloads] LOG-FAIL {msg}\n")


if __name__ == "__main__":
    sys.exit(main())
