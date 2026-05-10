"""Procedural beach ambience: filtered noise (waves) + slow LFO + occasional birds.
Output: 8s seamless loop WAV at 22050Hz, 16-bit mono."""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path("/root/PatPatFlutter/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050
DURATION = 8.0  # seconds — short loop for size


def low_pass(samples, alpha=0.05):
    """Simple 1-pole low-pass filter — turns white noise into 'shhh' wave-like sound."""
    out = []
    y = 0.0
    for x in samples:
        y = y + alpha * (x - y)
        out.append(y)
    return out


def crossfade(samples, fade_samples=2048):
    """Make the loop seamless by crossfading start with end of buffer."""
    n = len(samples)
    out = list(samples)
    for i in range(fade_samples):
        ratio = i / fade_samples
        # blend: tail (end-fade+i) into head (i)
        a = out[i]
        b = out[n - fade_samples + i]
        # linear crossfade
        out[i] = a * ratio + b * (1 - ratio)
    return out[:n - fade_samples // 2]


def main():
    n = int(DURATION * SR)

    # 1) White noise base
    rnd = random.Random(42)
    noise = [rnd.uniform(-1, 1) for _ in range(n)]

    # 2) Low-pass filter for ocean "shhhhh"
    waves = low_pass(noise, alpha=0.025)
    # Normalize
    mx = max(abs(s) for s in waves) or 1
    waves = [s / mx for s in waves]

    # 3) Slow LFO modulation — wave swells every ~6 seconds
    out = []
    for i in range(n):
        t = i / SR
        # Two layered LFOs for organic feel
        lfo1 = 0.6 + 0.4 * math.sin(2 * math.pi * (1.0 / 6.0) * t)
        lfo2 = 0.85 + 0.15 * math.sin(2 * math.pi * (1.0 / 11.0) * t + 1.3)
        out.append(waves[i] * lfo1 * lfo2 * 0.55)

    # 4) Add 3 random short bird chirps at random positions
    for _ in range(3):
        start_t = rnd.uniform(0.5, DURATION - 0.5)
        start = int(start_t * SR)
        chirp_dur = rnd.uniform(0.06, 0.12)
        chirp_n = int(chirp_dur * SR)
        f0 = rnd.uniform(1500, 2400)
        f1 = f0 * rnd.uniform(0.8, 1.5)
        for i in range(chirp_n):
            ti = i / SR
            # exponential frequency sweep
            f = f0 * ((f1 / f0) ** (ti / chirp_dur))
            s = math.sin(2 * math.pi * f * ti)
            # envelope: quick attack, quick release
            env_t = i / chirp_n
            env = 4 * env_t * (1 - env_t)  # parabolic
            idx = start + i
            if idx < n:
                out[idx] += s * env * 0.25

    # 5) Crossfade for seamless loop
    out = crossfade(out, fade_samples=int(0.1 * SR))

    # 6) Write WAV
    path = OUT / "ambience_beach.wav"
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        for s in out:
            v = max(-1, min(1, s))
            w.writeframes(struct.pack("<h", int(v * 32000)))
    print(f"  ✓ ambience_beach.wav ({len(out)/SR:.1f}s, {path.stat().st_size//1024}KB)")


if __name__ == "__main__":
    main()
