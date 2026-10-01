"""Export listening / talk / sentence question packs from web HTML → assets/data."""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

WEB = Path(
    r"E:\Task Space\mobile for learning app\New folder"
    r"\ark-english-busters-20260910T174320Z-1-001\ark-english-busters"
)
OUT = Path(r"E:\Task Space\mobile for learning app\New folder\ark_busters_kids")
DATA = OUT / "assets" / "data"
VOICE = OUT / "assets" / "audio" / "voice"
DATA.mkdir(parents=True, exist_ok=True)


def extract_js_assign(text: str, names: list[str]) -> str:
    """Extract first `NAME = {...}` or `NAME = [...]` object/array literal."""
    for name in names:
        m = re.search(rf"(?:const|var|let)\s+{name}\s*=\s*([\[{{])", text)
        if not m:
            continue
        start = m.start(1)
        opener = text[start]
        closer = "]" if opener == "[" else "}"
        i = start
        depth = 0
        in_str = False
        esc = False
        quote = ""
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
                elif c == opener:
                    depth += 1
                elif c == closer:
                    depth -= 1
                    if depth == 0:
                        return text[start : i + 1]
                elif opener == "{" and c == "[" and depth == 0:
                    pass
                elif opener == "{" and c in "[]":
                    # nested arrays inside object — track separately using bracket stack
                    pass
            i += 1
        raise SystemExit(f"unclosed {name}")
    raise SystemExit(f"none of {names} found")


def extract_balanced(text: str, start: int) -> str:
    opener = text[start]
    assert opener in "[{"
    closers = {"[": "]", "{": "}"}
    closer = closers[opener]
    i = start
    depth = 0
    in_str = False
    esc = False
    quote = ""
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
            elif c in "[{":
                depth += 1
            elif c in "]}":
                depth -= 1
                if depth == 0:
                    return text[start : i + 1]
        i += 1
    raise SystemExit("unbalanced")


def find_assign(text: str, names: list[str]) -> str:
    for name in names:
        m = re.search(rf"(?:const|var|let)\s+{name}\s*=\s*([\[{{])", text)
        if m:
            return extract_balanced(text, m.start(1))
    raise SystemExit(f"none of {names}")


def js_to_json(raw: str) -> object:
    """Best-effort JS object → JSON. Prefer raw JSON when already valid."""
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        pass
    s = raw
    out: list[str] = []
    i = 0
    in_str = False
    esc = False
    quote = ""

    def last_non_ws() -> str:
        for ch in reversed(out):
            if not ch.isspace():
                return ch
        return ""

    while i < len(s):
        c = s[i]
        if in_str:
            if esc:
                # JS \' inside "..." → '
                out.append(c)
                esc = False
                i += 1
                continue
            if c == "\\":
                nxt = s[i + 1] if i + 1 < len(s) else ""
                if quote == '"' and nxt == "'":
                    out.append("'")
                    i += 2
                    continue
                esc = True
                out.append(c)
                i += 1
                continue
            if c == quote:
                in_str = False
            out.append(c)
            i += 1
            continue
        if c in "\"'":
            in_str = True
            quote = c
            if c == "'":
                out.append('"')
                i += 1
                while i < len(s):
                    ch = s[i]
                    if ch == "\\" and i + 1 < len(s):
                        out.append(s[i + 1])
                        i += 2
                        continue
                    if ch == "'":
                        out.append('"')
                        i += 1
                        in_str = False
                        break
                    if ch == '"':
                        out.append('\\"')
                        i += 1
                        continue
                    out.append(ch)
                    i += 1
                continue
            out.append(c)
            i += 1
            continue
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", s[i:])
        if m and last_non_ws() in "{[,":
            out.append('"' + m.group(1) + '":')
            i += m.end()
            continue
        out.append(c)
        i += 1
    s2 = "".join(out)
    s2 = re.sub(r",\s*([}\]])", r"\1", s2)
    return json.loads(s2)


def copy_voice_dir(src_name: str, dst_name: str) -> int:
    src = WEB / "voice" / src_name
    dst = VOICE / dst_name
    dst.mkdir(parents=True, exist_ok=True)
    n = 0
    if not src.exists():
        print("missing voice", src)
        return 0
    for f in src.iterdir():
        if f.is_file():
            shutil.copy2(f, dst / f.name)
            n += 1
    print("copied voice", src_name, "→", dst_name, n)
    return n


def export_listening() -> None:
    html = next(WEB.glob("**/listening-buster*.html"))
    text = html.read_text(encoding="utf-8", errors="ignore")
    levels = js_to_json(find_assign(text, ["LEVELS"]))
    pack = {
        "version": 1,
        "qn": 10,
        "winRatio": 0.6,
        "timeByLevel": {"0": 0, "1": 8, "2": 12, "3": 14},
        "livesByLevel": {"0": 5, "1": 3, "2": 3, "3": 3},
        "grades": {},
    }
    total = 0
    for grade, lvmap in levels.items():
        gkey = grade if grade.startswith("g") else f"g{grade}"
        pack["grades"][gkey] = {"levels": {}}
        for lv, items in lvmap.items():
            out_items = []
            for i, it in enumerate(items):
                out_items.append(
                    {
                        "id": f"{gkey}_{lv}_{i}",
                        "t": it.get("t", "pic"),
                        "en": it.get("en", ""),
                        "ja": it.get("ja", ""),
                        "tip": it.get("tip", ""),
                        "ans": it.get("ans", ""),
                        "opts": it.get("opts", []),
                        "q": it.get("q"),
                        "voice": f"audio/voice/lis/{gkey}_{lv}_{i}.mp3",
                    }
                )
                total += 1
            pack["grades"][gkey]["levels"][str(lv)] = out_items
    (DATA / "listening.json").write_text(
        json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("listening items", total)
    copy_voice_dir("lis", "lis")


def export_talk() -> None:
    html = next(WEB.glob("**/talk-buster*.html"))
    text = html.read_text(encoding="utf-8", errors="ignore")
    talk = js_to_json(find_assign(text, ["TALK"]))
    pack = {"version": 1, "qn": 10, "winRatio": 0.6, "grades": {}}
    offset = {"g5": 0, "g4": 12, "g3": 24}
    total = 0
    for grade, items in talk.items():
        gkey = grade if str(grade).startswith("g") else f"g{grade}"
        out = []
        base = offset.get(gkey, 0)
        for i, it in enumerate(items):
            out.append(
                {
                    "id": f"{gkey}_{i}",
                    "ja": it["ja"],
                    "en": it["en"],
                    "voice": f"audio/voice/talk/{base + i + 1}.mp3",
                }
            )
            total += 1
        pack["grades"][gkey] = out
    (DATA / "talk.json").write_text(
        json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("talk items", total)
    copy_voice_dir("talk", "talk")


def export_sentence() -> None:
    html = next(WEB.glob("**/english-busters*.html"))
    text = html.read_text(encoding="utf-8", errors="ignore")
    levels = js_to_json(find_assign(text, ["LEVELS"]))
    # optional GRAMPARTS
    gramparts = {}
    try:
        gramparts = js_to_json(find_assign(text, ["GRAMPARTS"]))
    except SystemExit:
        pass
    pack = {
        "version": 1,
        "qn": 10,
        "winRatio": 0.6,
        "timeByGrade": {"g5": 6, "g4": 9, "g3": 12},
        "gramParts": gramparts,
        "grades": {},
    }
    offset = {"g5": 0, "g4": 18, "g3": 30}
    total = 0
    for grade, items in levels.items():
        gkey = grade if str(grade).startswith("g") else f"g{grade}"
        out = []
        base = offset.get(gkey, 0)
        for i, it in enumerate(items):
            out.append(
                {
                    "id": f"{gkey}_{i}",
                    "ja": it.get("ja", []),
                    "answer": it.get("answer", []),
                    "tip": it.get("tip", ""),
                    "voice": f"audio/voice/gram/{base + i + 1}.mp3",
                }
            )
            total += 1
        pack["grades"][gkey] = out
    (DATA / "sentence.json").write_text(
        json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("sentence items", total)
    copy_voice_dir("gram", "gram")
    if (WEB / "voice" / "gramparts").exists():
        copy_voice_dir("gramparts", "gramparts")


def update_manifest() -> None:
    path = DATA / "manifest.json"
    man = {
        "appMinBuild": 1,
        "packs": {
            "vocab": {"version": 1, "bundled": "data/vocab.json", "url": "", "sha256": ""},
            "listening": {
                "version": 1,
                "bundled": "data/listening.json",
                "url": "",
                "sha256": "",
            },
            "talk": {"version": 1, "bundled": "data/talk.json", "url": "", "sha256": ""},
            "sentence": {
                "version": 1,
                "bundled": "data/sentence.json",
                "url": "",
                "sha256": "",
            },
        },
    }
    path.write_text(json.dumps(man, ensure_ascii=False, indent=2), encoding="utf-8")
    print("manifest updated")


if __name__ == "__main__":
    export_listening()
    export_talk()
    export_sentence()
    update_manifest()
    print("done")
