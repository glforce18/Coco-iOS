"""Generate UI panel/ribbon/texture assets for in-game polish."""
from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    {
        "name": "ui_ribbon_banner",
        "dir": "ui",
        "prompt": (
            "Wide horizontal red coral game UI ribbon banner with deep folds at both ends, "
            "rich coral red and dark crimson colors, gold trim outline, "
            "centered EMPTY blank surface ready for text overlay, "
            "isolated on transparent background, top-down view, "
            "Royal Match Toon Blast style, 3D chunky banner, "
            "soft drop shadow, vibrant saturated, octane render"
        ),
        "model": PHOENIX, "w": 1024, "h": 384, "alchemy": True,
        "neg": "text, letters, words, scrambled, low quality, blurry, dark gloomy, flat 2D",
        "force": True,
    },
    {
        "name": "ui_panel_wood_blank",
        "dir": "ui",
        "prompt": (
            "Square wooden plaque panel with thick gold metallic border frame, "
            "warm sandy cream interior surface, slight gradient lighter at top darker at bottom, "
            "rounded corners, 3D depth shadow, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium UI panel, "
            "gold trim with subtle highlights, octane render"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": "text, scratches, dirty, low quality, blurry, dark, flat",
        "force": True,
    },
    {
        "name": "ui_palm_corners",
        "dir": "ui",
        "prompt": (
            "Tropical palm fronds and leaves bouquet decoration corner overlay, "
            "lush green palms with subtle highlights, "
            "isolated on transparent background, "
            "premium 3D mobile game decorative element, "
            "facing inward from top-left corner of screen, "
            "vibrant saturated greens, octane render"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": "text, characters, animals, low quality, dark gloomy, dead leaves",
        "force": True,
    },
    {
        "name": "ui_bamboo_hut_bg",
        "dir": "backgrounds",
        "prompt": (
            "Cozy tropical bamboo hut interior background, "
            "vertical 9:16 portrait composition, "
            "warm bamboo plank walls, mossy stone floor at bottom, "
            "hanging palm leaves at top corners, hanging string lights warm glow, "
            "soft golden ambient light, soft shadow, "
            "central area empty (for UI overlay), "
            "Royal Match Toon Blast premium 3D quality, "
            "Pixar level cozy magical atmosphere, octane render"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": "characters, mascots, text UI, low quality, dark gloomy, scary, modern",
        "force": True,
    },
    {
        "name": "ui_sunset_ocean_bg",
        "dir": "backgrounds",
        "prompt": (
            "Tropical sunset ocean view background, "
            "vertical 9:16 portrait composition, "
            "purple-orange-magenta sky with soft clouds, "
            "calm turquoise ocean horizon mid-frame, "
            "silhouettes of palm trees on left and right edges, "
            "small sparkles in sky, soft mist, "
            "central area mostly clear (for UI overlay), "
            "Royal Match Toon Blast Pixar production quality, magical evening, octane render"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": "characters, text UI, low quality, dark gloomy, modern minimalist, urban",
        "force": True,
    },
]

if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/ui").mkdir(exist_ok=True, parents=True)
    Path("/root/PatPatFlutter/assets/tropical/backgrounds").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=2)
