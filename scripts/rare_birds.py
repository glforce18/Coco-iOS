"""5 rare birds + nest BG — for the egg hatching system."""

from leonardo_generate import PHOENIX, run_batch

BIRD_BASE = (
    "single chibi cute round tropical parrot bird character, "
    "plump fluffy round body and head fused together, tiny wing nubs at sides, "
    "large oversized round black eyes with bright white reflection highlights, "
    "small simple smiling beak, tiny feet, "
    "glossy translucent jelly toy material with soft rim light, "
    "Royal Match production quality, premium 3D mobile match-3 game character, "
    "soft global illumination, octane render, "
    "centered on pure white empty background, full body visible front view"
)

NEG = (
    "outline, black outline, frame, border, plate, badge, "
    "text, letters, words, watermark, logo, signature, "
    "background, scene, environment, multiple objects, group, perch, "
    "ugly, deformed, low quality, blurry, jpeg artifacts, "
    "dull, muted, faded, gray, dim, washed out, "
    "human face, weird proportions, scary, evil, sharp teeth, "
    "robotic, mechanical"
)


def bird(filename, color_desc):
    return {
        "name": filename,
        "dir": "sprites_v10",
        "prompt": f"{BIRD_BASE}, with {color_desc}",
        "model": PHOENIX,
        "w": 768,
        "h": 768,
        "alchemy": True,
        "neg": NEG,
        "force": True,
    }


PRODUCTS = [
    bird("rare_gold",
        "PURE METALLIC GOLD glossy plumage covering entire body, "
        "luxurious gleaming gold like 24k bullion, magical aura, premium rarity"),
    bird("rare_iridescent",
        "PRISMATIC IRIDESCENT plumage shifting through pink purple cyan green colors, "
        "magical pearl shimmer, rainbow holographic feathers, mystical premium rarity"),
    bird("rare_fire",
        "BURNING FIRE RED ORANGE plumage with subtle flame patterns, "
        "glowing ember effect, hot lava red core, dramatic premium rarity"),
    bird("rare_ice",
        "ICE CRYSTAL BLUE WHITE plumage with frosty shimmer, "
        "translucent crystalline texture like frozen jelly, cold winter tropical, premium rarity"),
    bird("rare_neon",
        "NEON ELECTRIC GREEN plumage with bright glow effect, "
        "cyberpunk vibrant lime, glowing aura, futuristic premium rarity"),
    # Bonus: nest BG for the hatching screen
    {
        "name": "nest_scene_bg",
        "dir": "backgrounds",
        "prompt": (
            "cozy tropical bird nest scene at golden hour, three small "
            "speckled bird eggs nestled in a woven twig nest sitting on a "
            "wooden tree branch, surrounded by soft tropical leaves and "
            "flowers, warm golden sunset light filtering through palm fronds, "
            "magical sparkle particles, dreamy bokeh background, "
            "Pixar 3D render, premium mobile game wallpaper, "
            "vertical 9:16 composition"
        ),
        "model": PHOENIX, "w": 768, "h": 1280, "alchemy": True,
        "neg": (
            "characters, people, animals, parrot, mascot, ugly, "
            "text, watermark, logo, low quality, blurry"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    from pathlib import Path
    Path("/root/PatPatFlutter/assets/tropical/sprites_v10").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=6)
