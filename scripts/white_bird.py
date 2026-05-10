"""Generate white bird sprite — matches the existing chibi tropical bird family.

Output: /root/PatPatFlutter/assets/tropical/sprites_v10/jelly_white.png
Then rembg cleanup → /root/PatPatFlutter/assets/sprites/jelly_white.png
"""

from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

BIRD_BASE = (
    "single chibi cute round tropical parrot bird character, "
    "plump fluffy round body and head fused together, tiny wing nubs at sides, "
    "large oversized round eyes with bright reflection highlights, "
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
    "metallic shine, robotic, mechanical, mixed colors body, "
    "yellow body, pink body, blue body, any color other than pure white"
)

PRODUCTS = [
    {
        "name": "jelly_white",
        "dir": "sprites_v10",
        "prompt": (
            f"{BIRD_BASE}, with PURE BRIGHT SNOW WHITE plumage covering entire body, "
            "subtle pearlescent cool blue tinted shadows for depth, "
            "vivid sapphire blue eyes with sparkle highlights, "
            "tiny soft pink cheek blush, light orange beak and feet, "
            "NO yellow tones, NO gray, brilliant clean white feathers"
        ),
        "model": PHOENIX, "w": 768, "h": 768, "alchemy": True,
        "neg": NEG_BIRD, "force": True,
    },
]


if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/sprites_v10").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=1)
