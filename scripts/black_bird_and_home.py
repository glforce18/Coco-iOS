"""Generate black bird sprite + Coco's home interior BG."""

from leonardo_generate import PHOENIX, run_batch

BIRD_BASE = (
    "single chibi cute round tropical parrot bird character, "
    "plump fluffy round body and head fused together, tiny wing nubs at sides, "
    "large oversized round eyes with bright white reflection highlights, "
    "small simple smiling beak, tiny feet, "
    "glossy translucent jelly toy material with soft rim light, "
    "Royal Match production quality, premium 3D mobile match-3 game character, "
    "soft global illumination, octane render, "
    "centered on pure white empty background, full body visible front view, "
    "consistent unified art style, simple readable silhouette"
)

NEG_BIRD = (
    "outline, black outline, glow halo, magical glow, sparkles, neon, "
    "frame, border, plate, platform, base, pedestal, badge, "
    "text, letters, words, watermark, logo, signature, "
    "background, scene, environment, multiple objects, group, perch, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, gray, dim, washed out, desaturated, "
    "complex pattern, busy texture, realistic photograph, "
    "human face, weird proportions, scary, evil, threatening, sharp teeth, "
    "metallic shine, robotic, mechanical, mixed colors body"
)


PRODUCTS = [
    # 7th product — black raven/parrot
    {
        "name": "jelly_black",
        "dir": "../sprites_v9",  # custom — will move
        "prompt": (
            f"{BIRD_BASE}, with PURE GLOSSY JET BLACK plumage covering entire body, "
            "subtle blue iridescent shimmer on feathers, bright vivid neon yellow eyes, "
            "small darker black wing tips, NO white parts, dramatic vibrant black"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": NEG_BIRD, "force": True,
    },
    # Coco's hut interior
    {
        "name": "coco_home_interior",
        "dir": "backgrounds",
        "prompt": (
            "cozy tropical bamboo hut interior, warm golden lantern light, "
            "wooden plank floor, woven palm leaf walls and ceiling, "
            "hanging string lights, small tropical plants in pots, "
            "wooden shelves with seashells, hammock visible to the side, "
            "small round window showing jungle outside at twilight, "
            "wooden treasure chest in corner, tribal wooden patterns on walls, "
            "Pixar quality 3D render, warm inviting atmosphere, "
            "premium mobile game asset, vertical 9:16 composition, "
            "empty central area for character placement, octane render"
        ),
        "model": PHOENIX, "w": 768, "h": 1280, "alchemy": True,
        "neg": (
            "characters, people, animals, parrot, bird, mascot, "
            "text, watermark, logo, signature, ui, hud, "
            "low quality, blurry, jpeg artifacts, dark scary, modern furniture, "
            "outdoor scene only"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    # Force "sprites_v9" path — gets created
    import sys
    from pathlib import Path
    Path("/root/PatPatFlutter/assets/tropical/sprites_v9").mkdir(exist_ok=True, parents=True)
    # Patch dir on first product to point inside tropical
    PRODUCTS[0]["dir"] = "sprites_v9"
    run_batch(PRODUCTS, workers=2)
