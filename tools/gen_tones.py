"""Render the web games' Web Audio beeps (tone()) to WAV assets.

The web builds these sounds live with OscillatorNode; the app plays them as
files. Each note mirrors `tone(freq, start, dur, type, vol)`: gain ramps
exponentially from 0.0001 to vol in 20ms, then back to 0.0001 at start+dur.
Waveforms are band-limited (additive) like Web Audio's oscillators.

    python tools/gen_tones.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"


def osc(kind, f, t):
    if kind == "sine":
        return math.sin(2 * math.pi * f * t)
    nyq = RATE / 2
    s, n = 0.0, 1
    while n * f < nyq:
        ph = 2 * math.pi * n * f * t
        if kind == "square" and n % 2:
            s += math.sin(ph) / n * 4 / math.pi
        elif kind == "sawtooth":
            s += (-1) ** (n + 1) * math.sin(ph) / n * 2 / math.pi
        elif kind == "triangle" and n % 2:
            s += (-1) ** ((n - 1) // 2) * math.sin(ph) / (n * n) * 8 / math.pi ** 2
        n += 1
    return s


def gain(t, d, v):
    lo = 0.0001
    if t < 0.02:
        return lo * (v / lo) ** (t / 0.02)
    if t < d:
        return v * (lo / v) ** ((t - 0.02) / (d - 0.02))
    return 0.0


def render(name, notes):
    """notes: [(freq, start, dur, type, vol)]"""
    length = max(s + d + 0.06 for _, s, d, _, _ in notes)
    buf = [0.0] * int(length * RATE)
    for f, s, d, kind, v in notes:
        i0 = int(s * RATE)
        for i in range(int((d + 0.05) * RATE)):
            t = i / RATE
            buf[i0 + i] += osc(kind, f, s + t) * gain(t, d, v)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        # Absolute level like Web Audio (gain 0.35 = 35% full scale).
        w.writeframes(b"".join(
            struct.pack("<h", max(-32767, min(32767, int(x * 32767)))) for x in buf))
    print(name, f"{length:.2f}s")


OK = [(f, i * 0.06, 0.18, "triangle", 0.35) for i, f in enumerate([523, 659, 784, 1047])]

SOUNDS = {
    # sndOK (all games; plays together with music/correct.mp3)
    "tone_ok": OK,
    # listening sndCorrect adds a sparkle on top
    "tone_ok_sparkle": OK + [(1568, 0.26, 0.25, "sine", 0.22)],
    # vocabulary sndNG
    "tone_ng": [(180, 0, 0.12, "square", 0.3), (140, 0.12, 0.18, "square", 0.32)],
    # listening / sentence / talk sndWrong
    "tone_wrong": [(180, 0, 0.12, "square", 0.3), (150, 0.12, 0.18, "square", 0.32)],
    # vocabulary sndFan (win fanfare)
    "tone_fanfare": [(f, t, 0.35, "triangle", 0.4) for f, t in [(523, 0), (659, 0.12), (784, 0.24), (1047, 0.4)]],
    # listening sndTimeUp
    "tone_timeup": [(f, t, 0.3, "sawtooth", 0.28) for f, t in [(440, 0), (392, 0.18), (330, 0.36), (262, 0.55)]],
}

if __name__ == "__main__":
    for name, notes in SOUNDS.items():
        render(name, notes)
