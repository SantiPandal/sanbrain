#!/usr/bin/env python3
"""Sanbrain: process approved Downloads deletions — strict, two-factor.

Replaces the old sed/grep-over-the-whole-brief approach. A file is deleted
from ~/Downloads only when BOTH are true:

  1. It appears as a checked item (`- [x] **name**`) inside the Downloads
     approval section of a recent brief, OR checked directly in a manifest.
  2. The same name appears as a checkbox item in a recent downloads-manifest
     (the harvest script wrote it — so we know the name came from a real
     directory listing, not from arbitrary LLM-generated text).

Names containing path separators or traversal are rejected outright.
Folders are only removed when the manifest listed them as folders (trailing /).

Usage:
  process-approved-deletions.py [--downloads DIR] [--vault DIR]
                                [--days 3] [--dry-run]
"""
import argparse
import datetime as dt
import glob
import os
import re
import shutil
import sys

CHECKED_RE = re.compile(r"^\s*-\s*\[[xX]\]\s*\*\*(.+?)\*\*")
CHECKBOX_RE = re.compile(r"^\s*-\s*\[[ xX]\]\s*\*\*(.+?)\*\*")
# Section of the brief that morning-brief copies the manifest into
BRIEF_SECTION_RE = re.compile(
    r"^###\s*Downloads\b.*$|^##\s*One-Way Doors\s*$", re.M)


def log_line(log_path, msg):
    stamp = dt.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(f"{stamp} {msg}\n")


def section_lines(text, start_re):
    """Yield lines belonging to sections whose heading matches start_re,
    stopping at the next heading of equal-or-higher level."""
    out = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        m = start_re.match(lines[i])
        if not m:
            i += 1
            continue
        level = len(re.match(r"^#+", lines[i]).group(0))
        i += 1
        while i < len(lines):
            hm = re.match(r"^(#+)\s", lines[i])
            if hm and len(hm.group(1)) <= level:
                break
            out.append(lines[i])
            i += 1
    return out


def recent_files(pattern, days):
    cutoff = dt.date.today() - dt.timedelta(days=days)
    keep = []
    for p in glob.glob(pattern):
        m = re.search(r"(\d{4}-\d{2}-\d{2})", os.path.basename(p))
        if m:
            try:
                if dt.date.fromisoformat(m.group(1)) >= cutoff:
                    keep.append(p)
            except ValueError:
                pass
    return sorted(keep)


def safe_name(name):
    """Reject anything that isn't a plain Downloads entry name."""
    stripped = name.rstrip("/")
    if not stripped or stripped in (".", ".."):
        return False
    if "/" in stripped or "\\" in stripped or stripped.startswith("."):
        return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--downloads", default=os.path.expanduser("~/Downloads"))
    ap.add_argument("--vault", default=os.path.expanduser(
        "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"))
    ap.add_argument("--log", default=os.path.expanduser("~/sanbrain/logs/downloads.log"))
    ap.add_argument("--days", type=int, default=3,
                    help="how many days of briefs/manifests to consider")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    daily = os.path.join(args.vault, "wiki", "daily")
    raw = os.path.join(args.vault, "raw")

    # Factor 2: names the harvest actually listed (allow-list), with kind
    allowed = {}  # name (no trailing /) -> "folder"|"file"
    approved_in_manifest = set()
    for mf in recent_files(os.path.join(raw, "downloads-manifest-*.md"), args.days):
        text = open(mf, encoding="utf-8", errors="replace").read()
        for line in text.splitlines():
            m = CHECKBOX_RE.match(line)
            if not m:
                continue
            name = m.group(1)
            kind = "folder" if name.endswith("/") else "file"
            allowed[name.rstrip("/")] = kind
            if CHECKED_RE.match(line):
                approved_in_manifest.add(name.rstrip("/"))

    # Factor 1: checked items inside the Downloads section of recent briefs
    approved_in_brief = set()
    for bf in recent_files(os.path.join(daily, "*-brief.md"), args.days):
        text = open(bf, encoding="utf-8", errors="replace").read()
        for line in section_lines(text, BRIEF_SECTION_RE):
            m = CHECKED_RE.match(line)
            if m:
                approved_in_brief.add(m.group(1).rstrip("/"))

    approved = (approved_in_brief | approved_in_manifest) & set(allowed)
    skipped = (approved_in_brief | approved_in_manifest) - set(allowed)
    for name in sorted(skipped):
        log_line(args.log, f"SKIP (not in any manifest allow-list): {name}")

    deleted, missing = 0, 0
    for name in sorted(approved):
        if not safe_name(name):
            log_line(args.log, f"SKIP (unsafe name): {name!r}")
            continue
        target = os.path.join(args.downloads, name)
        if not os.path.lexists(target):
            missing += 1
            continue
        kind = allowed[name]
        if args.dry_run:
            log_line(args.log, f"DRY-RUN would delete {kind}: {name}")
            continue
        try:
            if kind == "folder" and os.path.isdir(target):
                shutil.rmtree(target)
            else:
                os.remove(target)
            deleted += 1
            log_line(args.log, f"Approved deletion ({kind}): {name}")
        except OSError as e:
            log_line(args.log, f"ERROR deleting {name}: {e}")

    print(f"approved-deletions: {deleted} deleted, {missing} already gone, "
          f"{len(skipped)} skipped (not allow-listed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
