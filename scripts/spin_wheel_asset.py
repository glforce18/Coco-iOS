"""Premium spin wheel image — replaces hand-painted wheel."""
from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    {
        "name": "ui_spin_wheel",
        "dir": "ui",
        "prompt": (
            "Premium tropical wooden spin wheel, square 1:1 frame, "
            "round wheel divided into 8 colored prize segments arranged like pie slices, "
            "segment colors alternating: blue, coral red, palm green, gold yellow, brown bamboo, lagoon teal, dark coral, sky blue, "
            "thick golden rope frame around outer edge with 8 metal nail studs at cardinal points, "
            "central golden hub disc, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium production quality, glossy 3D, "
            "vibrant saturated colors, soft global illumination, octane render, "
            "facing camera straight-on, no text in segments"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": (
            "text gibberish, scrambled letters, illegible, "
            "casino slot machine, gambling, dice, roulette, "
            "low quality, blurry, dark gloomy, modern flat 2D, "
            "characters mascot inside wheel, weird proportions"
        ),
        "force": True,
    },
]

if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/ui").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=1)
