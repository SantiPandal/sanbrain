#!/usr/bin/env python3
"""Tests for process-downloads.py — proves the safety invariants without ever
touching the real ~/Downloads, the real vault, or the real macOS Trash.

A fake trash command (mv into a temp dir) stands in for /usr/bin/trash via
SANBRAIN_TRASH_CMD, so the real code path runs end-to-end in isolation.

Covers the bugs the adversarial review found:
  - underscore-separated one-way names (acta_constitutiva_2024.pdf) are SAVED,
    never idle-trashed unsaved  [the critical data-loss bug]
  - unknown 'valuable' files are saved (to needs-review), not destroyed
  - only the positive 'disposable' allowlist is trashed unsaved on idle
  - symlinks / partial downloads / directories / crypto-by-name are never reclaimed
  - 0-byte files are never 'verified saved'; future mtime never goes negative
  - the provenance ledger lets saves be recognized even when vault reads are denied

Run: python3 scripts/test-process-downloads.py
"""
import datetime
import json
import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ENGINE = os.path.join(HERE, "process-downloads.py")
DAY = 86400
PASS, FAIL = 0, 0


def check(cond, label):
    global PASS, FAIL
    if cond:
        PASS += 1; print(f"  ok   {label}")
    else:
        FAIL += 1; print(f"  FAIL {label}")


def write(path, content=b"x", mtime_days_ago=0):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(content)
    if mtime_days_ago:
        t = time.time() - mtime_days_ago * DAY
        os.utime(path, (t, t))


def fake_trash(root):
    trash_dir = os.path.join(root, "_trash")
    os.makedirs(trash_dir, exist_ok=True)
    script = os.path.join(root, "fake-trash.sh")
    with open(script, "w") as f:
        f.write("#!/bin/bash\nfor a in \"$@\"; do\n"
                "  case \"$a\" in -*) continue;; esac\n"
                "  mv \"$a\" \"%s/\" || exit 1\ndone\n" % trash_dir)
    os.chmod(script, 0o755)
    return script, trash_dir


def run_engine(dl, vault, state, trash_cmd, extra=None):
    env = dict(os.environ, SANBRAIN_TRASH_CMD=trash_cmd)
    cmd = [sys.executable, ENGINE, "--downloads", dl, "--vault", vault,
           "--state", state, "--log", os.path.join(state, "log.txt"),
           "--idle-days", "14", "--max-mb", "500", "--json"] + (extra or [])
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    assert r.returncode == 0, f"engine failed: {r.stderr}\n{r.stdout}"
    return json.loads(r.stdout.strip().splitlines()[-1])


def setup(root):
    dl = os.path.join(root, "Downloads"); vault = os.path.join(root, "VAULT")
    state = os.path.join(root, "state")
    os.makedirs(dl); os.makedirs(state)
    os.makedirs(os.path.join(vault, "raw", "archive"))
    os.makedirs(os.path.join(vault, "wiki", "logs"))

    # crypto — never touched (by ext and by name)
    write(os.path.join(dl, "fiel.key"), b"KEYBYTES", 999)
    write(os.path.join(dl, "santiago.pem"), b"-----BEGIN KEY-----", 999)
    write(os.path.join(dl, "llave-privada.bin"), b"raw key", 999)
    # one-way door, underscore-separated, NOT saved -> SAVED to legal then trashed
    write(os.path.join(dl, "acta_constitutiva_2024.pdf"), b"ACTA bytes unique", 40)
    write(os.path.join(dl, "RFC_2026.pdf"), b"RFC pdf bytes unique", 40)
    # one-way door already saved -> trashed, NOT re-saved
    contrato = b"CONTRATO firmado unique bytes"
    write(os.path.join(dl, "contrato-x.pdf"), contrato, 200)
    write(os.path.join(vault, "raw", "archive", "20260101-120000-contrato-x.pdf"), contrato)
    # one-way whose only vault copy is an empty placeholder -> NOT trusted -> saved fresh
    write(os.path.join(dl, "acuse-evicted.pdf"), b"ACUSE real content", 60)
    write(os.path.join(vault, "raw", "archive", "20260101-120000-acuse-evicted.pdf"), b"")
    # valuable UNKNOWN type, unsaved, idle -> saved to needs-review (NOT destroyed)
    write(os.path.join(dl, "weird-report.xyz"), b"some valuable unknown data", 50)
    # disposable, idle -> trashed unsaved (cheap to lose)
    write(os.path.join(dl, "screenshot.png"), b"PNGDATA", 30)
    write(os.path.join(dl, "Installer.dmg"), b"DMGDATA", 40)
    # disposable, fresh -> kept (aging)
    write(os.path.join(dl, "fresh-pic.jpg"), b"JPGDATA", 0)
    # harvestable, fresh -> aging (waits for harvest)
    write(os.path.join(dl, "fresh-note.txt"), b"working", 0)
    # 0-byte file + 0-byte vault file: must NOT become 'verified saved'
    write(os.path.join(dl, "empty.dat"), b"", 30)
    write(os.path.join(vault, "raw", "archive", "zero.bin"), b"")
    # partial download matching a one-way name -> never acted on
    write(os.path.join(dl, "contrato-nuevo.pdf.part"), b"half a contract", 40)
    # future mtime -> idle clamps to 0, file kept
    write(os.path.join(dl, "from-the-future.pdf"), b"future doc")
    ft = time.time() + 10 * DAY
    os.utime(os.path.join(dl, "from-the-future.pdf"), (ft, ft))
    # a symlink-to-dir, old -> never trashed
    target = os.path.join(root, "external"); os.makedirs(target)
    write(os.path.join(target, "important.txt"), b"keep me")
    link = os.path.join(dl, "shortcut")
    os.symlink(target, link)
    old = time.time() - 200 * DAY
    os.utime(link, (old, old), follow_symlinks=False)
    # a real directory -> never trashed
    os.makedirs(os.path.join(dl, "projectdir"))
    return dl, vault, state


def names(items):
    return {i["name"] for i in items}


def test_real_run():
    print("test: full lifecycle (fail-safe defaults)")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        s = run_engine(dl, vault, state, trash_cmd)
        present = set(os.listdir(dl))
        trashed = {os.path.basename(p) for p in os.listdir(trash_dir)}
        legal_dir = os.path.join(vault, "raw", "legal")
        review_dir = os.path.join(vault, "raw", "needs-review")
        legal = set(os.listdir(legal_dir)) if os.path.isdir(legal_dir) else set()
        review = set(os.listdir(review_dir)) if os.path.isdir(review_dir) else set()

        # crypto: never touched
        for k in ("fiel.key", "santiago.pem", "llave-privada.bin"):
            check(k in present, f"crypto {k} NOT trashed")
        check({"fiel.key", "santiago.pem", "llave-privada.bin"} <= set(s["kept_keys"]),
              "all crypto reported kept")

        # THE critical bug: underscore one-way names are SAVED, never lost
        for n in ("acta_constitutiva_2024.pdf", "RFC_2026.pdf"):
            check(n in trashed, f"{n} cleared")
            check(n in names(s["promoted"]), f"{n} was SAVED before clearing (not idle-trashed)")
            check(any(x.startswith(n.split('.')[0]) for x in legal), f"{n} saved into raw/legal/")

        # saved one-way: trashed, not re-saved
        check("contrato-x.pdf" in trashed, "saved one-way trashed")
        check("contrato-x.pdf" not in names(s["promoted"]), "saved one-way NOT re-saved")

        # empty/evicted vault copy not trusted -> saved fresh
        check("acuse-evicted.pdf" in trashed and "acuse-evicted.pdf" in names(s["promoted"]),
              "evicted-copy one-way SAVED fresh (empty copy not trusted)")

        # valuable UNKNOWN -> saved to needs-review, never destroyed unsaved
        check("weird-report.xyz" in trashed, "valuable unknown cleared")
        check(any(p["name"] == "weird-report.xyz" and "needs-review" in p["copy_path"]
                  for p in s["promoted"]), "valuable unknown SAVED to needs-review")

        # disposable idle -> trashed unsaved; disposable fresh -> kept
        check("screenshot.png" in trashed and "Installer.dmg" in trashed, "disposable idle trashed")
        check("fresh-pic.jpg" in present, "disposable fresh kept")

        # harvestable fresh -> aging
        check("fresh-note.txt" in present, "harvestable fresh kept (aging)")

        # 0-byte never verified-saved
        check("empty.dat" in present, "0-byte file NOT trashed as verified-saved")

        # partial download never acted on
        check("contrato-nuevo.pdf.part" in present, "partial download untouched")

        # future mtime -> kept, idle never negative
        check("from-the-future.pdf" in present, "future-mtime file kept")
        check(all(a["idle_days"] >= 0 for a in s["aging"]), "no negative idle_days")

        # symlink + directory never trashed
        check("shortcut" in present, "symlink NOT trashed")
        check("projectdir" in present, "directory NOT trashed")

        # audit ledger written, Obsidian-visible
        led = [f for f in os.listdir(os.path.join(vault, "wiki", "logs"))
               if f.startswith("downloads-trash-")]
        check(len(led) == 1, "audit ledger created")
        check(len(s["errors"]) == 0, "no errors")


def test_provenance_fallback_when_vault_unreadable():
    print("test: saved recognized via provenance ledger when vault reads denied")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        # Seed the provenance ledger with contrato's hash (as reconcile/harvest would).
        import hashlib
        h = hashlib.sha256(b"CONTRATO firmado unique bytes").hexdigest()
        with open(os.path.join(state, "downloads-provenance.jsonl"), "w") as f:
            f.write(json.dumps({"source_sha256": h, "origin": "reconcile"}) + "\n")
        # Make the vault unreadable (simulate launchd/TCC denial).
        arch = os.path.join(vault, "raw", "archive")
        os.chmod(arch, 0o000)
        try:
            s = run_engine(dl, vault, state, trash_cmd)
            trashed = {os.path.basename(p) for p in os.listdir(trash_dir)}
            check("contrato-x.pdf" in trashed, "saved-by-ledger file trashed despite vault denial")
            check("contrato-x.pdf" not in names(s["promoted"]), "ledger-saved file not re-saved")
            check(s.get("vault_reads_denied") is True, "vault-read denial surfaced in summary")
        finally:
            os.chmod(arch, 0o755)


def test_dry_run():
    print("test: dry-run mutates nothing")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        before = set(os.listdir(dl))
        s = run_engine(dl, vault, state, trash_cmd, extra=["--dry-run"])
        check(set(os.listdir(dl)) == before, "Downloads unchanged in dry-run")
        check(len(os.listdir(trash_dir)) == 0, "nothing trashed in dry-run")
        check(not os.path.isdir(os.path.join(vault, "raw", "legal")), "nothing saved in dry-run")
        check(len(s["trashed"]) > 0, "dry-run still REPORTS what it would do")


def test_idempotent():
    print("test: second run is safe (no double-action)")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        run_engine(dl, vault, state, trash_cmd)
        n = len(os.listdir(trash_dir))
        run_engine(dl, vault, state, trash_cmd)
        check(len(os.listdir(trash_dir)) == n, "second run trashes nothing new")


def write_proposal(state, entries, generated=None):
    path = os.path.join(state, "proposal.json")
    with open(path, "w") as f:
        json.dump({"generated": generated or datetime.date.today().isoformat(),
                   "files": entries}, f)
    return path


def test_proposal_clamp():
    print("test: LLM proposal is CLAMPED (can only make files safer)")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        prop = write_proposal(state, [
            {"name": "fiel.key", "recommendation": "disposable"},               # crypto floor
            {"name": "acta_constitutiva_2024.pdf", "recommendation": "disposable"},  # legal floor
            {"name": "weird-report.xyz", "recommendation": "disposable"},        # permitted downgrade
            {"name": "screenshot.png", "recommendation": "keep"},                # force-keep
            {"name": "ghost-not-real.pdf", "recommendation": "disposable"},      # hallucinated
        ])
        s = run_engine(dl, vault, state, trash_cmd, extra=["--proposal", prop])
        present = set(os.listdir(dl))
        trashed = {os.path.basename(p) for p in os.listdir(trash_dir)}

        check("fiel.key" in present and "fiel.key" in s["kept_keys"],
              "crypto kept despite LLM 'disposable' (crypto floor)")
        check("acta_constitutiva_2024.pdf" in names(s["promoted"]),
              "pattern-matched legal SAVED despite LLM 'disposable' (legal floor)")
        check("weird-report.xyz" in trashed and "weird-report.xyz" not in names(s["promoted"]),
              "ambiguous 'valuable' downgraded to disposable by LLM (the one permitted downgrade)")
        check("screenshot.png" in present and "screenshot.png" not in trashed,
              "idle disposable KEPT because LLM said 'keep'")
        check("ghost-not-real.pdf" not in trashed and "ghost-not-real.pdf" not in names(s["promoted"]),
              "hallucinated filename in proposal causes NO action")


def test_proposal_upgrade():
    print("test: LLM proposal can upgrade protection")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, _ = fake_trash(root)
        prop = write_proposal(state, [
            {"name": "weird-report.xyz", "recommendation": "save-legal"},
            {"name": "Installer.dmg", "recommendation": "save-review"},
        ])
        s = run_engine(dl, vault, state, trash_cmd, extra=["--proposal", prop])
        check(any(p["name"] == "weird-report.xyz" and "legal" in p["copy_path"]
                  for p in s["promoted"]), "valuable upgraded to save-legal -> raw/legal/")
        check(any(p["name"] == "Installer.dmg" and "needs-review" in p["copy_path"]
                  for p in s["promoted"]), "disposable upgraded to save-review -> needs-review/")


def test_proposal_malformed_and_stale():
    print("test: malformed/stale proposal is ignored (deterministic fallback)")
    with tempfile.TemporaryDirectory() as root:
        dl, vault, state = setup(root)
        trash_cmd, trash_dir = fake_trash(root)
        bad = os.path.join(state, "bad.json")
        with open(bad, "w") as f:
            f.write("{not valid json,,,")
        s = run_engine(dl, vault, state, trash_cmd, extra=["--proposal", bad])
        # falls back to deterministic: weird-report.xyz -> saved to needs-review
        check(any(p["name"] == "weird-report.xyz" and "needs-review" in p["copy_path"]
                  for p in s["promoted"]), "malformed proposal -> deterministic default holds")
        # stale proposal (yesterday) ignored
        with tempfile.TemporaryDirectory() as root2:
            dl2, vault2, state2 = setup(root2)
            tc2, _ = fake_trash(root2)
            stale = write_proposal(state2, [{"name": "screenshot.png", "recommendation": "keep"}],
                                   generated="2020-01-01")
            s2 = run_engine(dl2, vault2, state2, tc2, extra=["--proposal", stale])
            present2 = set(os.listdir(dl2))
            check("screenshot.png" not in present2, "stale proposal ignored (screenshot still aged out)")


def test_classify_unit():
    print("test: classify() unit cases")
    import importlib.util
    spec = importlib.util.spec_from_file_location("pd", ENGINE)
    pd = importlib.util.module_from_spec(spec); spec.loader.exec_module(pd)
    cases = {
        "acta_constitutiva_2024.pdf": "oneway", "RFC_2026.pdf": "oneway",
        "nda_acme_signed.pdf": "oneway", "estado de cuenta junio.pdf": "oneway",
        "cheque pala.pdf": "oneway", "transferencia_spei.pdf": "oneway",
        "fiel.pem": "key", "csd-sello.cer": "key", "llave_privada.txt": "key",
        "screenshot 2026.png": "disposable", "Installer.dmg": "disposable",
        "backup.zip": "disposable", "notes.txt": "harvestable",
        "random-thing.xyz": "valuable", "research-paper.pdf": "valuable",
    }
    for name, expect in cases.items():
        got = pd.classify(name)
        check(got == expect, f"classify({name!r}) == {expect} (got {got})")


if __name__ == "__main__":
    test_real_run()
    test_provenance_fallback_when_vault_unreadable()
    test_dry_run()
    test_idempotent()
    test_proposal_clamp()
    test_proposal_upgrade()
    test_proposal_malformed_and_stale()
    test_classify_unit()
    print(f"\n{PASS} passed, {FAIL} failed")
    sys.exit(1 if FAIL else 0)
