#!/usr/bin/env python3
"""Generador de música "pixel soft" (chiptune suave) para Campeones de los valores.

No requiere dependencias externas. Genera dos loops WAV (mono, 16-bit, 22050 Hz):
  - assets/audio/music_menu.wav  -> tema tranquilo para el menú de inicio
  - assets/audio/music_game.wav  -> tema alegre para el nivel

Uso:  python3 tools/generate_music.py
"""
import math
import os
import struct
import wave
from array import array

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

NOTE_INDEX = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
              "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def freq(note: str) -> float:
    """'A4' -> 440.0"""
    name, octave = note[:-1], int(note[-1])
    midi = 12 * (octave + 1) + NOTE_INDEX[name]
    return 440.0 * 2 ** ((midi - 69) / 12)


# ---------- Osciladores suaves ----------
def osc_triangle(phase):
    return 4.0 * abs(phase - math.floor(phase + 0.5)) - 1.0


def osc_pulse(phase, duty=0.25):
    # Pulso con bordes suavizados (menos áspero que un cuadrado puro)
    p = phase % 1.0
    edge = 0.02
    if p < edge:
        return p / edge
    if p < duty - edge:
        return 1.0
    if p < duty + edge:
        return 1.0 - (p - (duty - edge)) / edge * 2
    if p < 1.0 - edge:
        return -1.0
    return -1.0 + (p - (1.0 - edge)) / edge


def envelope(t, dur, attack=0.02, release=0.12, sustain=0.75):
    if t < attack:
        return t / attack
    decay = 0.08
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    if t > dur - release:
        return max(0.0, sustain * (dur - t) / release)
    return sustain


def render_note(buf, start, dur, f, vol, kind="pulse", duty=0.25,
                vibrato=0.0, attack=0.02, release=0.12):
    n0 = int(start * RATE)
    n = int(dur * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        vib = 1.0 + vibrato * math.sin(2 * math.pi * 5.5 * t) * min(1.0, t * 4)
        phase += f * vib / RATE
        if kind == "pulse":
            s = osc_pulse(phase, duty)
        elif kind == "tri":
            s = osc_triangle(phase)
        else:
            s = math.sin(2 * math.pi * phase)
        idx = n0 + i
        if idx < len(buf):
            buf[idx] += s * vol * envelope(t, dur, attack, release)


def render_noise_hat(buf, start, vol=0.05, dur=0.04):
    # Hi-hat suave con ruido pseudoaleatorio determinista
    n0 = int(start * RATE)
    seed = 12345 + n0
    for i in range(int(dur * RATE)):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        s = (seed / 0x3FFFFFFF) - 1.0
        e = 1.0 - i / (dur * RATE)
        if n0 + i < len(buf):
            buf[n0 + i] += s * vol * e * e


def render_kick(buf, start, vol=0.35):
    n0 = int(start * RATE)
    phase = 0.0
    dur = 0.12
    for i in range(int(dur * RATE)):
        t = i / RATE
        f = 120 * (1 - t / dur) + 45
        phase += f / RATE
        e = (1 - t / dur) ** 2
        if n0 + i < len(buf):
            buf[n0 + i] += math.sin(2 * math.pi * phase) * vol * e


def song(bpm, chords, melody, arp=True, drums=True, lead_duty=0.25):
    """chords: lista de (raíz_bajo, [notas acorde]) por compás (4 tiempos).
    melody: lista de (nota|None, duración_en_tiempos)."""
    beat = 60.0 / bpm
    bars = len(chords)
    total = bars * 4 * beat
    buf = [0.0] * int(total * RATE + RATE * 0.01)

    for b, (bass, notes) in enumerate(chords):
        bar_t = b * 4 * beat
        # Bajo triangular: raíz en tiempos 1 y 3, quinta suave en 2 y 4
        for k in range(4):
            note = bass if k % 2 == 0 else notes[2 % len(notes)].replace(
                notes[2 % len(notes)][-1], str(int(bass[-1])))
            render_note(buf, bar_t + k * beat, beat * 0.9, freq(note), 0.22,
                        kind="tri", release=0.08)
        # Arpegio de corcheas (pulso 12.5%, muy bajito)
        if arp:
            seq = notes + notes[-2:0:-1]
            for k in range(8):
                render_note(buf, bar_t + k * beat / 2, beat / 2 * 0.85,
                            freq(seq[k % len(seq)]), 0.06, kind="pulse",
                            duty=0.125, attack=0.005, release=0.05)
        if drums:
            for k in range(4):
                if k in (0, 2):
                    render_kick(buf, bar_t + k * beat, 0.28)
                render_noise_hat(buf, bar_t + k * beat + beat / 2, 0.035)

    t = 0.0
    for note, beats in melody:
        d = beats * beat
        if note:
            render_note(buf, t, d * 0.92, freq(note), 0.13, kind="pulse",
                        duty=lead_duty, vibrato=0.006, attack=0.015,
                        release=min(0.15, d * 0.4))
        t += d

    # Eco suave (delay) para dar sensación "soft"
    delay = int(beat * 0.75 * RATE)
    out = buf[:]
    for i in range(delay, len(out)):
        out[i] += out[i - delay] * 0.22

    # Filtro paso-bajo de un polo para redondear el sonido
    alpha = 0.55
    y = 0.0
    for i in range(len(out)):
        y += alpha * (out[i] - y)
        out[i] = y

    # Normalizar y suavizar extremos para que el loop no haga "click"
    peak = max(1e-6, max(abs(s) for s in out))
    gain = 0.8 / peak
    fade = int(0.01 * RATE)
    for i in range(fade):
        out[i] *= i / fade
        out[-1 - i] *= i / fade
    return [s * gain for s in out]


def write_wav(path, samples):
    data = array("h", (int(max(-1.0, min(1.0, s)) * 32767) for s in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(f"OK {path} ({len(samples) / RATE:.1f}s)")


def menu_theme():
    # Tranquilo, 84 BPM, I - vi - IV - V en Do mayor (x2)
    C = ("C3", ["C4", "E4", "G4"])
    Am = ("A2", ["A3", "C4", "E4"])
    F = ("F2", ["F3", "A3", "C4"])
    G = ("G2", ["G3", "B3", "D4"])
    chords = [C, Am, F, G] * 2
    melody = [
        ("E5", 1), ("G5", 1), ("E5", 1), ("C5", 1),
        ("C5", 1), ("E5", 1), ("A4", 2),
        ("A4", 1), ("C5", 1), ("F5", 1), ("E5", 1),
        ("D5", 2), ("B4", 1), ("D5", 1),
        ("E5", 1.5), ("D5", 0.5), ("C5", 1), ("G4", 1),
        ("A4", 1), ("C5", 1), ("E5", 2),
        ("F5", 1), ("E5", 1), ("C5", 1), ("A4", 1),
        ("B4", 1), ("D5", 1), ("C5", 2),
    ]
    return song(84, chords, melody, arp=True, drums=False, lead_duty=0.5)


def game_theme():
    # Alegre, 116 BPM, en Sol mayor: I - V - vi - IV / I - IV - V - I (x2)
    G = ("G2", ["G3", "B3", "D4"])
    D = ("D3", ["D4", "F#4", "A4"])
    Em = ("E2", ["E3", "G3", "B3"])
    C = ("C3", ["C4", "E4", "G4"])
    chords = [G, D, Em, C, G, C, D, G] * 2
    phrase_a = [
        ("B4", 0.5), ("D5", 0.5), ("G5", 1), ("F#5", 0.5), ("E5", 0.5), ("D5", 1),
        ("A4", 0.5), ("D5", 0.5), ("F#5", 1), ("E5", 0.5), ("D5", 0.5), ("A4", 1),
        ("B4", 0.5), ("E5", 0.5), ("G5", 1), ("F#5", 0.5), ("G5", 0.5), ("B5", 1),
        ("A5", 1), ("G5", 0.5), ("E5", 0.5), ("C5", 2),
    ]
    phrase_b = [
        ("D5", 0.5), ("B4", 0.5), ("G4", 1), ("B4", 0.5), ("D5", 0.5), ("G5", 1),
        ("E5", 0.5), ("G5", 0.5), ("C5", 1), ("E5", 1), (None, 1),
        ("F#5", 0.5), ("E5", 0.5), ("D5", 1), ("A4", 0.5), ("D5", 0.5), ("F#5", 1),
        ("G5", 1.5), ("D5", 0.5), ("G5", 2),
    ]
    melody = phrase_a + phrase_b + phrase_a + phrase_b
    return song(116, chords, melody, arp=True, drums=True, lead_duty=0.25)


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    write_wav(os.path.join(OUT_DIR, "music_menu.wav"), menu_theme())
    write_wav(os.path.join(OUT_DIR, "music_game.wav"), game_theme())
