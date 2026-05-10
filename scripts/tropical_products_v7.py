"""UNIFIED jelly material — single template, only color/shape varies.
Goal: match Royal Match / Candy Crush production sprite consistency.
NO outlines, NO glow halos, NO sparkles, identical face style across all 6."""

from leonardo_generate import PHOENIX, run_batch

# Base style — identical across all 6 sprites
BASE_STYLE = (
    "premium 3D rendered match-3 game character mascot, "
    "glossy translucent jelly candy plastic material with subtle rim light, "
    "soft rounded simple shape, two big simple round black eyes with white reflection dots, "
    "small smiling cartoon mouth, "
    "Royal Match Candy Crush production quality, "
    "soft global illumination, octane render, "
    "isolated centered on pure white background, full body visible, "
    "consistent unified art style, simple readable silhouette"
)

NEG = (
    "outline, black outline, glow halo, magical glow, sparkles, neon, "
    "frame, border, plate, platform, base, pedestal, badge, "
    "text, letters, words, watermark, logo, signature, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, gray, dim, "
    "complex pattern, busy texture, realistic photograph, "
    "human face, multiple eyes, weird proportions, "
    "metallic shine, robotic, mechanical, body suit"
)


def sprite(filename, body_desc):
    return {
        "name": filename,
        "dir": "sprites_v7",
        "prompt": (
            f"{body_desc}. {BASE_STYLE}"
        ),
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": True,
        "neg": NEG,
        "force": True,
    }


# Each spec: name + minimal body description (color/shape only)
PRODUCTS = [
    # red strawberry
    sprite("jelly_purple",
        "single chibi cute character made entirely of glossy bright candy red jelly "
        "in strawberry shape with small white seed dots, tiny green leaf on top"),
    # yellow banana
    sprite("jelly_yellow",
        "single chibi cute character made entirely of glossy bright candy yellow jelly "
        "in slightly curved banana shape, tiny brown nub at one end"),
    # blue blueberry
    sprite("jelly_blue",
        "single chibi cute character made entirely of glossy deep blue jelly "
        "in perfectly round blueberry sphere shape with a tiny crown indent on top"),
    # green lime
    sprite("jelly_green",
        "single chibi cute character made entirely of glossy emerald green jelly "
        "in perfectly round lime sphere shape, tiny green leaf on top"),
    # pink — keep dragon fruit but simpler
    sprite("jelly_pink",
        "single chibi cute character made entirely of glossy hot pink jelly "
        "in round dragon fruit shape with small green leaf accents"),
    # orange citrus
    sprite("jelly_orange",
        "single chibi cute character made entirely of glossy bright orange jelly "
        "in perfectly round orange citrus sphere shape, tiny green leaf on top"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
