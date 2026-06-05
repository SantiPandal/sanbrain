#!/usr/bin/env python3
"""Final prep: resolve slug<->PDF, extract text, emit job file for the distillation fan-out."""
import os, re, json, glob, subprocess

VAULT = os.path.expanduser("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT")
ENT = os.path.join(VAULT, "wiki/entities")
DL = os.path.expanduser("~/Downloads")
REPO = "/Users/santipandal/conductor/workspaces/sanbrain/calgary"
CACHE = os.path.join(REPO, ".context/book-text")
os.makedirs(CACHE, exist_ok=True)

STOP = set("the a an of and for to in on with how why your you what is are it as at by".split())
NOISE = set("2nd 3rd 1st 4th 5th 11th 40th updated edition ed expanded anniversary english "
            "vol volume new revised second third first complete oceanofpdf com part".split())

def slugify(s):
    s = s.lower().replace("&", " and ")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return re.sub(r"-+", "-", s).strip("-")

def core_tokens(slug):
    toks = [t for t in slug.split("-") if t and t not in STOP and t not in NOISE]
    out = []
    for t in toks:
        if t.isdigit() and len(t) <= 2 and t not in {"21","48","33"}:
            continue
        out.append(t)
    return set(out)

# entity book slugs
entities = {}
for f in glob.glob(os.path.join(ENT, "*.md")):
    head = open(f, encoding="utf-8", errors="ignore").read(400)
    if re.search(r"^type:\s*book\s*$", head, re.M):
        slug = os.path.basename(f)[:-3]
        entities[slug] = core_tokens(slug)

ADMIN = re.compile(r"acuse|factura|cfdi|term-sheet|cheque|boarding|dc3|solicitud|"
                   r"demand_forecasting|demand forecasting|podcast-intro|taxfree_ocr|res_20|"
                   r"sat-reglas|sat_reglas|cumplimiento|comentarios-contrato|un_taco|un taco|"
                   r"^[0-9a-f]{8}-|^\d{5,}_|preview-", re.I)

def pdf_title(fn):
    base = re.sub(r"\.(pdf|epub|mobi)$", "", os.path.basename(fn), flags=re.I)
    base = re.sub(r"_?OceanofPDF\.com_?", "", base, flags=re.I)
    base = re.sub(r"\s*\(\d+\)$", "", base)
    return re.split(r"_-_| - ", base)[0]

pdfs = {}
for root, _, files in os.walk(DL):
    if root[len(DL):].count(os.sep) > 1:
        continue
    for fn in files:
        if not re.search(r"\.(pdf|epub)$", fn, re.I) or ADMIN.search(fn):
            continue
        slug = slugify(pdf_title(fn))
        if core_tokens(slug):
            pdfs.setdefault(slug, []).append(os.path.join(root, fn))

def score(a, b):
    if not a or not b: return 0.0
    inter = a & b
    if not inter: return 0.0
    subset = 1.0 if (a <= b or b <= a) else 0.0
    return subset*2 + len(inter)/len(a|b) + len(inter)*0.1

def best_file(pslug):
    return sorted(pdfs[pslug], key=lambda p: (p.count(os.sep), len(p)))[0]

mapping, used = {}, set()
pairs = []
for eslug, etoks in entities.items():
    best = None
    for pslug in pdfs:
        sc = score(etoks, core_tokens(pslug))
        if best is None or sc > best[0]:
            best = (sc, pslug)
    pairs.append((best[0], eslug, best[1]))
pairs.sort(reverse=True)
for sc, eslug, pslug in pairs:
    if sc >= 1.0 and pslug and pslug not in used:
        mapping[eslug] = best_file(pslug); used.add(pslug)

# ---- manual matches (near-misses) ----
MANUAL = {
    "100m-money-models": "00m-money-models-how-to-make-money",
    "21-lecciones-para-el-siglo-xxi": "21-lessons-for-the-21st-century",
    "expert-secrets": "expert-secret-converting-your-online-visitors-into-lifelong-customers",
    "flow-the-psychology-of-optimal-experience": "flow-the-psychology-of-happiness",
    "gdel-escher-bach-an-eternal-golden-braid": "godel-escher-bach-an-eternal-golden-brai",
    "meditations": "meditation",
    "the-48-laws-of-power": "48-laws-of-powers",
}
for eslug, pslug in MANUAL.items():
    if eslug in entities and pslug in pdfs and pslug not in used:
        mapping[eslug] = best_file(pslug); used.add(pslug)

# ---- new entities: real books with PDFs but no entity yet (books are entities) ----
NEW = {
    "quanta-and-fields": ("quanta-and-fields", "Quanta and Fields", "Sean Carroll"),
    "the-greatest-minds-and-ideas-of-all-time": ("the-greatest-minds-and-ideas-of-all-time",
        "The Greatest Minds and Ideas of All Time", "Will Durant"),
}
new_jobs = {}
for eslug,(pslug,title,author) in NEW.items():
    if pslug in pdfs and pslug not in used:
        new_jobs[eslug] = {"pdf": best_file(pslug), "title": title, "author": author}
        used.add(pslug)

# entities still without a PDF (genuine stubs — no text to extract)
no_pdf = sorted(s for s in entities if s not in mapping)

# ---- build jobs: extract text, skip the already-done pilot ----
PILOT_DONE = {"100m-offers"}
jobs = []
for eslug, pdf in sorted(mapping.items()):
    if eslug in PILOT_DONE: continue
    jobs.append({"slug": eslug, "pdf": pdf, "new": False})
for eslug, meta in sorted(new_jobs.items()):
    jobs.append({"slug": eslug, "pdf": meta["pdf"], "new": True,
                 "title": meta["title"], "author": meta["author"]})

extracted = 0
for j in jobs:
    txt = os.path.join(CACHE, j["slug"] + ".txt")
    if not (os.path.exists(txt) and os.path.getsize(txt) > 1000):
        subprocess.run(["pdftotext", j["pdf"], txt], capture_output=True)
    j["txt"] = txt
    j["chars"] = os.path.getsize(txt) if os.path.exists(txt) else 0
    if j["chars"] > 1000: extracted += 1

json.dump(jobs, open(os.path.join(REPO, ".context/book-jobs.json"), "w"), indent=1)

print(f"JOBS: {len(jobs)}  (existing entities: {len(jobs)-len(new_jobs)}, new entities: {len(new_jobs)}, pilot already done: 1)")
print(f"TEXT EXTRACTED OK: {extracted}/{len(jobs)}")
print(f"\nNEW entities to create: {list(new_jobs)}")
print(f"\nEntities with NO pdf (left as stubs, {len(no_pdf)}): {no_pdf}")
fails = [j['slug'] for j in jobs if j['chars'] <= 1000]
print(f"\nExtraction FAILED/empty ({len(fails)}): {fails}")
