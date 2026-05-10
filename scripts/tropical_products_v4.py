"""HYPER-VIBRANT v4: candy-bright saturated colors, includes red papaya."""

from leonardo_generate import PHOENIX, run_batch

# ULTRA VIBRANT style — push saturation hard
STYLE = (
    "ultra detailed 3D rendered character, Pixar Disney quality cartoon, "
    "HYPER-SATURATED candy-bright neon vibrant colors, glossy lacquered finish, "
    "punchy high-contrast color palette, eye-popping vivid hues, soft global illumination, "
    "octane render, floating in empty pure white space, centered, full body visible, "
    "happy energetic expression"
)

NEG = (
    "frame, border, plate, platform, base, pedestal, tray, card, badge, "
    "rounded square frame, decorative border, "
    "text, letters, words, watermark, logo, signature, copyright, brand, "
    "background, scene, environment, multiple objects, group, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, pale, washed out, desaturated, gray, dim, dark color"
)


def sprite(filename, prompt):
    return {
        "name": filename,
        "dir": "sprites_v4",
        "prompt": f"{prompt}. {STYLE}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": False,
        "neg": NEG,
        "force": True,
    }


# All 9 sprites regenerated with hyper-vibrant prompts. Purple slot = RED PAPAYA.
PRODUCTS = [
    # purple → vibrant red papaya half (replaces dark coconut!)
    sprite("jelly_purple",
        "cute cartoon papaya fruit cut in half, bright fiery red orange flesh inside with "
        "small dark seeds in center, lime green outer skin, glossy juicy texture, "
        "big cute cartoon eyes and happy smile, chibi proportions"),
    sprite("jelly_yellow",
        "cute cartoon pineapple character, EXTREMELY bright golden yellow body with "
        "diamond crosshatch skin, fluffy emerald green leaf crown, "
        "huge sparkling round eyes, big happy smile, glossy lacquered finish, chibi"),
    sprite("jelly_blue",
        "cute cartoon spiral conch seashell character, vibrant electric cyan turquoise "
        "with iridescent rainbow shimmer, glossy candy finish, big sparkling eyes, "
        "smile, magical pearlescent reflections"),
    sprite("jelly_green",
        "cute cartoon green mango character, EXTREMELY vibrant lime emerald green "
        "glossy juicy skin, fresh dark green leaf with stem on top, "
        "big sparkling round eyes, huge happy smile, candy lacquered finish"),
    sprite("jelly_pink",
        "cute cartoon hibiscus tropical flower character, EXTREMELY hot vivid neon pink petals, "
        "five large rounded petals, bright golden yellow stamen center, "
        "two cute eyes peeking from petals, glossy candy finish"),
    sprite("jelly_orange",
        "cute friendly cartoon crab character with vibrant electric orange shell, "
        "two raised claws making peace sign, big sparkling round eyes, huge happy smile, "
        "four little legs, super glossy candy finish, mascot style"),
    # Specials
    sprite("jelly_rocket",
        "cute cartoon rocket missile, classic torpedo shape pointing diagonally upward, "
        "vibrant candy red and pure white striped paint, two small wing fins, "
        "huge bright yellow flame jet trail with sparks, magical glow, dynamic flying pose"),
    sprite("jelly_bomb",
        "cute cartoon classic round bomb character, glossy black sphere with bright happy "
        "cartoon face, big eyes and smile, lit twisted fuse on top with bright orange "
        "flame and yellow sparks flying everywhere, glowing red crack pattern"),
    sprite("jelly_rainbow",
        "magical giant tropical pearl crystal orb, hyper-saturated rainbow iridescent "
        "prismatic shimmer (vivid pink, orange, yellow, green, blue, purple stripes), "
        "intense magical glow, sparkling stars around, hero treasure item"),
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=8)
