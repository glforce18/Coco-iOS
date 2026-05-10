"""Generate 'All 12 Islands' world map screenshot for App Store marketing."""

from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    {
        "name": "screenshot_islands_v3_blank",
        "dir": "screenshots",
        "prompt": (
            "Vertical 9:16 mobile match-3 game world map screenshot, "
            "TOP: gold-trim wooden banner with red ribbon, EMPTY no text inside, "
            "MIDDLE+BOTTOM: aerial bird's-eye view of tropical archipelago with 12 distinct islands "
            "arranged on bright turquoise ocean, connected by glowing golden dotted path winding between them, "
            "each island has a clean WOODEN PLANK SIGNPOST with COMPLETELY BLANK empty surface NO TEXT no numbers, "
            "12 unique themed islands: "
            "sandy coral beach with palms, "
            "dense coconut jungle, "
            "turquoise lagoon with pink coral palace, "
            "green palm valley with waterfall, "
            "wooden harbor with sailboats lighthouse, "
            "dark cave entrance with golden treasure glow, "
            "red lava volcano island, "
            "white blue iceberg island, "
            "underwater coral reef visible through clear water, "
            "ancient stone temple with mossy ruins, "
            "huge waterfall with mist, "
            "golden lost city pyramid with rays of light, "
            "Coco chibi blue parrot mascot flying with wings spread between islands, "
            "puffy white clouds, sparkles in sky, sailboats on water, "
            "Royal Match Toon Blast premium production quality, vibrant saturated colors, "
            "Pixar quality 3D render, octane, soft global illumination, "
            "playful magical tropical adventure"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "low quality, blurry, jpeg artifacts, deformed, "
            "text gibberish scrambled illegible, realistic photo, "
            "dark gloomy night, modern minimalist UI, flat 2D, "
            "weird proportions, broken anatomy, scary"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/screenshots").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=1)
