"""ALCHEMY ON — neon glowing candy-crush vibrant sprites.
6 base products only. Distinct PURE colors with maximum saturation."""

from leonardo_generate import PHOENIX, run_batch

# Aggressive vibrant prompt
STYLE = (
    "ultra premium 3D rendered cartoon character, Royal Match style mobile game asset, "
    "NEON GLOWING vivid colors, hyper-saturated candy gloss finish, magical luminous glow halo, "
    "punchy high-contrast lighting, sparkles around, juice splashes, "
    "Pixar Disney quality but EXTRA vibrant pop colors, "
    "single PURE saturated color dominant body, simple readable silhouette, "
    "soft global illumination, octane render, "
    "isolated on pure white empty background, centered, full body, "
    "happy energetic mascot expression, big sparkling cartoon eyes"
)

NEG = (
    "frame, border, plate, platform, base, pedestal, tray, card, badge, "
    "decorative border, mixed colors, multiple hues, gradient body, "
    "text, letters, words, watermark, logo, signature, copyright, brand, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, pale, washed out, desaturated, gray, dim, "
    "complex pattern, busy texture, realistic photograph, naturalistic"
)


def sprite(filename, prompt):
    return {
        "name": filename,
        "dir": "sprites_v6",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": True,  # ← KEY DIFFERENCE
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    # PURE RED — strawberry
    sprite("jelly_purple",
        "GLOWING NEON CRIMSON RED strawberry fruit cartoon character, "
        "intensely saturated bright red glossy body with white seed dots, "
        "small fresh green leaf cap on top, two huge cute eyes, big happy smile, "
        "magical red glow aura"),
    # PURE YELLOW — banana
    sprite("jelly_yellow",
        "GLOWING NEON SUNSHINE YELLOW banana cartoon character, vivid bright pure yellow "
        "curved banana body with no markings, big sparkling eyes, wide happy smile, "
        "magical yellow glow aura, NO green, NO brown spots"),
    # PURE BLUE — blueberry
    sprite("jelly_blue",
        "GLOWING NEON ELECTRIC SAPPHIRE BLUE round blueberry cartoon character, "
        "intensely saturated cobalt blue glossy round berry, two huge round eyes, "
        "happy smile, tiny green crown on top, magical blue glow aura, "
        "NO purple, NO turquoise, vivid PURE BLUE only"),
    # PURE GREEN — lime
    sprite("jelly_green",
        "GLOWING NEON LIME GREEN fruit cartoon character, vivid emerald shamrock green "
        "round lime body, glossy waxy citrus skin, big cute eyes, bright smile, "
        "small green leaf on top, magical green glow aura, NO yellow, NO blue"),
    # PURE PINK — dragon fruit
    sprite("jelly_pink",
        "GLOWING NEON HOT MAGENTA PINK dragon fruit cartoon character, intensely "
        "saturated bright pink glossy body with green spike scales, big cute eyes, "
        "bright happy smile, magical pink glow aura, NO red, NO orange, vivid PURE PINK"),
    # PURE ORANGE — orange citrus
    sprite("jelly_orange",
        "GLOWING NEON BRIGHT ORANGE round citrus orange fruit cartoon character, "
        "vivid saturated orange glossy round body, small green leaf on top, "
        "big cute eyes, bright happy smile, magical orange glow aura, "
        "NO red, NO yellow, vivid PURE ORANGE"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
