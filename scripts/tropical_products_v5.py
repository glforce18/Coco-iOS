"""6 distinct PURE color products — NO color overlap.
RED · ORANGE · YELLOW · GREEN · BLUE · PINK"""

from leonardo_generate import PHOENIX, run_batch

STYLE = (
    "ultra detailed 3D rendered character, Pixar Disney quality cartoon, "
    "single solid PURE saturated color dominant (not mixed colors), "
    "glossy candy lacquered finish, eye-popping vivid hue, simple silhouette, "
    "soft global illumination, octane render, "
    "floating in empty pure white space, centered, full body visible, "
    "happy energetic mascot expression, big sparkling eyes"
)

NEG = (
    "frame, border, plate, platform, base, pedestal, tray, card, badge, "
    "decorative border, mixed colors, multiple hues, gradient body, "
    "text, letters, words, watermark, logo, signature, copyright, brand, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, pale, washed out, desaturated, gray, dim, "
    "complex pattern, busy texture"
)


def sprite(filename, prompt):
    return {
        "name": filename,
        "dir": "sprites_v5",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": False,
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    # purple slot → RED — strawberry
    sprite("jelly_purple",
        "PURE RED strawberry fruit cartoon character, deep crimson red glossy body "
        "with tiny white seed dots, small green leaf cap on top, "
        "two huge cute black eyes and big happy smile"),
    # yellow slot → YELLOW — banana
    sprite("jelly_yellow",
        "PURE YELLOW banana cartoon character, vivid bright yellow curved banana "
        "with tiny brown nub at end, big sparkling eyes and wide happy smile, "
        "glossy lacquered yellow finish, NO green spots"),
    # blue slot → BLUE — blueberry
    sprite("jelly_blue",
        "PURE BLUE round blueberry cartoon character, deep cobalt sapphire blue "
        "round berry, glossy candy finish, two huge round eyes and happy smile, "
        "tiny crown on top, NO purple, vivid blue dominant"),
    # green slot → GREEN — lime
    sprite("jelly_green",
        "PURE GREEN lime fruit cartoon character, vivid neon emerald green oval "
        "lime, glossy waxy citrus skin texture, big cute eyes and smile, "
        "small green leaf on top, NO yellow, vibrant green only"),
    # pink slot → PINK — dragon fruit
    sprite("jelly_pink",
        "PURE PINK dragon fruit cartoon character, hot magenta pink glossy body "
        "with green leafy spikes around it, big cute eyes and bright happy smile, "
        "glossy candy pink finish, NO orange or red, vivid pink only"),
    # orange slot → ORANGE — orange fruit
    sprite("jelly_orange",
        "PURE ORANGE round orange fruit cartoon character, vivid neon orange "
        "glossy round citrus, small green leaf on top, big cute eyes and "
        "bright happy smile, NO red or yellow, vivid orange dominant only"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
