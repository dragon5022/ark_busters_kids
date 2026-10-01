"""Extract VOCAB array from vocabulary-busters HTML → vocab.json + image files."""
import json
import re
import base64
from pathlib import Path

html_path = Path(
    r"E:\Task Space\mobile for learning app\New folder"
    r"\ark-english-busters-20260910T174320Z-1-001\ark-english-busters"
    r"\ボキャブラリー_無料版\vocabulary-busters_無料版.html"
)
out_dir = Path(
    r"E:\Task Space\mobile for learning app\New folder\ark_busters_kids"
)
data_dir = out_dir / "assets" / "data"
img_dir = out_dir / "assets" / "images" / "vocab"
data_dir.mkdir(parents=True, exist_ok=True)
img_dir.mkdir(parents=True, exist_ok=True)

text = html_path.read_text(encoding="utf-8", errors="ignore")
# Find VOCAB=[...]
m = re.search(r"VOCAB\s*=\s*(\[)", text)
if not m:
    raise SystemExit("VOCAB not found")
start = m.start(1)
# Bracket match
i = start
depth = 0
in_str = False
esc = False
quote = ""
end = None
while i < len(text):
    c = text[i]
    if in_str:
        if esc:
            esc = False
        elif c == "\\":
            esc = True
        elif c == quote:
            in_str = False
    else:
        if c in "\"'":
            in_str = True
            quote = c
        elif c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    i += 1

raw = text[start:end]
# JS object keys are unquoted sometimes — VOCAB uses JSON-like with quoted keys
vocab = json.loads(raw)
print("parsed", len(vocab))

items = []
for idx, v in enumerate(vocab, start=1):
    img_field = v.get("img", "")
    rel_img = None
    if isinstance(img_field, str) and img_field.startswith("data:image"):
        # data:image/jpeg;base64,...
        header, b64 = img_field.split(",", 1)
        ext = "jpg"
        if "png" in header:
            ext = "png"
        elif "webp" in header:
            ext = "webp"
        fname = f"{idx:03d}.{ext}"
        (img_dir / fname).write_bytes(base64.b64decode(b64))
        rel_img = f"images/vocab/{fname}"
    items.append(
        {
            "id": idx,
            "w": v["w"],
            "ja": v["ja"],
            "lv": int(v["lv"]),
            "img": rel_img,
            "voice": f"audio/voice/voca/{idx}.mp3",
        }
    )

pack = {
    "version": 1,
    "packId": "vocab",
    "qn": 10,
    "timeByLevel": {"1": 5, "2": 7, "3": 10},
    "winRatio": 0.6,
    "items": items,
}
out_json = data_dir / "vocab.json"
out_json.write_text(json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8")
print("wrote", out_json, "items", len(items), "imgs", len(list(img_dir.glob("*"))))

# Manifest for remote content updates
manifest = {
    "appMinBuild": 1,
    "packs": {
        "vocab": {
            "version": 1,
            "bundled": "data/vocab.json",
            "url": "",
            "sha256": "",
        }
    },
}
(data_dir / "manifest.json").write_text(
    json.dumps(manifest, indent=2), encoding="utf-8"
)
print("wrote manifest")
