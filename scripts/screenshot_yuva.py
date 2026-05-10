"""Generate Yuva (egg incubator) screen mockup for App Store screenshot."""

from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    {
        "name": "screenshot_yuva_v2",
        "dir": "screenshots",
        "prompt": (
            "Vertical 9:16 mobile match-3 game UI screenshot, tropical bird sanctuary egg nest screen, "
            "TOP: gold-trim wooden banner reading 'YUVA' in red ribbon, "
            "MIDDLE: 3 cream speckled eggs in woven palm nests on wooden shelf, golden halo glow around each, "
            "left egg pristine, middle slightly cracked, right egg ready with bright cracks and sparkles, "
            "BOTTOM: tidy 4-column 3-row grid (12 slots) of chibi parrot birds, "
            "row 1: red, yellow, blue, green birds, "
            "row 2: pink, orange, black raven (neon yellow eyes), gold metallic rare, "
            "row 3: iridescent rainbow, fire bird with flames, ice bird with frost aura, neon cyan-pink bird, "
            "all 12 birds fully colored unlocked, fluffy round chibi parrots with big glossy eyes, "
            "rare last 5 with golden border and sparkles, common 7 with wooden frame, "
            "background: bamboo hut interior, warm string lights, palm leaves, gold metallic UI borders, "
            "Royal Match Toon Blast premium 3D quality, octane render, glossy jelly-toy material, "
            "vibrant saturated colors, cozy magical atmosphere"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "low quality, blurry, jpeg artifacts, deformed, ugly, "
            "text gibberish, scrambled words, illegible UI, "
            "realistic photo, scary, dark gloomy, "
            "weird proportions, missing eyes, broken anatomy, "
            "modern minimalist UI, flat 2D, plain white background, "
            "western cartoon style, anime style"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/screenshots").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=1)
