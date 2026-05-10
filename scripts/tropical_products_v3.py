"""Final regen for jelly_rocket — proper rocket shape."""

from leonardo_generate import PHOENIX, run_batch

STYLE = (
    "ultra detailed 3D rendered character, Pixar Disney quality cartoon, "
    "vibrant glossy materials, soft global illumination, octane render, "
    "floating in empty pure white space, centered, full body visible"
)

NEG = (
    "frame, border, plate, platform, base, pedestal, tray, card, badge, "
    "rounded square frame, decorative border, "
    "text, letters, words, watermark, logo, signature, copyright, brand, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, dark, scary, "
    "round bomb, ball, sphere"
)


def sprite(filename, prompt):
    return {
        "name": filename,
        "dir": "sprites_v3",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": False,
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    sprite("jelly_rocket",
        "cute cartoon space rocket missile, classic torpedo shape pointing upward diagonally, "
        "vibrant red and white striped tropical paint with pineapple decoration, "
        "two small fin wings at base, big bright yellow flame jet shooting from bottom, "
        "magical sparks and stars trail, dynamic flying upward pose, mascot style"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=1)
