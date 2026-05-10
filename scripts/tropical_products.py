"""Generate 10 tropical product sprites to replace jelly_*.png.
Phoenix base 768x768, isolated white BG, premium Royal Match cartoon 3D."""

from leonardo_generate import PHOENIX, run_batch

STYLE = (
    "premium 3D cartoon game tile sprite, Royal Match style, vibrant glossy, "
    "isolated on pure pristine white background, centered single object, "
    "soft drop shadow under, ultra detailed, octane render, mobile match-3 "
    "game asset, square composition, full body visible, no text, no logo"
)

NEG = (
    "background, scene, environment, multiple objects, frame, border, text, "
    "watermark, signature, ugly, low quality, blurry, jpeg artifacts, dark, "
    "complex composition, busy"
)


def sprite(filename, prompt):
    """filename without .png — saved to assets/tropical/sprites_new/, moved later."""
    return {
        "name": filename,
        "dir": "sprites_new",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": False,
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    sprite("jelly_purple",
        "single half coconut fruit cracked open, dark brown fibrous shell exterior, "
        "pure white creamy meat inside, glossy water droplet on top, smiling friendly cartoon face on shell"),
    sprite("jelly_yellow",
        "single tropical pineapple fruit, bright golden yellow textured skin with diamond pattern, "
        "spiky green crown leaves on top, big cute cartoon eyes and smile, glossy juicy"),
    sprite("jelly_blue",
        "single spiral conch seashell, vibrant turquoise blue and cyan iridescent gradient, "
        "pearlescent shimmer, smooth coiled shape, cartoon style with subtle face"),
    sprite("jelly_green",
        "single ripe green mango fruit, vibrant fresh lime green glossy skin, "
        "small dark green leaf on top, cute cartoon face with smile, juicy droplet"),
    sprite("jelly_pink",
        "single hibiscus tropical flower, vibrant hot pink petals with yellow center stamen, "
        "five large rounded petals, sparkling dewdrop, cute cartoon style"),
    sprite("jelly_orange",
        "single tropical red orange crab cartoon character, smiling friendly face with big eyes, "
        "two raised waving claws, bright vibrant red orange shell, chibi proportions"),
    # Specials — match the visual style but with magical "powered up" features
    sprite("jelly_rocket",
        "single tropical bamboo rocket cartoon, two crossed bamboo sticks with palm leaf wings, "
        "yellow flame fire jet at bottom, glowing hot pink core, magical sparks, dynamic angle"),
    sprite("jelly_bomb",
        "single tropical tiki carved wooden bomb cartoon, dark brown wood with carved face, "
        "burning orange fuse on top with red flame and sparks, glowing red volcanic core, scary cute"),
    sprite("jelly_rainbow",
        "single giant tropical pearl in open clamshell, rainbow iridescent prismatic shimmer "
        "(pink, orange, yellow, green, blue, purple), magical glow, sparkles around, hero item"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
