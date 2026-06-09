#!/usr/bin/env python3
"""Sanbrain: vault-doctor — mechanical integrity checks, zero LLM calls.

Replaces the LLM-computed "Vault Health" numbers in the morning brief and adds
the integrity checks an LLM can't be trusted to do exhaustively: broken
wikilinks, iCloud conflict/eviction artifacts, schema violations, propagation
postconditions, sensor heartbeats, raw/ backlog.

Writes a dated markdown report into wiki/logs/ and prints a one-paragraph
summary to stdout (for cron logs and for inclusion in prompts).

Usage: vault-doctor.py [--vault PATH] [--state PATH] [--max-list N]
Exit code is always 0 — the doctor reports, it doesn't block.
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import sys
import unicodedata

WIKILINK_RE = re.compile(r"\[\[([^\]|#\n]+)(?:#[^\]|\n]*)?(?:\|[^\]\n]*)?\]\]")
PLACEHOLDER_PATTERNS = [
    "To be extracted", "To be connected", "Not yet added", "TBD",
    "[One-line:", "[Framework/concept]", "[How ideas",
]
ENTITY_TYPES = {"person", "business", "book", "redirect"}
# Folders whose pages are entry points / outputs — not expected to have
# inbound links, and not counted as orphans.
ORPHAN_EXEMPT_DIRS = {"daily", "logs", "context", "reviews"}
ROOT_EXEMPT = {"index", "log", "SOUL", "CRITICAL_FACTS", "_CLAUDE", "personality", "soul"}


def norm(name: str) -> str:
    name = unicodedata.normalize("NFC", name).strip().casefold()
    return name


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def frontmatter(text):
    """Crude single-pass frontmatter parse: returns dict of scalar fields."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fields = {}
    for line in text[3:end].splitlines():
        m = re.match(r"^(\w[\w-]*):\s*(.*)$", line)
        if m:
            fields[m.group(1)] = m.group(2).strip()
    return fields


def parse_attendees(fm_value):
    """attendees: [a, b] or comma string -> list of names."""
    v = fm_value.strip()
    if v.startswith("[") and v.endswith("]"):
        v = v[1:-1]
    return [a.strip().strip("'\"") for a in v.split(",") if a.strip()]


def slugify(name):
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s.lower())
    return re.sub(r"-+", "-", s).strip("-")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vault", default=os.path.expanduser(
        "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"))
    ap.add_argument("--state", default=os.path.expanduser("~/sanbrain/.state"))
    ap.add_argument("--max-list", type=int, default=10)
    ap.add_argument("--out", default=None, help="report path (default wiki/logs/doctor-DATE.md)")
    args = ap.parse_args()

    vault = args.vault
    if not os.path.isdir(vault):
        print(f"vault-doctor: vault not found at {vault}")
        return 0

    today = dt.date.today().isoformat()
    now = dt.datetime.now()
    wiki = os.path.join(vault, "wiki")
    findings = {}   # section -> list[str]
    metrics = {}    # label -> number

    def add(section, item):
        findings.setdefault(section, []).append(item)

    # ── Collect pages ────────────────────────────────────────────
    all_md = []     # every .md in the vault (link resolution targets)
    wiki_md = []    # pages under wiki/ (subject to schema + health checks)
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in {".obsidian", ".trash", ".git"}]
        for fn in files:
            p = os.path.join(root, fn)
            if fn.endswith(".md"):
                all_md.append(p)
                if root.startswith(wiki + os.sep) or root == wiki:
                    wiki_md.append(p)

    basenames = {norm(os.path.splitext(os.path.basename(p))[0]) for p in all_md}
    metrics["total vault pages"] = len(all_md)
    metrics["wiki pages"] = len(wiki_md)

    # ── 1. iCloud artifacts: conflict copies + evicted placeholders ──
    conflict_re = re.compile(r"( \d+\.md$)|(conflicted copy)", re.I)
    for p in all_md:
        if conflict_re.search(os.path.basename(p)):
            add("iCloud conflict copies", os.path.relpath(p, vault))
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in {".obsidian", ".trash", ".git"}]
        for fn in files:
            if fn.endswith(".icloud"):
                add("Evicted files (not downloaded locally)",
                    os.path.relpath(os.path.join(root, fn), vault))
    for p in wiki_md:
        if os.path.getsize(p) == 0:
            add("Empty pages (0 bytes)", os.path.relpath(p, vault))

    # ── 2. Wikilink integrity ────────────────────────────────────
    inbound = set()
    broken = []
    for p in wiki_md:
        text = read(p)
        src = os.path.relpath(p, vault)
        for m in WIKILINK_RE.finditer(text):
            target = norm(os.path.basename(m.group(1)))
            if not target:
                continue
            inbound.add(target)
            if target not in basenames:
                broken.append(f"{src} -> [[{m.group(1)}]]")
    metrics["broken wikilinks"] = len(broken)
    for b in broken:
        add("Broken wikilinks (target page missing)", b)

    # ── 3. Schema checks on wiki pages ───────────────────────────
    entities_dir = os.path.join(wiki, "entities")
    for p in wiki_md:
        rel = os.path.relpath(p, vault)
        text = read(p)
        fm = frontmatter(text)
        if not fm:
            add("Pages missing frontmatter", rel)
            continue
        if "type" not in fm:
            add("Pages missing `type:` in frontmatter", rel)
        if os.path.dirname(p) == entities_dir:
            if fm.get("type") not in ENTITY_TYPES:
                add("Entity pages with unexpected type",
                    f"{rel} (type: {fm.get('type', '?')})")
            if fm.get("type") != "redirect" and "## Timeline" not in text:
                add("Entity pages missing `## Timeline`", rel)
        for pat in PLACEHOLDER_PATTERNS:
            if pat in text:
                add("Placeholder text left in pages", f"{rel} ('{pat}')")
                break

    # ── 4. Propagation postcondition (Tan's MUST as an invariant):
    # every meeting attendee has an entity page that references the meeting ──
    entity_texts = {}
    if os.path.isdir(entities_dir):
        for p in glob.glob(os.path.join(entities_dir, "*.md")):
            entity_texts[norm(os.path.splitext(os.path.basename(p))[0])] = read(p)
    for p in wiki_md:
        text = read(p)
        fm = frontmatter(text)
        if "attendees" not in fm:
            continue
        meeting_base = os.path.splitext(os.path.basename(p))[0]
        for name in parse_attendees(fm["attendees"]):
            slug = norm(slugify(name))
            if slug in ("santiago", "santiago-pandal"):
                continue
            if slug not in entity_texts:
                add("Meetings with unpropagated attendees (no entity page)",
                    f"{os.path.relpath(p, vault)}: {name}")
            elif meeting_base not in entity_texts[slug]:
                add("Meetings with unpropagated attendees (no timeline back-link)",
                    f"{os.path.relpath(p, vault)}: {name} -> wiki/entities/{slug}.md")

    # ── 5. Counts, staleness, orphans ────────────────────────────
    def count_dir(sub, label):
        d = os.path.join(wiki, sub)
        n = len(glob.glob(os.path.join(d, "*.md"))) if os.path.isdir(d) else 0
        metrics[label] = n

    count_dir("entities", "entities")
    count_dir("concepts", "concepts")
    count_dir("ideas", "ideas")
    count_dir("projects", "projects")
    count_dir("context", "context files")

    stale_cutoff = now - dt.timedelta(days=30)
    stale = []
    for p in wiki_md:
        parts = os.path.relpath(p, wiki).split(os.sep)
        if parts[0] in ("daily", "logs"):
            continue
        mtime = dt.datetime.fromtimestamp(os.path.getmtime(p))
        if mtime < stale_cutoff:
            stale.append((mtime, os.path.relpath(p, vault)))
    stale.sort()
    metrics["stale pages (30+ days)"] = len(stale)
    for mtime, rel in stale[: args.max_list]:
        add("Stalest pages", f"{rel} (last touched {mtime.date()})")

    orphans = []
    for p in wiki_md:
        parts = os.path.relpath(p, wiki).split(os.sep)
        if parts[0] in ORPHAN_EXEMPT_DIRS:
            continue
        base = os.path.splitext(os.path.basename(p))[0]
        if base in ROOT_EXEMPT:
            continue
        if norm(base) not in inbound:
            orphans.append(os.path.relpath(p, vault))
    metrics["orphan pages (no inbound links)"] = len(orphans)
    for o in orphans[: args.max_list]:
        add("Orphan pages", o)

    for cf in glob.glob(os.path.join(wiki, "context", "*.md")):
        fm = frontmatter(read(cf))
        lu = fm.get("last_updated", "")
        try:
            age = (dt.date.today() - dt.date.fromisoformat(lu)).days
            if age > 7:
                add("Stale context files (7+ days)",
                    f"{os.path.relpath(cf, vault)} (last_updated {lu}, {age}d ago)")
        except ValueError:
            add("Context files with unparseable last_updated",
                f"{os.path.relpath(cf, vault)} ('{lu}')")

    # ── 6. raw/ backlog ──────────────────────────────────────────
    raw_dir = os.path.join(vault, "raw")
    backlog = []
    if os.path.isdir(raw_dir):
        for fn in os.listdir(raw_dir):
            p = os.path.join(raw_dir, fn)
            if not os.path.isfile(p) or fn.startswith("."):
                continue
            age_h = (now - dt.datetime.fromtimestamp(os.path.getmtime(p))).total_seconds() / 3600
            if age_h > 48:
                backlog.append(f"raw/{fn} (sitting {int(age_h)}h)")
    metrics["raw/ files stuck 48h+"] = len(backlog)
    for b in backlog:
        add("raw/ backlog — ingest is not clearing these", b)

    # ── 7. Sensor heartbeats ─────────────────────────────────────
    hb_dir = os.path.join(args.state, "heartbeats")
    hb_lines = []
    if os.path.isdir(hb_dir):
        for f in sorted(glob.glob(os.path.join(hb_dir, "*.json"))):
            try:
                hb = json.load(open(f))
            except (json.JSONDecodeError, OSError):
                hb_lines.append(f"- {os.path.basename(f)}: UNREADABLE heartbeat")
                continue
            name, status = hb.get("sensor", "?"), hb.get("status", "?")
            ls = hb.get("last_success", "")
            age = ""
            warn = ""
            if ls:
                try:
                    delta = now - dt.datetime.fromisoformat(ls)
                    age = f"{delta.days}d{delta.seconds // 3600}h ago"
                    if delta > dt.timedelta(hours=48):
                        warn = " ⚠ no success in 48h+"
                except ValueError:
                    pass
            else:
                warn = " ⚠ never succeeded"
            detail = hb.get("detail", "")
            hb_lines.append(f"- **{name}**: {status} (last success: {age or 'n/a'}){warn}"
                            + (f" — {detail}" if detail else ""))
            if warn:
                add("Sensors needing attention", f"{name}:{warn.strip(' ⚠')}")
    else:
        hb_lines.append("- no heartbeats recorded yet")

    # ── 8. log.md size ───────────────────────────────────────────
    log_md = os.path.join(vault, "log.md")
    if os.path.isfile(log_md):
        kb = os.path.getsize(log_md) // 1024
        metrics["log.md size (KB)"] = kb
        if kb > 512:
            add("Maintenance", f"log.md is {kb}KB — rotate it (move old months to wiki/logs/)")

    # ── Write report ─────────────────────────────────────────────
    problem_count = sum(len(v) for k, v in findings.items() if k != "Stalest pages")
    out_path = args.out or os.path.join(wiki, "logs", f"doctor-{today}.md")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    lines = [
        "---",
        "type: doctor-report",
        f"date: {today}",
        f"generated: {now.strftime('%Y-%m-%dT%H:%M:%S')}",
        f"problems: {problem_count}",
        "---",
        "## For future Claude",
        "Mechanical vault integrity report from vault-doctor.py. These numbers are",
        "computed deterministically — use them as-is in the morning brief instead of",
        "recomputing. Findings are facts, not suggestions.",
        "",
        f"# Vault Doctor — {today}",
        "",
        "## Metrics",
    ]
    for k, v in metrics.items():
        lines.append(f"- {k}: {v}")
    lines += ["", "## Sensor Heartbeats"] + hb_lines
    if findings:
        lines.append("")
        lines.append("## Findings")
        for section in sorted(findings):
            items = findings[section]
            lines.append(f"\n### {section} ({len(items)})")
            for item in items[: args.max_list]:
                lines.append(f"- {item}")
            if len(items) > args.max_list:
                lines.append(f"- … and {len(items) - args.max_list} more")
    else:
        lines += ["", "## Findings", "", "No problems found."]
    lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    top = sorted(((k, len(v)) for k, v in findings.items()), key=lambda x: -x[1])[:4]
    summary = (f"vault-doctor: {metrics['total vault pages']} pages, "
               f"{problem_count} problems"
               + (" (" + "; ".join(f"{n} {k.lower()}" for k, n in top) + ")" if top else "")
               + f". Report: {os.path.relpath(out_path, vault)}")
    print(summary)
    return 0


if __name__ == "__main__":
    sys.exit(main())
