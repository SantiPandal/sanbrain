#!/usr/bin/env python3
"""Emit pending book slugs in batches of N for parallel agent fan-out."""
import json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JOBS = os.path.join(REPO, ".context/book-jobs.json")
VAULT = os.path.expanduser("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT")
ENT = os.path.join(VAULT, "wiki/entities")

def is_done(slug):
    p = os.path.join(ENT, slug + ".md")
    if not os.path.exists(p):
        return False
    t = open(p, encoding="utf-8").read()
    if any(s in t for s in [
        "To be extracted",
        "To be connected",
        "Not yet added",
        "[Framework/concept]",
        "[How ideas",
    ]):
        return False
    frameworks = re.search(r"## Key Frameworks\n(.*?)(\n## |\Z)", t, re.S)
    apps = re.search(r"## Santiago's Applications\n(.*?)(\n## |\Z)", t, re.S)
    framework_count = len(re.findall(r"^- \*\*[^*]+\*\*", frameworks.group(1), re.M)) if frameworks else 0
    app_count = len(re.findall(r"^- ", apps.group(1), re.M)) if apps else 0
    if framework_count >= 4 and app_count >= 2:
        return True
    if re.search(r"Enriched from full-text|Phase 2 book ingestion", t):
        return True
    return False

jobs = json.load(open(JOBS))
pending = [j for j in jobs if not is_done(j["slug"])]
batch_size = int(sys.argv[1]) if len(sys.argv) > 1 else 10
batch_num = int(sys.argv[2]) if len(sys.argv) > 2 else 0
start = batch_num * batch_size
chunk = pending[start : start + batch_size]
print(json.dumps(chunk, indent=2))
first = start + 1 if chunk else 0
last = start + len(chunk) if chunk else 0
print(f"# batch {batch_num}: {len(chunk)} books ({first}-{last} of {len(pending)} pending)", file=sys.stderr)
