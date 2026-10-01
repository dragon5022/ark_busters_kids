"""Sync game art from the web pack into assets/images as WebP.

Source of truth is the web pack ("app illust" folder). If an AI-upscaled copy
exists in UPSCALED (see C:/dev/upscale/upscale.py), it is used instead of the
original. Output is WebP (quality 90, alpha kept) to keep the app small.

Re-run any time; only changed files are rewritten.

    python tools/sync_images.py
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT.parent / "ark-english-busters-20260910T174320Z-1-001" / "ark-english-busters" / "app illust"
UPSCALED = Path("C:/dev/upscale/out")
ASSETS = ROOT / "assets" / "images"
STATE = UPSCALED / "sync_state.json"

# web pack folder -> assets/images folder
FOLDERS = {
    "top images": "hub",
    "story": "story",
    "vocaimages": "monsters/vocamon",
    "lisimages": "monsters/lismon",
    "graimages": "monsters/gramon",
    "talkimages": "monsters/talkmon",
    ".": "misc",  # loose files at the pack root (f-talk.png, character art…)
}
# Art that exists only on the live site (https://arkbusters-kids.netlify.app),
# not in the web pack: encounter pop-ups, and images embedded as base64 in
# the live game pages. Downloaded to LIVE_ASSETS.
LIVE_ASSETS = Path("C:/dev/upscale/live_assets")
LIVE = {
    "voca pop t.png": "misc/voca pop t.webp",
    "lis pop t.png": "misc/lis pop t.webp",
    "gra pop t.png": "misc/gra pop t.webp",
    "talk pop t.png": "misc/talk pop t.webp",
    "b64_lis_0.png": "monsters/lismon/lismon-battle.webp",  # transparent battle art
    "b64_sen_0.png": "monsters/gramon/gramon-coin.webp",  # round battle medallion
}
EXTS = {".png", ".jpg", ".jpeg", ".webp"}
QUALITY = 90


def save_webp(src: Path, dst: Path):
    im = Image.open(src)
    im = im.convert("RGBA") if im.mode in ("RGBA", "LA", "P") else im.convert("RGB")
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, "WEBP", quality=QUALITY, method=4)


def main():
    state = json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {}
    jobs = []  # (original, upscaled, dst)
    for pack_dir, dest in FOLDERS.items():
        for p in sorted((PACK / pack_dir).iterdir()):
            if not p.is_file() or p.suffix.lower() not in EXTS or p.name.startswith("_"):
                continue
            up = UPSCALED / "pack" / pack_dir / (p.stem + ".png")
            jobs.append((p, up, ASSETS / dest / (p.stem + ".webp")))
    for name, dest in LIVE.items():
        p = LIVE_ASSETS / name
        if p.exists():
            jobs.append((p, UPSCALED / "live" / (p.stem + ".png"), ASSETS / dest))
    # Vocabulary word pictures were extracted from the web HTML (export_vocab.py)
    for p in sorted((ASSETS / "vocab").glob("*")):
        if p.suffix.lower() in {".jpg", ".jpeg", ".png"}:
            jobs.append((p, UPSCALED / "vocab" / (p.stem + ".png"), ASSETS / "vocab" / (p.stem + ".webp")))

    written = upscaled = 0
    for orig, up, dst in jobs:
        src = up if up.exists() else orig
        key = dst.relative_to(ASSETS).as_posix()
        sig = f"{src}|{src.stat().st_mtime_ns}"
        if dst.exists() and state.get(key) == sig:
            upscaled += src == up
            continue
        save_webp(src, dst)
        state[key] = sig
        written += 1
        upscaled += src == up

    # Old PNG copies in managed folders are superseded by the WebP files.
    removed = 0
    for dest in FOLDERS.values():
        for p in (ASSETS / dest).glob("*.png"):
            p.unlink()
            removed += 1

    # Point vocab.json at the WebP files.
    vj = ROOT / "assets" / "data" / "vocab.json"
    data = json.loads(vj.read_text(encoding="utf-8"))
    for item in data.get("items", []):
        img = item.get("img") or ""
        if img.startswith("images/vocab/"):
            item["img"] = str(Path(img).with_suffix(".webp").as_posix())
    vj.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    UPSCALED.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(jobs)} images: {written} written, {upscaled} from upscaled, "
          f"{len(jobs) - upscaled} still original; removed {removed} old PNGs")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
