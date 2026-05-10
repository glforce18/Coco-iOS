"""Mystical jungle game wallpaper — matches reference design."""
from leonardo_generate import PHOENIX, run_batch

PRODUCTS = [
    {
        "name": "game_jungle_bg",
        "dir": "backgrounds",
        "prompt": (
            "mystical dark tropical jungle scene at twilight, dense green palm fronds "
            "and leaves framing left and right edges of vertical composition, "
            "deep dark teal-green atmosphere with golden light rays filtering through canopy, "
            "glowing magical fireflies sparkles floating in the air, mossy stone path receding into distance, "
            "hanging vines, exotic plants, tropical mushrooms, dark forest depths, "
            "Royal Match game background quality, premium 3D render, soft volumetric lighting, "
            "vertical 9:16 game wallpaper composition, empty central area for game board overlay, "
            "Pixar quality, octane render, vibrant magical atmosphere"
        ),
        "model": PHOENIX,
        "w": 768,
        "h": 1280,
        "alchemy": True,
        "neg": (
            "characters, people, animals, text, watermark, logo, signature, "
            "ui, hud, frame, border, low quality, blurry, jpeg artifacts, "
            "bright sunny day, bright daylight, sunset, beach, ocean, water"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    run_batch(PRODUCTS, workers=1)
