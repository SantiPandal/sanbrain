#!/usr/bin/env python3
"""Match book entity slugs <-> PDF files in ~/Downloads. Deterministic best-effort."""
import os, re, json, glob

VAULT = os.path.expanduser("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT")
ENT = os.path.join(VAULT, "wiki/entities")
DL = os.path.expanduser("~/Downloads")

STOP = set("the a an of and for to in on with how why your you what is are it as at by".split())
# tokens that don't help identity (edition/format noise)
NOISE = set("2nd 3rd 1st 4th 5th 11th 40th updated edition ed expanded anniversary english "
            "vol volume new revised second third first complete oceanofpdf com part".split())

def slugify(s):
    s = s.lower()
    s = s.replace("&", " and ")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return re.sub(r"-+", "-", s).strip("-")

def core_tokens(slug):
    toks = [t for t in slug.split("-") if t and t not in STOP and t not in NOISE]
    # drop pure 1-2 digit tokens (years/edition nums) but keep things like 100m, 1929, 48, 33, 21
    out = []
    for t in toks:
        if t.isdigit() and len(t) <= 2 and t not in {"21","48","33"}:
            continue
        out.append(t)
    return set(out)

# ---- entity book slugs ----
entities = {}
for f in glob.glob(os.path.join(ENT, "*.md")):
    try:
        head = open(f, encoding="utf-8").read(400)
    except Exception:
        continue
    if re.search(r"^type:\s*book\s*$", head, re.M):
        slug = os.path.basename(f)[:-3]
        entities[slug] = core_tokens(slug)

# ---- candidate book PDFs in Downloads (maxdepth 2) ----
ADMIN = re.compile(r"acuse|factura|cfdi|term-sheet|cheque|boarding|dc3|solicitud|"
                   r"demand_forecasting|podcast-intro|taxfree_ocr|res_20|sat-reglas|sat_reglas|"
                   r"cumplimiento|comentarios-contrato|un_taco|un taco|^[0-9a-f-]{8,}|"
                   r"^\d{5,}_", re.I)

def pdf_title(fn):
    base = os.path.basename(fn)
    base = re.sub(r"\.(pdf|epub|mobi)$", "", base, flags=re.I)
    base = re.sub(r"_?OceanofPDF\.com_?", "", base, flags=re.I)
    base = re.sub(r"\s*\(\d+\)$", "", base)  # drop (1) (2) copy markers
    # author separator: _-_ or " - "
    title = re.split(r"_-_| - ", base)[0]
    return title

pdfs = {}
for root, _, files in os.walk(DL):
    depth = root[len(DL):].count(os.sep)
    if depth > 1:
        continue
    for fn in files:
        if not re.search(r"\.(pdf|epub)$", fn, re.I):
            continue
        if ADMIN.search(fn):
            continue
        full = os.path.join(root, fn)
        title = pdf_title(fn)
        slug = slugify(title)
        toks = core_tokens(slug)
        if not toks:
            continue
        pdfs.setdefault(slug, []).append(full)

# ---- match ----
def score(etoks, ptoks):
    if not etoks or not ptoks:
        return 0.0
    inter = etoks & ptoks
    if not inter:
        return 0.0
    # subset bonus: entity fully contained in pdf (or vice versa)
    subset = 1.0 if (etoks <= ptoks or ptoks <= etoks) else 0.0
    jac = len(inter) / len(etoks | ptoks)
    return subset * 2 + jac + len(inter) * 0.1

mapping = {}      # entity_slug -> pdf path
used_pdfs = set()
ent_unmatched = []

# greedy: for each entity, find best pdf-slug
pairs = []
for eslug, etoks in entities.items():
    best = None
    for pslug, paths in pdfs.items():
        sc = score(etoks, core_tokens(pslug))
        if sc > 0:
            if best is None or sc > best[0]:
                best = (sc, pslug)
    pairs.append((best[0] if best else 0, eslug, best[1] if best else None))

pairs.sort(reverse=True)
for sc, eslug, pslug in pairs:
    if sc < 1.0 or pslug is None:
        ent_unmatched.append(eslug)
        continue
    if pslug in used_pdfs:
        # pick a still-available pdf-slug for this entity
        ent_unmatched.append(eslug)
        continue
    # choose best concrete file: prefer loose (not in subfolder), shortest path, no (1)/(2)
    cand = sorted(pdfs[pslug], key=lambda p: (p.count(os.sep), len(p)))
    mapping[eslug] = {"score": round(sc, 2), "pdf": cand[0], "pdf_slug": pslug}
    used_pdfs.add(pslug)

pdf_unmatched = sorted(s for s in pdfs if s not in used_pdfs)

out = {
    "matched": mapping,
    "entities_unmatched": sorted(ent_unmatched),
    "pdfs_unmatched": {s: pdfs[s] for s in pdf_unmatched},
}
print(json.dumps(out, indent=1, ensure_ascii=False))
print(f"\n# entities={len(entities)} matched={len(mapping)} "
      f"ent_unmatched={len(ent_unmatched)} pdf_unmatched={len(pdf_unmatched)}",
      flush=True)
