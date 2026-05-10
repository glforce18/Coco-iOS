"""Generate short SFX WAV files for PatPat using pure Python (struct + wave)."""
import math
import struct
import wave
from pathlib import Path

OUT = Path("/root/PatPatFlutter/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050  # sample rate (Hz)


def write_wav(name, samples):
    """samples: list of float -1..1"""
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        for s in samples:
            v = max(-1, min(1, s))
            w.writeframes(struct.pack("<h", int(v * 32000)))
    print(f"  ✓ {name} ({len(samples)/SR*1000:.0f}ms)")


def envelope(t, total, attack=0.01, release=0.1):
    """ADSR-ish envelope (0..1)"""
    if t < attack:
        return t / attack
    end = total - release
    if t > end:
        return max(0, 1 - (t - end) / release)
    return 1.0


def tone(freq, duration, attack=0.005, release=0.05, vibrato=0, vib_rate=8):
    """Generate sine tone with envelope."""
    n = int(duration * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = freq * (1 + vibrato * math.sin(2 * math.pi * vib_rate * t))
        s = math.sin(2 * math.pi * f * t)
        env = envelope(t, duration, attack, release)
        out.append(s * env * 0.7)
    return out


def sweep(f0, f1, duration, attack=0.005, release=0.04):
    """Frequency sweep f0 → f1."""
    n = int(duration * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        # exponential sweep
        f = f0 * ((f1 / f0) ** (t / duration))
        phase += 2 * math.pi * f / SR
        s = math.sin(phase)
        env = envelope(t, duration, attack, release)
        out.append(s * env * 0.7)
    return out


def chord(freqs, duration, attack=0.005, release=0.08):
    """Chord (sum of multiple tones)."""
    n = int(duration * SR)
    out = []
    for i in range(n):
        t = i / SR
        s = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
        env = envelope(t, duration, attack, release)
        out.append(s * env * 0.7)
    return out


# 1) pop.wav — short pop for match (200ms, 800Hz down to 200Hz)
print("Generating SFX...")
write_wav("pop.wav", sweep(900, 180, 0.18))

# 2) combo.wav — rising tone for combo (300ms, 400→1200Hz)
write_wav("combo.wav", sweep(400, 1400, 0.28, attack=0.01, release=0.06))

# 3) swap.wav — short blip for swap (80ms, 600Hz)
write_wav("swap.wav", tone(600, 0.07, attack=0.005, release=0.04))

# 4) success.wav — fanfare for level complete (700ms, ascending chord)
fanfare = []
for f0, f1, dur in [(523, 523, 0.15), (659, 659, 0.15), (784, 784, 0.15), (1047, 1047, 0.30)]:
    fanfare.extend(tone(f0, dur, attack=0.005, release=0.03))
write_wav("success.wav", fanfare)

# 5) chirp.wav — parrot squawk for mascot tap (250ms, vibrato 1000Hz)
write_wav("chirp.wav", tone(1100, 0.18, attack=0.005, release=0.06, vibrato=0.04, vib_rate=14))

# 6) special.wav — magical chime when special tile spawns (450ms, chord up)
specbase = chord([523, 659, 784], 0.12, attack=0.01, release=0.04)
spectop = chord([1047, 1319, 1568], 0.30, attack=0.01, release=0.06)
write_wav("special.wav", specbase + spectop)

# 7) fail.wav — sad tone for game over (400ms, descending)
write_wav("fail.wav", sweep(400, 100, 0.36, attack=0.01, release=0.08))

print("\nDone.")
