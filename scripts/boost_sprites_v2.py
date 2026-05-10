"""Extra HD boost — restore from backup, apply stronger enhancement.
Saturation 1.65x, brightness 1.12x, contrast 1.10x, sharpness 1.4x"""
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter

SPRITES = Path("/root/PatPatFlutter/assets/sprites")
BACKUP = Path("/root/PatPatFlutter/assets/sprites/_pre_boost_backup")

ALL = [
    "jelly_purple", "jelly_yellow", "jelly_blue", "jelly_green", "jelly_pink", "jelly_orange",
    "jelly_rocket", "jelly_bomb", "jelly_rainbow",
]

for name in ALL:
    src_backup = BACKUP / f"{name}.png"
    if not src_backup.exists():
        print(f"  - {name} backup missing, skip")
        continue
    img = Image.open(src_backup).convert("RGBA")
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))
    # Stronger color enhancement
    rgb = ImageEnhance.Color(rgb).enhance(1.65)         # saturation
    rgb = ImageEnhance.Brightness(rgb).enhance(1.12)    # brightness
    rgb = ImageEnhance.Contrast(rgb).enhance(1.10)      # contrast
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.4)      # crisper edges
    r2, g2, b2 = rgb.split()
    out = Image.merge("RGBA", (r2, g2, b2, a))
    # Save back to live sprites dir
    out.save(SPRITES / f"{name}.png", "PNG", optimize=True)
    print(f"  ✓ {name}")
print("Done.")
