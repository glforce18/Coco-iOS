"""Generate Level Complete + Spin Wheel + Shop screenshots."""

from leonardo_generate import PHOENIX, run_batch
from pathlib import Path

PRODUCTS = [
    # ─── Level Complete (TEBRIKLER) ─────────────────────────────────
    {
        "name": "screenshot_level_complete_v1",
        "dir": "screenshots",
        "prompt": (
            "Vertical 9:16 mobile match-3 game level complete celebration screen, "
            "TOP: huge gold-shimmer 'TEBRIKLER!' text in coral red ribbon banner with gold trim, "
            "MIDDLE: cute fluffy round chibi blue parrot mascot named Coco in center "
            "with small wings raised in victory pose, golden halo glow around it, "
            "above mascot: 3 GOLDEN STARS in a row with sparkle bursts radiating from each, "
            "stars are 3D chunky golden with white shine highlight, "
            "BACKGROUND: rotating gold sun rays from center, "
            "colorful confetti raining down (yellow, blue, green, pink, orange squares tumbling), "
            "BELOW MASCOT: gold-trim wooden plaque panel with three stat rows: "
            "'Puan: 4250' (with bar chart icon), "
            "'Altin: 75' (with gold coin icon), "
            "'Maks Kombo: x6' (with flame icon), "
            "BOTTOM: green coral 'DEVAM' button with arrow icon, "
            "background mystical jungle bird sanctuary tone darkened with golden glow, "
            "Royal Match Toon Blast premium production quality, "
            "vibrant saturated colors, octane render, joyful celebration atmosphere, "
            "Pixar quality 3D"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "low quality, blurry, deformed, scary, dark, gloomy, "
            "text gibberish, scrambled letters, illegible, "
            "realistic photo, modern minimalist UI, flat 2D, "
            "weird proportions, broken anatomy, multiple mascots"
        ),
        "force": True,
    },
    # ─── Spin Wheel (CARK) ────────────────────────────────────────
    {
        "name": "screenshot_spin_wheel_v1",
        "dir": "screenshots",
        "prompt": (
            "Vertical 9:16 mobile match-3 game tropical spin wheel screen, "
            "TOP: gold-trim wooden banner with red ribbon reading 'COCO CARK' in white capitals, "
            "MIDDLE: huge round wooden spin wheel taking center frame, "
            "wheel divided into 8 colored prize segments arranged like pie slices: "
            "blue, coral red, green palm, gold yellow JACKPOT, brown bamboo, dark teal lagoon, dark coral, blue, "
            "each segment shows an icon: gold coins, gold coins, gold coins, diamond, hammer, sparkle wand, fast-forward arrow, gold coins, "
            "OUTER FRAME: thick golden rope band around wheel with 8 metal nail studs at cardinal points, "
            "TOP OF WHEEL: wooden mallet hammer pointer pointing down at wheel rim, "
            "CENTER HUB: round golden disc with chibi blue parrot mascot face peeking out, "
            "wheel emits golden glow halo, "
            "BACKGROUND: tropical sunset ocean view with palm leaf silhouettes, mystical purple-orange sky, "
            "BELOW WHEEL: large green coral 'CEVIR' button (spin button), "
            "Royal Match Toon Blast premium quality, vibrant colors, glossy 3D, octane render, "
            "magical excitement atmosphere"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "low quality, blurry, scary, dark gloomy, deformed, "
            "text gibberish scrambled illegible numbers, "
            "casino slot machine, gambling chips, dice, "
            "weird proportions, modern flat UI, real photo"
        ),
        "force": True,
    },
    # ─── Shop / Magaza ────────────────────────────────────────────
    {
        "name": "screenshot_shop_v1",
        "dir": "screenshots",
        "prompt": (
            "Vertical 9:16 mobile match-3 game tropical shop screen, "
            "TOP: gold-trim wooden banner with red ribbon reading 'MAGAZA' in white capitals, "
            "BELOW BANNER: top stats bar with stars/gold/heart icons, "
            "MAIN AREA stacked premium offer cards: "
            "FIRST CARD with golden border + sparkle effect, large diamond icon, "
            "title 'VIP UYELIK' in gold, subtitle 'Sinirsiz can + 2x altin + reklamsiz' below, "
            "coral 'AL' button on right side with price tag, "
            "SECOND CARD: red 'block' icon, title 'REKLAMSIZ', subtitle 'Tek seferlik tum reklamlar kapanir', "
            "THIRD CARD: gift box icon, title 'BASLANGIC PAKETI', '5 cekic + 5 renk + 5 hamle + 1000 altin', "
            "FOURTH ROW shows 3 small booster cards side by side: hammer icon (Cekic), sparkle wand (Renk), fast-forward (+3 Hamle), "
            "FIFTH ROW: 3 coin pack offers small medium large with tropical jungle gold coin piles, "
            "BACKGROUND: cozy tropical hut interior with bamboo walls, hanging palm leaves, soft warm lighting, "
            "all UI panels gold-trim wooden plaques on cream sandy tan interior, "
            "Royal Match Toon Blast production quality, vibrant colors, glossy 3D, octane render, "
            "inviting commerce atmosphere"
        ),
        "model": PHOENIX, "w": 832, "h": 1472, "alchemy": True,
        "neg": (
            "low quality, blurry, scary, dark gloomy, deformed, "
            "text gibberish scrambled illegible, "
            "modern minimalist flat UI, real photo, "
            "casino, bet, gambling theme"
        ),
        "force": True,
    },
]


if __name__ == "__main__":
    Path("/root/PatPatFlutter/assets/tropical/screenshots").mkdir(exist_ok=True, parents=True)
    run_batch(PRODUCTS, workers=2)
