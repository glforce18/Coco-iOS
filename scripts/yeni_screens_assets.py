"""Reference screenshot adaptation — generate matching assets for 4 screens.

User placed reference SS in /root/foto/yeni/, asked us to recreate the look
TIPA TIP (exactly). This batch generates all missing visual elements.
"""
from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    # === ROYAL CROWNED PARROT MASCOT (the hero character in profile + level complete) ===
    {
        "name": "mascot_crowned_portrait",
        "dir": "mascot",
        "prompt": (
            "Adorable royal crowned macaw parrot portrait, head and shoulders only facing camera, "
            "deep blue head feathers, bright yellow chest, white face mask around eyes, black beak, "
            "wearing tiny ornate red velvet crown with gold trim and small gem on forehead, "
            "big sparkly eyes, gentle proud smile, "
            "isolated centered on transparent background, soft golden rim light, "
            "Royal Match Toon Blast premium production quality, 3D pixar render, glossy, "
            "vibrant saturated colors, octane render, depth of field background blur"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, sign, gritty, dark gloomy, low quality, flat 2D, two characters, multiple parrots, weird proportions, extra wings",
        "force": True,
    },
    {
        "name": "mascot_crowned_full",
        "dir": "mascot",
        "prompt": (
            "Full body adorable royal crowned macaw parrot standing tall, facing camera straight on, "
            "deep blue head and back feathers, bright sunny yellow chest and belly, white face mask, black curved beak, "
            "wearing tiny ornate red velvet crown with gold trim and gem, "
            "small orange feet visible, wings tucked at sides, "
            "isolated on transparent background, soft golden halo glow around figure, "
            "Royal Match Toon Blast premium production quality, 3D pixar render glossy, "
            "vibrant saturated colors, octane render, hero portrait composition"
        ),
        "model": PHOENIX, "w": 832, "h": 1248, "alchemy": True,
        "neg": "text, gritty, dark, low quality, flat 2D, multiple parrots, weird proportions, sitting, perched on branch, environment background",
        "force": True,
    },

    # === RIBBON BANNERS (red velvet + gold trim + tassels — text overlaid in Flutter) ===
    {
        "name": "ui_ribbon_red_gold",
        "dir": "ui",
        "prompt": (
            "Horizontal royal red velvet ribbon banner with thick gold trim border, "
            "two pointed tassels hanging from bottom corners, gold filigree decoration at edges, "
            "centered shape facing camera straight, slight curve drape, glossy 3D, "
            "isolated on transparent background, "
            "Royal Match Toon Blast UI element premium quality, octane render, "
            "rich saturated burgundy red, polished gold trim shine"
        ),
        "model": PHOENIX, "w": 1408, "h": 768, "alchemy": True,
        "neg": "text letters writing, characters, mascot, blurry, low quality, flat 2D, modern flat design",
        "force": True,
    },

    # === ANIMATED FRAME ELEMENTS ===
    {
        "name": "ui_palm_leaves_left",
        "dir": "ui",
        "prompt": (
            "Lush tropical jungle palm leaves cluster framing the LEFT edge of a screen, "
            "leaves growing in from left side pointing inward and overlapping, "
            "deep green saturated tropical foliage, several monstera and palm fronds, "
            "two bright red hibiscus flowers tucked among leaves, "
            "tall vertical composition, leaves anchored to left edge with empty space on right, "
            "isolated on transparent background, glossy 3D pixar style, "
            "Royal Match Toon Blast premium decoration quality, "
            "octane render, vibrant saturated greens, soft top-down light"
        ),
        "model": PHOENIX, "w": 768, "h": 1408, "alchemy": True,
        "neg": "text, characters, animals, mascot, fence, low quality, dark gloomy, flat 2D, faded colors, sparse",
        "force": True,
    },
    {
        "name": "ui_palm_leaves_right",
        "dir": "ui",
        "prompt": (
            "Lush tropical jungle palm leaves cluster framing the RIGHT edge of a screen, "
            "leaves growing in from right side pointing inward and overlapping, "
            "deep green saturated tropical foliage, several monstera and palm fronds, "
            "two bright red hibiscus flowers tucked among leaves, "
            "tall vertical composition, leaves anchored to right edge with empty space on left, "
            "isolated on transparent background, glossy 3D pixar style, "
            "Royal Match Toon Blast premium decoration quality, "
            "octane render, vibrant saturated greens, soft top-down light"
        ),
        "model": PHOENIX, "w": 768, "h": 1408, "alchemy": True,
        "neg": "text, characters, animals, mascot, fence, low quality, dark gloomy, flat 2D, faded colors, sparse",
        "force": True,
    },
    {
        "name": "ui_string_lights",
        "dir": "ui",
        "prompt": (
            "Horizontal row of warm glowing fairy string lights, "
            "round amber yellow bulbs hanging from a dark thin curved wire, "
            "bulbs spaced evenly across width, each glowing with soft halo, "
            "isolated on transparent background, top-edge composition with wire spanning horizontally, "
            "Royal Match Toon Blast UI element premium quality, glossy 3D, "
            "warm cozy atmosphere, octane render"
        ),
        "model": PHOENIX, "w": 1408, "h": 512, "alchemy": True,
        "neg": "text, characters, day light, sun, low quality, blurry, flat 2D, modern flat design",
        "force": True,
    },

    # === EGG STATES (for YUVA infographic) ===
    {
        "name": "ui_egg_unhatched",
        "dir": "ui",
        "prompt": (
            "Single creamy speckled bird egg nestled in dark woven straw nest, "
            "egg has subtle brown speckles, glossy shell, facing camera, "
            "small dark twig nest underneath, isolated on transparent background, "
            "Royal Match Toon Blast premium item quality, glossy 3D pixar render, "
            "octane render, soft top light, no environment background"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, characters, parrot, baby bird, broken egg, cracked egg, multiple eggs, low quality, flat 2D",
        "force": True,
    },
    {
        "name": "ui_egg_cracked",
        "dir": "ui",
        "prompt": (
            "Single creamy speckled bird egg with diagonal CRACK opening across middle, "
            "bright golden light bursting out from the crack, sparkle particles around, "
            "egg sitting in dark woven straw nest, isolated on transparent background, "
            "Royal Match Toon Blast premium item quality, glossy 3D pixar render, "
            "magical glowing effect, octane render, no environment"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, characters, fully hatched parrot, baby bird visible, intact egg, multiple eggs, low quality, flat 2D",
        "force": True,
    },
    {
        "name": "ui_egg_hatched_parrot",
        "dir": "ui",
        "prompt": (
            "Adorable baby blue parrot emerging from cracked egg shell, "
            "tiny blue parrot with yellow chest and big eyes peeking out happy, "
            "broken egg shell pieces around its body, sitting in dark woven straw nest, "
            "magical golden sparkles and light rays around, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, "
            "octane render, vibrant magical scene, no environment background"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, two parrots, adult parrot, no shell, intact egg, low quality, flat 2D, dark, scary",
        "force": True,
    },

    # === 6 CHIBI PARROTS IN WOVEN NESTS (for YUVA grid) ===
    {
        "name": "bird_chibi_cyan_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi cyan TURQUOISE parrot perched in dark woven straw nest, "
            "round chubby cyan blue body, bright yellow beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated cyan turquoise color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary, red blue color mix",
        "force": True,
    },
    {
        "name": "bird_chibi_pink_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi PINK parrot perched in dark woven straw nest, "
            "round chubby hot pink body, bright orange beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated hot pink color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary",
        "force": True,
    },
    {
        "name": "bird_chibi_red_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi RED scarlet parrot perched in dark woven straw nest, "
            "round chubby crimson red body, bright yellow beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated scarlet red color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary",
        "force": True,
    },
    {
        "name": "bird_chibi_magenta_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi MAGENTA fuchsia parrot perched in dark woven straw nest, "
            "round chubby deep magenta body, bright yellow beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated magenta purple-pink color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary",
        "force": True,
    },
    {
        "name": "bird_chibi_green_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi GREEN parrot perched in dark woven straw nest, "
            "round chubby vibrant green body, bright orange beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated emerald green color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary",
        "force": True,
    },
    {
        "name": "bird_chibi_yellow_nest",
        "dir": "sprites_v10",
        "prompt": (
            "Tiny adorable chibi YELLOW canary parrot perched in dark woven straw nest, "
            "round chubby sunny yellow body, bright orange beak, big sparkly eyes, "
            "small wings folded, sitting in nest facing camera, "
            "isolated on transparent background, "
            "Royal Match Toon Blast premium hero item quality, glossy 3D pixar render, octane render, "
            "vibrant saturated golden yellow color"
        ),
        "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True,
        "neg": "text, eggs, multiple birds, weird proportions, low quality, flat 2D, dark scary",
        "force": True,
    },
]


if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/ui").mkdir(exist_ok=True, parents=True)
    Path("/root/PatPatFlutter/assets/tropical/mascot").mkdir(exist_ok=True, parents=True)
    Path("/root/PatPatFlutter/assets/tropical/sprites_v10").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=6)
