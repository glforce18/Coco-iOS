"""TROPICAL BIRDS theme — 6 chibi parrots in unified toy style.
Royal Match grade, identical proportions, distinct PURE plumage colors.
Plus 3 specials: nest/egg, birdhouse, feather."""

from leonardo_generate import PHOENIX, run_batch

# Strict template — same prompt structure for all 6 birds, only color varies.
BASE = (
    "single chibi cute round tropical parrot bird character, "
    "plump fluffy round body and head fused together, tiny wing nubs at sides, "
    "large oversized round black eyes with bright white reflection highlights, "
    "small simple smiling beak, tiny feet, "
    "glossy translucent jelly toy material with soft rim light, "
    "Royal Match production quality, premium 3D mobile match-3 game character, "
    "soft global illumination, octane render, "
    "centered on pure white empty background, full body visible front view, "
    "consistent unified art style, simple readable silhouette"
)

NEG = (
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


def sprite(filename, color_desc):
    return {
        "name": filename,
        "dir": "sprites_v8",
        "prompt": (
            f"{BASE}, with {color_desc}"
        ),
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": True,
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    # purple slot → RED bird
    sprite("jelly_purple",
        "PURE BRIGHT CRIMSON RED plumage covering entire body, "
        "small darker red wing tips, NO other colors"),
    # yellow slot → YELLOW bird (chick-style)
    sprite("jelly_yellow",
        "PURE BRIGHT SUNSHINE YELLOW plumage covering entire body, "
        "like a baby chick, NO white belly, NO other colors"),
    # blue slot → BLUE bird
    sprite("jelly_blue",
        "PURE BRIGHT COBALT SAPPHIRE BLUE plumage covering entire body, "
        "small darker blue wing tips, NO purple, NO other colors"),
    # green slot → GREEN bird
    sprite("jelly_green",
        "PURE BRIGHT EMERALD LIME GREEN plumage covering entire body, "
        "small darker green wing tips, NO yellow, NO other colors"),
    # pink slot → PINK bird (or violet)
    sprite("jelly_pink",
        "PURE BRIGHT MAGENTA HOT PINK plumage covering entire body, "
        "small darker pink wing tips, NO red, NO other colors"),
    # orange slot → ORANGE bird
    sprite("jelly_orange",
        "PURE BRIGHT VIVID NEON ORANGE plumage covering entire body, "
        "small darker orange wing tips, NO red, NO yellow, NO other colors"),
]

# Specials — match bird theme
SPECIALS_STYLE = (
    "premium 3D rendered cartoon match-3 game special tile asset, "
    "glossy plastic toy material, vibrant colors, "
    "isolated centered on pure white empty background, full body visible, "
    "Royal Match production quality, octane render"
)
SPECIALS_NEG = NEG

SPECIALS = [
    {
        "name": "jelly_rocket",
        "dir": "sprites_v8",
        "prompt": (
            "single cute speckled bird egg sitting in small twig nest, "
            "vivid pale blue egg with white speckles, glowing magical aura, "
            "soft golden sparkles around, dynamic upward floating pose. "
            f"{SPECIALS_STYLE}"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": SPECIALS_NEG, "force": True,
    },
    {
        "name": "jelly_bomb",
        "dir": "sprites_v8",
        "prompt": (
            "single cute wooden tiki birdhouse with bright red roof, round entrance hole, "
            "tiny wisps of smoke from chimney, glowing orange windows, "
            "scary cute volcanic energy. "
            f"{SPECIALS_STYLE}"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": SPECIALS_NEG, "force": True,
    },
    {
        "name": "jelly_rainbow",
        "dir": "sprites_v8",
        "prompt": (
            "single magical rainbow tropical feather, "
            "iridescent prismatic shimmer in pink orange yellow green blue purple, "
            "sparkle starbursts around, magical glow, hero treasure item. "
            f"{SPECIALS_STYLE}"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": SPECIALS_NEG, "force": True,
    },
]


if __name__ == "__main__":
    run_batch(PRODUCTS + SPECIALS, workers=8)
