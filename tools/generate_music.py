#!/usr/bin/env python3
"""Sintetizador procedural estilo Touhou Escolar + Undertale-Finale
para Campeones de los Valores (COBAEM CEMSaD 22 ENTHAVI).

Genera arreglos dinámicos diferenciados por:
  - Escenario / Contexto (Menú, 6 Exteriores, Salones, Jefe, Titanor Final)
  - Personaje seleccionado (_m = Masculino ZUN-trumpet/brass, _f = Femenino campana/flauta cristalina)
  - Dificultad (capa rítmica extra `music_hard_perc.wav` + ajuste dinámico de tempo/pitch en GameSettings)
  - Escena clímax 1 HP estilo Undertale (`music_finale_souls.wav`, composición original inspirada)

Sin dependencias externas (100% stdlib Python). Uso:
  python3 tools/generate_music.py
"""
import math
import os
import shutil
import wave
from array import array

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

NOTE_INDEX = {
    "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
    "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
    "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11,
}


def freq(note: str) -> float:
    name, octave = note[:-1], int(note[-1])
    midi = 12 * (octave + 1) + NOTE_INDEX[name]
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def osc_saw(phase: float) -> float:
    p = phase % 1.0
    return 2.0 * p - 1.0


def osc_pulse(phase: float, duty: float = 0.25) -> float:
    p = phase % 1.0
    edge = 0.03
    if p < edge:
        return p / edge
    if p < duty - edge:
        return 1.0
    if p < duty + edge:
        return 1.0 - (p - (duty - edge)) / edge * 2.0
    if p < 1.0 - edge:
        return -1.0
    return -1.0 + (p - (1.0 - edge)) / edge


def osc_tri(phase: float) -> float:
    return 4.0 * abs(phase - math.floor(phase + 0.5)) - 1.0


def adsr(t: float, dur: float, a: float = 0.012, d: float = 0.07, s: float = 0.72, r: float = 0.08) -> float:
    if t < a:
        return t / max(1e-5, a)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(1e-5, d))
    if t > dur - r:
        return max(0.0, s * ((dur - t) / max(1e-5, r)))
    return s


def add_voice(buf, start: float, dur: float, f: float, vol: float, voice: str = "zun_trumpet", vibrato: float = 0.005):
    n0 = int(start * RATE)
    n = int(dur * RATE)
    if n <= 0:
        return
    phase = 0.0
    phase2 = 0.0
    twopi = 2.0 * math.pi
    buf_len = len(buf)

    for i in range(n):
        idx = n0 + i
        if idx >= buf_len:
            break
        t = i / RATE
        vib = 1.0 + vibrato * math.sin(twopi * 5.8 * t) * min(1.0, t * 5.0)
        fv = f * vib
        phase += fv / RATE

        if voice == "zun_trumpet":
            phase2 += (fv * 1.003) / RATE
            raw = 0.60 * osc_saw(phase) + 0.40 * osc_pulse(phase2, 0.22)
            env = adsr(t, dur, 0.012, 0.06, 0.78, min(0.10, dur * 0.35))
        elif voice == "flute_synth":
            raw = 0.65 * math.sin(twopi * phase) + 0.25 * osc_tri(phase * 2.0) + 0.10 * osc_pulse(phase, 0.5)
            env = adsr(t, dur, 0.015, 0.05, 0.80, min(0.11, dur * 0.35))
        elif voice == "school_chime":
            p1 = math.sin(twopi * phase)
            p2 = math.sin(twopi * phase * 2.756) * math.exp(-t * 9.0) * 0.42
            p3 = math.sin(twopi * phase * 5.404) * math.exp(-t * 15.0) * 0.22
            raw = p1 + p2 + p3
            env = (1.0 - math.exp(-t * 180.0)) * math.exp(-t * 3.8)
        elif voice == "touhou_piano":
            raw = 0.55 * osc_tri(phase) + 0.30 * math.sin(twopi * phase * 2.0) + 0.15 * osc_pulse(phase, 0.15)
            env = (1.0 - math.exp(-t * 140.0)) * math.exp(-t * 4.5)
        elif voice == "hero_bass":
            raw = 0.65 * osc_tri(phase) + 0.35 * osc_saw(phase * 0.5)
            env = adsr(t, dur, 0.006, 0.05, 0.72, 0.04)
        elif voice == "strings":
            phase2 += (fv * 0.996) / RATE
            raw = 0.50 * osc_saw(phase) + 0.50 * osc_saw(phase2)
            env = adsr(t, dur, 0.035, 0.08, 0.85, min(0.14, dur * 0.35))
        elif voice == "ut_lead":
            phase2 += (fv * 1.004) / RATE
            raw = math.tanh((0.62 * osc_pulse(phase, 0.25) + 0.38 * osc_saw(phase2)) * 2.1)
            env = adsr(t, dur, 0.008, 0.045, 0.82, min(0.09, dur * 0.35))
        elif voice == "ut_bass":
            raw = 0.55 * osc_pulse(phase, 0.50) + 0.45 * osc_saw(phase * 0.5)
            env = adsr(t, dur, 0.005, 0.04, 0.78, min(0.05, dur * 0.30))
        elif voice == "ut_arp":
            raw = 0.70 * osc_pulse(phase, 0.125) + 0.30 * osc_tri(phase * 2.0)
            env = adsr(t, dur, 0.004, 0.03, 0.65, min(0.04, dur * 0.35))
        elif voice == "ut_pad":
            phase2 += (fv * 0.995) / RATE
            raw = 0.45 * osc_saw(phase) + 0.45 * osc_saw(phase2) + 0.10 * math.sin(twopi * phase * 2.0)
            env = adsr(t, dur, 0.045, 0.09, 0.84, min(0.16, dur * 0.35))
        else:
            raw = osc_pulse(phase, 0.25)
            env = adsr(t, dur, 0.006, 0.04, 0.62, 0.04)

        buf[idx] += raw * vol * env


def render_kick(buf, start: float, vol: float = 0.40):
    n0 = int(start * RATE)
    dur = 0.13
    n = int(dur * RATE)
    phase = 0.0
    twopi = 2.0 * math.pi
    buf_len = len(buf)
    for i in range(n):
        idx = n0 + i
        if idx >= buf_len:
            break
        t = i / RATE
        f = 135.0 * (1.0 - t / dur) ** 1.4 + 44.0
        phase += f / RATE
        env = (1.0 - t / dur) ** 2.2
        buf[idx] += math.sin(twopi * phase) * vol * env


def render_snare(buf, start: float, vol: float = 0.22):
    n0 = int(start * RATE)
    dur = 0.11
    n = int(dur * RATE)
    seed = 98765 + n0
    phase = 0.0
    twopi = 2.0 * math.pi
    buf_len = len(buf)
    for i in range(n):
        idx = n0 + i
        if idx >= buf_len:
            break
        t = i / RATE
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = (seed / 0x3FFFFFFF) - 1.0
        phase += 190.0 / RATE
        tone = math.sin(twopi * phase) * math.exp(-t * 28.0)
        env = math.exp(-t * 22.0)
        buf[idx] += (noise * 0.72 + tone * 0.28) * vol * env


def render_hat(buf, start: float, vol: float = 0.075, dur: float = 0.045):
    n0 = int(start * RATE)
    n = int(dur * RATE)
    seed = 45678 + n0
    buf_len = len(buf)
    prev = 0.0
    for i in range(n):
        idx = n0 + i
        if idx >= buf_len:
            break
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        raw = (seed / 0x3FFFFFFF) - 1.0
        hp = raw - prev * 0.75
        prev = raw
        e = (1.0 - i / n) ** 2
        buf[idx] += hp * vol * e


def finalize_loop(buf, beat: float, echo_mix: float = 0.18, lp_alpha: float = 0.52):
    out = buf[:]
    delay = max(1, int(beat * 0.75 * RATE))
    for i in range(delay, len(out)):
        out[i] += out[i - delay] * echo_mix

    # Low-pass suave para brillo equilibrado en bocinas de móvil
    y = 0.0
    for i in range(len(out)):
        y += lp_alpha * (out[i] - y)
        out[i] = y

    # Soft limiter ligero antes de normalizar
    for i in range(len(out)):
        out[i] = math.tanh(out[i] * 0.85)

    peak = max(1e-6, max(abs(s) for s in out))
    gain = 0.84 / peak
    fade = min(len(out) // 4, int(0.012 * RATE))
    for i in range(fade):
        w = i / max(1, fade)
        out[i] *= w
        out[-1 - i] *= w
    return [s * gain for s in out]


def write_wav(path: str, samples):
    data = array("h", (int(max(-1.0, min(1.0, s)) * 32767) for s in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    kb = os.path.getsize(path) / 1024.0
    print(f"  OK {os.path.basename(path):28s} {len(samples) / RATE:5.2f}s ({kb:6.1f} KB)")


def shift_octave(note: str, delta_oct: int) -> str:
    return note[:-1] + str(int(note[-1]) + delta_oct)


def build_touhou_school_track(
    bpm: float,
    chords: list,
    melody: list,
    char_variant: str = "m",
    bell_bars: bool = True,
    drum_energy: str = "touhou",
    bell_motif=None,
):
    beat = 60.0 / bpm
    bars = len(chords)
    total = bars * 4.0 * beat
    buf = [0.0] * (int(total * RATE) + 64)

    lead_voice = "zun_trumpet" if char_variant == "m" else "flute_synth"
    counter_voice = "touhou_piano" if char_variant == "m" else "school_chime"

    for b, (bass, triad) in enumerate(chords):
        bar_t = b * 4.0 * beat

        # Bajo octavado estilo Touhou en corcheas
        for k in range(8):
            note = bass if (k % 2 == 0) else shift_octave(bass, 1)
            add_voice(buf, bar_t + k * (beat * 0.5), beat * 0.44, freq(note), 0.22, voice="hero_bass", vibrato=0.0)

        # Acordes rítmicos de piano escolar
        chord_steps = [0.0, 1.0, 1.5, 2.5, 3.0]
        for cs in chord_steps:
            for n_note in triad:
                add_voice(buf, bar_t + cs * beat, beat * 0.36, freq(n_note), 0.065, voice="touhou_piano", vibrato=0.0)

        # Arpegios rápidos en semicorcheas (16ths) Touhou
        arp_seq = triad + [shift_octave(triad[0], 1)] + triad[::-1]
        for k in range(16):
            v_use = counter_voice if (char_variant == "f" and k % 4 == 0) else "arp"
            add_voice(
                buf,
                bar_t + k * (beat * 0.25),
                beat * 0.21,
                freq(arp_seq[k % len(arp_seq)]),
                0.068 if char_variant == "f" else 0.055,
                voice=v_use,
                vibrato=0.0,
            )

        # Campana escolar Westminster al inicio de frase
        if bell_bars and bell_motif and (b % 2 == 0):
            for idx_m, bn in enumerate(bell_motif):
                add_voice(buf, bar_t + idx_m * beat, beat * 1.15, freq(bn), 0.14, voice="school_chime", vibrato=0.0)

        # Percusión enérgica
        if drum_energy != "none":
            for k in range(4):
                bt = bar_t + k * beat
                if drum_energy == "menu":
                    if k in (0, 2):
                        render_kick(buf, bt, 0.26)
                    if k in (1, 3):
                        render_hat(buf, bt, 0.045, 0.04)
                else:
                    # Patrón Touhou Driving Beat
                    if k in (0, 2) or (drum_energy == "boss" and k == 3):
                        render_kick(buf, bt, 0.36)
                    if k in (1, 3):
                        render_snare(buf, bt, 0.22)
                    render_hat(buf, bt, 0.055, 0.035)
                    render_hat(buf, bt + beat * 0.5, 0.070, 0.040)
                    if drum_energy in ("touhou", "boss"):
                        render_hat(buf, bt + beat * 0.25, 0.035, 0.025)
                        render_hat(buf, bt + beat * 0.75, 0.040, 0.025)
                    if drum_energy == "boss" and k == 3 and (b % 2 == 1):
                        render_snare(buf, bt + beat * 0.5, 0.18)
                        render_snare(buf, bt + beat * 0.75, 0.20)

    # Melodía principal + armonía en tercera para Femenino o quinta sutil para Masculino
    t = 0.0
    for note, beats in melody:
        dur = beats * beat
        if note:
            n_up = shift_octave(note, 1) if (char_variant == "f" and int(note[-1]) < 5) else note
            add_voice(buf, t, dur * 0.92, freq(n_up), 0.19, voice=lead_voice, vibrato=0.0055)
            if char_variant == "f":
                add_voice(buf, t, dur * 0.75, freq(n_up), 0.07, voice="school_chime", vibrato=0.0)
        t += dur

    return finalize_loop(buf, beat, echo_mix=0.20 if char_variant == "f" else 0.16, lp_alpha=0.58 if char_variant == "f" else 0.50)


def build_hard_perc_overlay(bpm: float = 160.0):
    """Capa de percusión pura sin notas afinadas para intensificar la dificultad Difícil."""
    beat = 60.0 / bpm
    bars = 4
    buf = [0.0] * (int(bars * 4.0 * beat * RATE) + 64)
    for b in range(bars):
        bar_t = b * 4.0 * beat
        for k in range(4):
            bt = bar_t + k * beat
            render_kick(buf, bt, 0.25)
            render_snare(buf, bt + beat * 0.5, 0.16)
            for s16 in range(4):
                render_hat(buf, bt + s16 * (beat * 0.25), 0.065 if s16 % 2 == 1 else 0.035, 0.028)
        if b == 3:
            for s16 in range(4):
                render_snare(buf, bar_t + 3.0 * beat + s16 * (beat * 0.25), 0.12 + 0.04 * s16)
    return finalize_loop(buf, beat, echo_mix=0.08, lp_alpha=0.72)


def build_finale_souls_climax():
    """Composición original heroica-emotiva estilo clímax (184 BPM, Eb mayor / C menor).
    Transmite urgencia, esperanza y unión de los corazones de los valores sin copiar melodías externas."""
    bpm = 184.0
    beat = 60.0 / bpm
    Cm = ("C3", ["C4", "Eb4", "G4"])
    Ab = ("Ab2", ["Ab3", "C4", "Eb4"])
    Eb = ("Eb3", ["Eb4", "G4", "Bb4"])
    Bb = ("Bb2", ["Bb3", "D4", "F4"])
    Fm = ("F2", ["F3", "Ab3", "C4"])
    G7 = ("G2", ["G3", "B3", "D4"])

    chords = [Cm, Ab, Eb, Bb, Fm, Cm, Ab, G7, Cm, Ab, Eb, Bb, Ab, Bb, Cm, Eb]
    bars = len(chords)
    buf = [0.0] * (int(bars * 4.0 * beat * RATE) + 64)

    for b, (bass, triad) in enumerate(chords):
        bar_t = b * 4.0 * beat
        # Bajo galopante continuo
        for k in range(8):
            n = bass if k % 2 == 0 else shift_octave(bass, 1)
            add_voice(buf, bar_t + k * beat * 0.5, beat * 0.45, freq(n), 0.23, voice="hero_bass", vibrato=0.0)
        # Cuerdas heroicas sostenidas
        for sn in triad:
            add_voice(buf, bar_t, beat * 3.85, freq(sn), 0.075, voice="strings", vibrato=0.003)
        # Arpegios cristalinos rápidos en semicorcheas
        arp = triad + [shift_octave(triad[0], 1), shift_octave(triad[2], 1)]
        for k in range(16):
            add_voice(buf, bar_t + k * beat * 0.25, beat * 0.20, freq(arp[k % len(arp)]), 0.072, voice="touhou_piano", vibrato=0.0)
        # Batería épica constante
        for k in range(4):
            bt = bar_t + k * beat
            render_kick(buf, bt, 0.40)
            if k in (1, 3):
                render_snare(buf, bt, 0.26)
            render_hat(buf, bt, 0.05, 0.03)
            render_hat(buf, bt + beat * 0.5, 0.075, 0.035)
        if b in (7, 15):
            for s16 in range(4):
                render_snare(buf, bar_t + 3.0 * beat + s16 * beat * 0.25, 0.18 + s16 * 0.04)

    melody = [
        # Parte A: Tensión creciente y llamado de los corazones
        ("G5", 1.5), ("Eb5", 0.5), ("C5", 1.0), ("D5", 1.0),
        ("Eb5", 1.5), ("G5", 0.5), ("Ab5", 1.0), ("G5", 1.0),
        ("Bb5", 1.5), ("G5", 0.5), ("Eb5", 1.0), ("F5", 1.0),
        ("D5", 2.0), ("Bb4", 1.0), ("D5", 1.0),

        ("C5", 1.0), ("Eb5", 1.0), ("F5", 1.0), ("Ab5", 1.0),
        ("G5", 1.5), ("Eb5", 0.5), ("C5", 2.0),
        ("Ab5", 1.0), ("G5", 1.0), ("F5", 1.0), ("Eb5", 1.0),
        ("D5", 2.0), ("G5", 1.0), ("B5", 1.0),

        # Parte B: Clímax triunfal y unidad escolar
        ("C6", 1.5), ("Bb5", 0.5), ("G5", 1.0), ("Eb5", 1.0),
        ("Ab5", 1.5), ("G5", 0.5), ("Eb5", 1.0), ("C5", 1.0),
        ("G5", 1.0), ("Bb5", 1.0), ("Eb6", 1.5), ("D6", 0.5),
        ("Bb5", 2.0), ("F5", 1.0), ("Bb5", 1.0),

        ("C6", 1.0), ("Bb5", 0.5), ("Ab5", 0.5), ("G5", 1.0), ("F5", 1.0),
        ("Bb5", 1.0), ("F5", 1.0), ("D5", 1.0), ("F5", 1.0),
        ("C5", 1.0), ("Eb5", 1.0), ("G5", 1.0), ("C6", 1.0),
        ("Eb6", 2.5), ("Bb5", 1.5),
    ]
    t = 0.0
    for note, beats in melody:
        dur = beats * beat
        if note:
            add_voice(buf, t, dur * 0.94, freq(note), 0.21, voice="zun_trumpet", vibrato=0.0055)
            add_voice(buf, t, dur * 0.80, freq(note), 0.08, voice="school_chime", vibrato=0.0)
        t += dur

    return finalize_loop(buf, beat, echo_mix=0.22, lp_alpha=0.58)


def build_undertale_battle_anthem():
    """Himno original chiptune-rock en Re menor (148 BPM, 16 compases = ~25.95s por ciclo)
    compuesto especialmente para el duelo de esquive estilo Undertale contra Titanor."""
    bpm = 148.0
    beat = 60.0 / bpm
    Dm = ("D2", ["D4", "F4", "A4"])
    C_M = ("C2", ["C4", "E4", "G4"])
    Bb_M = ("Bb1", ["Bb3", "D4", "F4"])
    A7_M = ("A1", ["A3", "C#4", "E4"])
    Gm_M = ("G2", ["G3", "Bb3", "D4"])
    F_M = ("F2", ["F3", "A3", "C4"])

    # Estructura A (0-3) -> A' (4-7) -> B puente emotivo (8-11) -> C clímax total (12-15)
    chords = [
        Dm, C_M, Bb_M, A7_M,
        Dm, Gm_M, Bb_M, A7_M,
        Bb_M, C_M, Dm, F_M,
        Gm_M, A7_M, Bb_M, A7_M,
    ]
    bars = len(chords)
    buf = [0.0] * (int(bars * 4.0 * beat * RATE) + 64)

    for b, (bass, triad) in enumerate(chords):
        bar_t = b * 4.0 * beat
        bass_hi = shift_octave(bass, 1)

        # Bajo octavado agresivo con pulso sincopado estilo batalla Undertale
        for k in range(8):
            if b in (8, 9, 10, 11) and k in (3, 7):
                bn = shift_octave(bass, 2)
            else:
                bn = bass if (k % 2 == 0) else bass_hi
            add_voice(buf, bar_t + k * beat * 0.5, beat * 0.43, freq(bn), 0.25, voice="ut_bass", vibrato=0.0)

        # Pad armónico en puente B (8-11) y clímax C (12-15)
        if b >= 8:
            for tn in triad:
                add_voice(buf, bar_t, beat * 3.85, freq(tn), 0.068, voice="ut_pad", vibrato=0.003)

        # Arpegio chiptune en semicorcheas (16ths) con motivo ascendente/descendente
        arp_notes = [triad[0], triad[1], triad[2], shift_octave(triad[0], 1), triad[2], triad[1]]
        for k in range(16):
            amp = 0.064 if b < 8 else (0.048 if b < 12 else 0.072)
            add_voice(
                buf,
                bar_t + k * beat * 0.25,
                beat * 0.20,
                freq(arp_notes[k % len(arp_notes)]),
                amp,
                voice="ut_arp",
                vibrato=0.0,
            )

        # Campana heroica en entradas de sección
        if b in (0, 4, 8, 12):
            add_voice(buf, bar_t, beat * 1.5, freq(shift_octave(triad[2], 1)), 0.10, voice="school_chime", vibrato=0.0)

        # Batería chiptune-rock enérgica con redobles al final de cada frase de 4 compases
        for k in range(4):
            bt = bar_t + k * beat
            render_kick(buf, bt, 0.39)
            if k in (1, 3):
                render_snare(buf, bt, 0.25)
            if b >= 12 and k == 2:
                render_kick(buf, bt + beat * 0.5, 0.30)
            render_hat(buf, bt, 0.048, 0.028)
            render_hat(buf, bt + beat * 0.5, 0.075, 0.036)
            if k in (0, 2) or b >= 12:
                render_hat(buf, bt + beat * 0.25, 0.032, 0.020)
                render_hat(buf, bt + beat * 0.75, 0.036, 0.022)
        if b in (3, 7, 11, 15):
            for s16 in range(4):
                render_snare(buf, bar_t + 3.0 * beat + s16 * beat * 0.25, 0.16 + 0.04 * s16)

    # Melodía principal (16 compases = 64 tiempos exactos)
    melody = [
        # A (0-3): Riff sincopado de alta energía
        ("D5", 0.5), ("F5", 0.5), ("A5", 0.5), ("D6", 0.75), ("C6", 0.75), ("A5", 1.0),
        ("G5", 0.5), ("E5", 0.5), ("C5", 0.5), ("G5", 1.0), ("E5", 0.5), ("C5", 1.0),
        ("Bb4", 0.5), ("D5", 0.5), ("F5", 0.5), ("Bb5", 1.0), ("A5", 0.5), ("F5", 1.0),
        ("E5", 1.0), ("C#5", 0.5), ("E5", 0.5), ("A5", 1.0), ("E5", 1.0),

        # A' (4-7): Variación ascendente con tensión
        ("D5", 0.5), ("A5", 0.5), ("F5", 0.5), ("D5", 0.5), ("A5", 0.75), ("D6", 0.75), ("F6", 0.5),
        ("E6", 0.75), ("D6", 0.75), ("Bb5", 0.5), ("G5", 1.0), ("Bb5", 1.0),
        ("A5", 0.5), ("F5", 0.5), ("D5", 0.5), ("F5", 0.5), ("Bb5", 1.0), ("D6", 1.0),
        ("C#6", 1.5), ("A5", 0.5), ("E5", 1.0), ("A5", 1.0),

        # B (8-11): Puente heroico del Alma
        ("Bb5", 1.5), ("A5", 0.5), ("F5", 1.0), ("D5", 1.0),
        ("G5", 1.5), ("E5", 0.5), ("C5", 1.0), ("G5", 1.0),
        ("A5", 1.0), ("D6", 1.0), ("F6", 1.5), ("E6", 0.5),
        ("C6", 1.5), ("A5", 0.5), ("F5", 1.0), ("C6", 1.0),

        # C (12-15): Clímax total de duelo
        ("Bb5", 0.5), ("D6", 0.5), ("G6", 1.0), ("F6", 0.5), ("D6", 0.5), ("Bb5", 1.0),
        ("A5", 0.5), ("C#6", 0.5), ("E6", 1.0), ("A6", 1.0), ("E6", 1.0),
        ("F6", 0.75), ("D6", 0.75), ("Bb5", 0.5), ("D6", 1.0), ("F6", 1.0),
        ("E6", 1.5), ("C#6", 0.5), ("A5", 1.0), ("E5", 1.0),
    ]
    t = 0.0
    for note, beats in melody:
        dur = beats * beat
        if note:
            add_voice(buf, t, dur * 0.92, freq(note), 0.22, voice="ut_lead", vibrato=0.0055)
            # En puente y clímax duplicar una octava abajo para peso sinfónico
            if t >= 8 * 4.0 * beat:
                add_voice(buf, t, dur * 0.85, freq(shift_octave(note, -1)), 0.09, voice="zun_trumpet", vibrato=0.003)
        t += dur

    return finalize_loop(buf, beat, echo_mix=0.20, lp_alpha=0.58)


def generate_all():
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. Menú Principal (Campanas escolares de entrada + Touhou alegre, 126 BPM)
    F = ("F3", ["F4", "A4", "C5"])
    C = ("C3", ["C4", "E4", "G4"])
    Dm = ("D3", ["D4", "F4", "A4"])
    Bb = ("Bb2", ["Bb3", "D4", "F4"])
    menu_chords = [F, C, Dm, Bb, F, C, Bb, C]
    menu_mel = [
        ("A5", 1.0), ("G5", 1.0), ("F5", 1.0), ("C5", 1.0),
        ("E5", 1.5), ("F5", 0.5), ("G5", 2.0),
        ("A5", 1.0), ("F5", 1.0), ("D5", 1.0), ("F5", 1.0),
        ("G5", 1.5), ("F5", 0.5), ("D5", 2.0),
        ("A5", 1.0), ("C6", 1.0), ("A5", 1.0), ("F5", 1.0),
        ("G5", 1.0), ("E5", 1.0), ("C5", 2.0),
        ("D5", 1.0), ("F5", 1.0), ("Bb5", 1.0), ("A5", 1.0),
        ("G5", 2.0), ("E5", 1.0), ("C5", 1.0),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(126, menu_chords, menu_mel, char_variant=cv, bell_bars=True, drum_energy="menu", bell_motif=["A5", "F5", "G5", "C5"])
        write_wav(os.path.join(OUT_DIR, f"music_menu_{cv}.wav"), s)

    # 2. Escenario 1 (Acceso y Lab D, 142 BPM, Dm-Bb-C-Am)
    Dm3 = ("D3", ["D4", "F4", "A4"])
    Bb2 = ("Bb2", ["Bb3", "D4", "F4"])
    C3 = ("C3", ["C4", "E4", "G4"])
    Am2 = ("A2", ["A3", "C4", "E4"])
    s1_chords = [Dm3, Bb2, C3, Am2, Dm3, Bb2, C3, Dm3]
    s1_mel = [
        ("D5", 1.0), ("E5", 0.5), ("F5", 0.5), ("A5", 1.0), ("G5", 1.0),
        ("F5", 1.0), ("E5", 0.5), ("D5", 0.5), ("F5", 2.0),
        ("E5", 1.0), ("G5", 1.0), ("C6", 1.0), ("G5", 1.0),
        ("A5", 1.5), ("G5", 0.5), ("E5", 2.0),
        ("D5", 0.5), ("F5", 0.5), ("A5", 1.0), ("D6", 1.0), ("C6", 1.0),
        ("Bb5", 1.0), ("A5", 0.5), ("G5", 0.5), ("F5", 2.0),
        ("G5", 1.0), ("E5", 1.0), ("C5", 1.0), ("E5", 1.0),
        ("D5", 2.5), ("A4", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(142, s1_chords, s1_mel, char_variant=cv, bell_bars=True, drum_energy="touhou", bell_motif=["A5", "F5", "G5", "D5"])
        write_wav(os.path.join(OUT_DIR, f"music_stage_1_{cv}.wav"), s)

    # 3. Escenario 2 (Cafetería Edif A, 146 BPM, Em-C-D-Bm)
    Em = ("E3", ["E4", "G4", "B4"])
    D3 = ("D3", ["D4", "F#4", "A4"])
    Bm = ("B2", ["B3", "D4", "F#4"])
    s2_chords = [Em, C3, D3, Bm, Em, C3, D3, Em]
    s2_mel = [
        ("B4", 0.5), ("E5", 0.5), ("G5", 1.0), ("F#5", 0.5), ("E5", 0.5), ("B4", 1.0),
        ("C5", 1.0), ("E5", 1.0), ("G5", 1.0), ("E5", 1.0),
        ("D5", 0.5), ("F#5", 0.5), ("A5", 1.0), ("G5", 0.5), ("F#5", 0.5), ("D5", 1.0),
        ("F#5", 1.5), ("D5", 0.5), ("B4", 2.0),
        ("E5", 0.5), ("G5", 0.5), ("B5", 1.0), ("A5", 0.5), ("G5", 0.5), ("F#5", 1.0),
        ("E5", 1.0), ("G5", 1.0), ("C6", 1.0), ("B5", 1.0),
        ("A5", 1.0), ("F#5", 1.0), ("D5", 1.0), ("F#5", 1.0),
        ("E5", 2.5), ("B4", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(146, s2_chords, s2_mel, char_variant=cv, bell_bars=True, drum_energy="touhou", bell_motif=["B5", "G5", "A5", "E5"])
        write_wav(os.path.join(OUT_DIR, f"music_stage_2_{cv}.wav"), s)

    # 4. Escenario 3 (Plaza Cívica, 150 BPM, Marcha escolar en Cm-Ab-Bb-G)
    Cm = ("C3", ["C4", "Eb4", "G4"])
    Ab = ("Ab2", ["Ab3", "C4", "Eb4"])
    Bb3 = ("Bb2", ["Bb3", "D4", "F4"])
    Gm = ("G2", ["G3", "Bb3", "D4"])
    s3_chords = [Cm, Ab, Bb3, Gm, Cm, Ab, Bb3, Cm]
    s3_mel = [
        ("G5", 1.0), ("C5", 0.5), ("D5", 0.5), ("Eb5", 1.0), ("G5", 1.0),
        ("Ab5", 1.0), ("G5", 0.5), ("Eb5", 0.5), ("C5", 2.0),
        ("F5", 1.0), ("D5", 0.5), ("F5", 0.5), ("Bb5", 1.0), ("F5", 1.0),
        ("G5", 1.5), ("D5", 0.5), ("Bb4", 2.0),
        ("C5", 0.5), ("Eb5", 0.5), ("G5", 1.0), ("C6", 1.0), ("Bb5", 1.0),
        ("Ab5", 1.0), ("Eb5", 1.0), ("Ab5", 2.0),
        ("Bb5", 1.0), ("G5", 1.0), ("F5", 1.0), ("D5", 1.0),
        ("C5", 2.5), ("G4", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(150, s3_chords, s3_mel, char_variant=cv, bell_bars=True, drum_energy="touhou", bell_motif=["G5", "Eb5", "F5", "C5"])
        write_wav(os.path.join(OUT_DIR, f"music_stage_3_{cv}.wav"), s)

    # 5. Escenario 4 (Biblioteca / Edif B, 154 BPM, Am-F-G-Em)
    Am = ("A2", ["A3", "C4", "E4"])
    F2 = ("F2", ["F3", "A3", "C4"])
    G2 = ("G2", ["G3", "B3", "D4"])
    Em2 = ("E2", ["E3", "G3", "B3"])
    s4_chords = [Am, F2, G2, Em2, Am, F2, G2, Am]
    s4_mel = [
        ("E5", 0.5), ("A5", 0.5), ("B5", 1.0), ("C6", 0.5), ("B5", 0.5), ("A5", 1.0),
        ("F5", 1.0), ("A5", 1.0), ("C6", 1.0), ("A5", 1.0),
        ("G5", 0.5), ("B5", 0.5), ("D6", 1.0), ("C6", 0.5), ("B5", 0.5), ("G5", 1.0),
        ("E5", 1.5), ("G5", 0.5), ("B5", 2.0),
        ("A5", 0.5), ("C6", 0.5), ("E6", 1.0), ("D6", 0.5), ("C6", 0.5), ("B5", 1.0),
        ("A5", 1.0), ("F5", 1.0), ("C5", 2.0),
        ("D5", 1.0), ("G5", 1.0), ("B5", 1.0), ("G5", 1.0),
        ("A5", 2.5), ("E5", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(154, s4_chords, s4_mel, char_variant=cv, bell_bars=False, drum_energy="touhou")
        write_wav(os.path.join(OUT_DIR, f"music_stage_4_{cv}.wav"), s)

    # 6. Escenario 5 (Taller Cómputo, 158 BPM, F#m-D-E-C#m)
    Fsm = ("F#2", ["F#3", "A3", "C#4"])
    D_M = ("D3", ["D4", "F#4", "A4"])
    E_M = ("E3", ["E4", "G#4", "B4"])
    Csm = ("C#3", ["C#4", "E4", "G#4"])
    s5_chords = [Fsm, D_M, E_M, Csm, Fsm, D_M, E_M, Fsm]
    s5_mel = [
        ("F#5", 0.5), ("A5", 0.5), ("C#6", 1.0), ("B5", 0.5), ("A5", 0.5), ("G#5", 1.0),
        ("F#5", 1.0), ("D5", 1.0), ("A5", 2.0),
        ("G#5", 0.5), ("B5", 0.5), ("E6", 1.0), ("C#6", 1.0), ("B5", 1.0),
        ("G#5", 1.5), ("E5", 0.5), ("C#5", 2.0),
        ("F#5", 0.5), ("G#5", 0.5), ("A5", 1.0), ("C#6", 1.0), ("D6", 1.0),
        ("A5", 1.0), ("F#5", 1.0), ("D5", 2.0),
        ("E5", 1.0), ("G#5", 1.0), ("B5", 1.0), ("G#5", 1.0),
        ("F#5", 2.5), ("C#5", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(158, s5_chords, s5_mel, char_variant=cv, bell_bars=False, drum_energy="touhou")
        write_wav(os.path.join(OUT_DIR, f"music_stage_5_{cv}.wav"), s)

    # 7. Escenario 6 (Cancha Usos Múltiples, 164 BPM, Em-D-C-B7)
    B7 = ("B2", ["B3", "D#4", "F#4"])
    s6_chords = [Em, D3, C3, B7, Em, C3, D3, B7]
    s6_mel = [
        ("E5", 0.5), ("G5", 0.5), ("B5", 1.0), ("E6", 1.0), ("D6", 1.0),
        ("F#5", 0.5), ("A5", 0.5), ("D6", 1.0), ("C6", 0.5), ("B5", 0.5), ("A5", 1.0),
        ("G5", 0.5), ("C6", 0.5), ("E6", 1.0), ("D6", 0.5), ("C6", 0.5), ("G5", 1.0),
        ("F#5", 1.5), ("D#5", 0.5), ("B4", 2.0),
        ("E5", 1.0), ("B5", 0.5), ("A5", 0.5), ("G5", 1.0), ("F#5", 1.0),
        ("E5", 1.0), ("G5", 1.0), ("C6", 2.0),
        ("D5", 0.5), ("F#5", 0.5), ("A5", 1.0), ("D6", 1.0), ("A5", 1.0),
        ("B5", 2.0), ("D#5", 2.0),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(164, s6_chords, s6_mel, char_variant=cv, bell_bars=True, drum_energy="touhou", bell_motif=["B5", "G5", "F#5", "B4"])
        write_wav(os.path.join(OUT_DIR, f"music_stage_6_{cv}.wav"), s)

    # 8. Salones de Clases (148 BPM, Gm-Eb-F-Dm + timbre escolar de pupitre/campana)
    Gm3 = ("G2", ["G3", "Bb3", "D4"])
    Eb3 = ("Eb3", ["Eb4", "G4", "Bb4"])
    F3 = ("F2", ["F3", "A3", "C4"])
    cl_chords = [Gm3, Eb3, F3, Dm3, Gm3, Eb3, F3, Gm3]
    cl_mel = [
        ("D5", 0.5), ("G5", 0.5), ("Bb5", 1.0), ("A5", 0.5), ("G5", 0.5), ("D5", 1.0),
        ("Eb5", 1.0), ("G5", 1.0), ("Bb5", 1.0), ("G5", 1.0),
        ("F5", 0.5), ("A5", 0.5), ("C6", 1.0), ("Bb5", 0.5), ("A5", 0.5), ("F5", 1.0),
        ("A5", 1.5), ("F5", 0.5), ("D5", 2.0),
        ("G5", 1.0), ("Bb5", 1.0), ("D6", 1.0), ("C6", 1.0),
        ("Bb5", 1.0), ("G5", 1.0), ("Eb5", 2.0),
        ("F5", 1.0), ("A5", 1.0), ("C6", 1.0), ("A5", 1.0),
        ("G5", 2.5), ("D5", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(148, cl_chords, cl_mel, char_variant=cv, bell_bars=True, drum_energy="touhou", bell_motif=["D5", "Bb4", "C5", "G4"])
        write_wav(os.path.join(OUT_DIR, f"music_classroom_{cv}.wav"), s)

    # 9. Tema de Jefes de Escenario (168 BPM, Dm-C-Bb-A, Touhou Boss Drive)
    A7 = ("A2", ["A3", "C#4", "E4"])
    boss_chords = [Dm3, C3, Bb2, A7, Dm3, F2, G2, A7]
    boss_mel = [
        ("D5", 0.5), ("F5", 0.5), ("A5", 1.0), ("D6", 0.5), ("C6", 0.5), ("A5", 1.0),
        ("G5", 0.5), ("E5", 0.5), ("C5", 1.0), ("E5", 1.0), ("G5", 1.0),
        ("F5", 0.5), ("D5", 0.5), ("Bb4", 1.0), ("D5", 1.0), ("F5", 1.0),
        ("E5", 1.5), ("C#5", 0.5), ("A4", 2.0),
        ("D5", 0.5), ("A5", 0.5), ("F5", 0.5), ("D5", 0.5), ("A5", 1.0), ("D6", 1.0),
        ("C6", 1.0), ("A5", 1.0), ("F5", 2.0),
        ("G5", 0.5), ("B5", 0.5), ("D6", 1.0), ("B5", 1.0), ("G5", 1.0),
        ("A5", 2.0), ("C#6", 2.0),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(168, boss_chords, boss_mel, char_variant=cv, bell_bars=False, drum_energy="boss")
        write_wav(os.path.join(OUT_DIR, f"music_boss_{cv}.wav"), s)

    # 10. Tema Final Titanor Danmaku (176 BPM, C#m-A-B-G#7)
    A_M = ("A2", ["A3", "C#4", "E4"])
    B_M = ("B2", ["B3", "D#4", "F#4"])
    Gs7 = ("G#2", ["G#3", "C4", "D#4"])
    fin_chords = [Csm, A_M, B_M, Gs7, Csm, A_M, B_M, Csm]
    fin_mel = [
        ("C#5", 0.5), ("E5", 0.5), ("G#5", 0.5), ("C#6", 0.5), ("B5", 1.0), ("G#5", 1.0),
        ("A5", 0.5), ("E5", 0.5), ("C#5", 0.5), ("E5", 0.5), ("A5", 1.0), ("E5", 1.0),
        ("F#5", 0.5), ("B5", 0.5), ("D#6", 1.0), ("C#6", 0.5), ("B5", 0.5), ("F#5", 1.0),
        ("G#5", 1.5), ("D#5", 0.5), ("C5", 2.0),
        ("C#5", 0.5), ("G#5", 0.5), ("E5", 0.5), ("C#5", 0.5), ("G#5", 1.0), ("E6", 1.0),
        ("D#6", 0.5), ("C#6", 0.5), ("A5", 1.0), ("E5", 2.0),
        ("F#5", 0.5), ("B5", 0.5), ("D#6", 0.5), ("F#6", 0.5), ("D#6", 1.0), ("B5", 1.0),
        ("C#6", 2.5), ("G#5", 1.5),
    ]
    for cv in ("m", "f"):
        s = build_touhou_school_track(176, fin_chords, fin_mel, char_variant=cv, bell_bars=True, drum_energy="boss", bell_motif=["C#6", "G#5", "B5", "F#5"])
        write_wav(os.path.join(OUT_DIR, f"music_boss_final_{cv}.wav"), s)

    # 11. Tema Original Clímax Undertale-Finale (1 HP Titanor + Corazones)
    write_wav(os.path.join(OUT_DIR, "music_finale_souls.wav"), build_finale_souls_climax())

    # 11b. Tema Original Batalla Undertale (Duelo de esquive 2+ minutos)
    write_wav(os.path.join(OUT_DIR, "music_undertale_battle.wav"), build_undertale_battle_anthem())

    # 12. Capa Percusiva Extra para Dificultad Difícil
    write_wav(os.path.join(OUT_DIR, "music_hard_perc.wav"), build_hard_perc_overlay(160.0))

    # 13. Aliases de compatibilidad
    shutil.copy2(os.path.join(OUT_DIR, "music_menu_m.wav"), os.path.join(OUT_DIR, "music_menu.wav"))
    shutil.copy2(os.path.join(OUT_DIR, "music_stage_1_m.wav"), os.path.join(OUT_DIR, "music_game.wav"))
    print("Banda sonora completa generada con éxito.")


if __name__ == "__main__":
    generate_all()
