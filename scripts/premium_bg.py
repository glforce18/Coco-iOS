"""Premium upsell modal BG — treasure golden tropical."""
from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    {
        "name": "ui_premium_bg",
        "dir": "backgrounds",
        "prompt": (
            "Vertical 9:16 luxurious tropical treasure background, "
            "warm golden light radiating from center, "
            "soft palm leaves at corners, sparkles floating, "
            "soft golden bokeh, faint ancient temple silhouette in distance, "
            "diamond gemstones scattered subtly, "
            "premium VIP atmosphere, vibrant rich gold + coral red tones, "
            "Royal Match Toon Blast premium production quality, "
            "soft global illumination, octane render, "
            "central area mostly clear for UI overlay"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "characters, mascots, text UI, low quality, blurry, "
            "dark gloomy night, scary, weapons, scary skull, "
            "modern minimalist flat design, real photo"
        ),
        "force": True,
    },
]

if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/backgrounds").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=1)
