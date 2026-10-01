"""Export the Listening Buster question pack (web LEVELS) → assets/data/listening.json.

Mirrors the LIVE page (arkbusters-kids.netlify.app, listening-buster_無料版.html):
  * questions come from `const LEVELS={...}` (200 questions: g5/g4/g3 × Lv0-3),
  * each question keeps its index in the ORIGINAL array (the web's
    `LEVELS[g][lv].indexOf(q)`), which is the recorded-voice key,
  * the live `loadQuestion()` swaps the audio level for 英検3級 Lv0 ↔ Lv1
    (`if(g==='g3'&&(lv===0||lv===1)) alv = lv===0 ? 1 : 0`),
  * `playLis()` tries `voice/lisOK/<key>.mp3`, then `<key>_r.mp3`, then TTS.
The live `voice/lisOK/` clips are stored in assets/audio/voice/lis/ (same names).

Usage:  python tools/export_listening.py [path/to/listening-buster.html]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WEB_HTML = Path(
    r"C:\code\educationApp\ark-english-busters-20260910T174320Z-1-001"
    r"\ark-english-busters\リスニングアプリ_無料版200問\listening-buster_無料版.html"
)
DATA = ROOT / "assets" / "data" / "listening.json"
VOICE = ROOT / "assets" / "audio" / "voice" / "lis"


def load_levels(html: Path) -> dict:
    text = html.read_text(encoding="utf-8", errors="ignore")
    start = text.index("const LEVELS=") + len("const LEVELS=")
    # The literal is plain JSON; decode just the first value.
    obj, _ = json.JSONDecoder().raw_decode(text[start:])
    return obj


def audio_level(grade: str, lv: int) -> int:
    if grade == "g3" and lv in (0, 1):
        return 1 if lv == 0 else 0
    return lv


def voice_for(grade: str, lv: int, i: int) -> str | None:
    key = f"{grade}_{audio_level(grade, lv)}_{i}"
    for name in (f"{key}.mp3", f"{key}_r.mp3"):
        if (VOICE / name).exists():
            return f"audio/voice/lis/{name}"
    return None


def main() -> None:
    html = Path(sys.argv[1]) if len(sys.argv) > 1 else WEB_HTML
    levels = load_levels(html)
    pack = {
        "version": 2,
        "qn": 10,  # PICK_COUNT
        "winRatio": 0.6,
        "timeByLevel": {"0": 0, "1": 8, "2": 12, "3": 14},  # LV_META[lv].time
        "livesByLevel": {"0": 5, "1": 3, "2": 3, "3": 3},  # level===0 ? 5 : 3
        "grades": {},
    }
    total = 0
    missing = []
    for grade in ("g5", "g4", "g3"):
        lvmap = levels[grade]
        pack["grades"][grade] = {"levels": {}}
        for lv in sorted(lvmap, key=int):
            items = []
            for i, it in enumerate(lvmap[lv]):
                voice = voice_for(grade, int(lv), i)
                if voice is None:
                    missing.append(f"{grade}_{lv}_{i}")
                items.append(
                    {
                        "id": f"{grade}_{lv}_{i}",
                        "t": it.get("t", "pic"),
                        "en": it.get("en", ""),
                        "ja": it.get("ja", ""),
                        "tip": it.get("tip", ""),
                        "ans": it.get("ans", ""),
                        "opts": it.get("opts", []),
                        "q": it.get("q"),
                        "voice": voice,
                    }
                )
                total += 1
            pack["grades"][grade]["levels"][str(lv)] = items
    DATA.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("listening questions:", total, "| missing voice:", missing or "none")


if __name__ == "__main__":
    main()
