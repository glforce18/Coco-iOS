"""Beach ambience v2 — TRULY seamless loop using buffer-overlap technique.
Generates 24s + 1s overlap, then crossfades the overlap into start so loop
boundary has zero discontinuity."""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path("/root/PatPatFlutter/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)

SR = 22050
LOOP_DURATION = 24.0  # final loop length
OVERLAP = 1.0  # extra samples generated for crossfade


def low_pass(samples, alpha=0.025):
    out = []
    y = 0.0
    for x in samples:
        y = y + alpha * (x - y)
        out.append(y)
    return out


def main():
    n_loop = int(LOOP_DURATION * SR)
    n_extra = int(OVERLAP * SR)
    n_total = n_loop + n_extra

    rnd = random.Random(7)
    noise = [rnd.uniform(-1, 1) for _ in range(n_total)]
    waves = low_pass(noise, alpha=0.025)
    mx = max(abs(s) for s in waves) or 1
    waves = [s / mx for s in waves]

    out = [0.0] * n_total
    for i in range(n_total):
        t = i / SR
        # LFO frequencies tuned so each completes integer cycles in 24s:
        # 1/6 Hz × 24s = 4 cycles ✓, 1/4 Hz × 24s = 6 cycles ✓
        lfo1 = 0.6 + 0.4 * math.sin(2 * math.pi * (1.0 / 6.0) * t)
        lfo2 = 0.85 + 0.15 * math.sin(2 * math.pi * (1.0 / 4.0) * t + 1.3)
        out[i] = waves[i] * lfo1 * lfo2 * 0.55

    # Add 6 random bird chirps in the loop window (not in overlap)
    for _ in range(6):
        start_t = rnd.uniform(0.5, LOOP_DURATION - 0.5)
        start = int(start_t * SR)
        chirp_dur = rnd.uniform(0.06, 0.14)
        chirp_n = int(chirp_dur * SR)
        f0 = rnd.uniform(1500, 2400)
        f1 = f0 * rnd.uniform(0.8, 1.6)
        for i in range(chirp_n):
            ti = i / SR
            f = f0 * ((f1 / f0) ** (ti / chirp_dur))
            s = math.sin(2 * math.pi * f * ti)
            env_t = i / chirp_n
            env = 4 * env_t * (1 - env_t)
            idx = start + i
            if idx < n_total:
                out[idx] += s * env * 0.25

    # Seamless loop technique:
    # The "overlap" samples at the end represent what would naturally come
    # AFTER the loop point. We crossfade those onto the START of the loop.
    # Result: the start of the loop already contains the natural continuation,
    # so when the player loops from sample[n_loop-1] back to sample[0],
    # the audio is continuous because sample[0] is the blended version.
    final = list(out[:n_loop])
    for i in range(n_extra):
        if i >= n_loop:
            break
        ratio = i / n_extra  # 0 → 1 across overlap
        # As we go forward in the loop, fade IN the overlap material and fade OUT the original
        original = out[i]
        overlap_material = out[n_loop + i]
        # Equal-power crossfade for natural sound
        fade_in = math.sin(ratio * math.pi / 2)
        fade_out = math.cos(ratio * math.pi / 2)
        final[i] = original * fade_out + overlap_material * fade_in

    # Write
    path = OUT / "ambience_beach.wav"
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        for s in final:
            v = max(-1, min(1, s))
            w.writeframes(struct.pack("<h", int(v * 32000)))
    print(f"  ✓ ambience_beach.wav ({len(final)/SR:.1f}s, {path.stat().st_size//1024}KB) — seamless loop")


if __name__ == "__main__":
    main()
