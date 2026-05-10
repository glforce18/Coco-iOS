"""Regenerate the bad sprites with a cleaner prompt — no frames, no watermarks."""

from leonardo_generate import PHOENIX, run_batch

# CLEANER style: avoid "tile/asset/card/sprite" terminology that triggers
# decorative frames around the subject. Instead describe as standalone 3D
# rendered character/object floating in empty white space.
STYLE = (
    "ultra detailed 3D rendered character, Pixar Disney quality cartoon, "
    "vibrant glossy materials, soft global illumination, octane render, "
    "floating in empty pure white space, centered, full body visible"
)

# Strong negatives — remove every cause of frames/watermarks/text/plates
NEG = (
    "frame, border, plate, platform, base, pedestal, tray, card, badge, "
    "rounded square frame, decorative border, "
    "text, letters, words, watermark, logo, signature, copyright, brand, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, dark, scary"
)


def sprite(filename, prompt):
    return {
        "name": filename,
        "dir": "sprites_v2",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": False,
        "neg": NEG,
        "force": True,
    }


# 6 to regenerate
PRODUCTS = [
    sprite("jelly_purple",
        "cute cartoon coconut character, dark brown round hairy coconut shell with two big "
        "expressive cartoon eyes and a wide smile, small white teeth visible, "
        "tiny green palm leaf sprouting from top, chibi proportions, mascot style"),
    sprite("jelly_yellow",
        "cute cartoon pineapple fruit character, bright golden yellow textured body with "
        "diamond cross-hatch skin pattern, fluffy spiky green leaf crown on top, "
        "big round expressive cartoon eyes and happy smile, chibi proportions, mascot style"),
    sprite("jelly_green",
        "cute cartoon green mango fruit character, vibrant lime green oval mango with "
        "smooth glossy skin, single dark green leaf with stem on top, "
        "big round eyes and a sweet smile, chibi proportions, mascot style"),
    sprite("jelly_orange",
        "cute friendly cartoon red orange crab character, round chibi body with "
        "two raised waving claws making a peace sign, two big round black eyes, "
        "happy smile, four little legs underneath, vibrant red orange shell, mascot style"),
    sprite("jelly_rocket",
        "cute cartoon coconut bomb rocket, round dark brown coconut shell with cartoon eyes, "
        "two glowing yellow flame jets shooting out from bottom, magical sparks around, "
        "dynamic upward flying pose, mascot style"),
    sprite("jelly_bomb",
        "cute cartoon round bomb character, classic black round bomb body with cartoon "
        "happy face, two big eyes and smile, lit fuse on top with bright orange flame "
        "and sparks flying, glowing red crack pattern on the body, chibi proportions"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
