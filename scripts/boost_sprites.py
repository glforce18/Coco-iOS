"""Post-process the 9 sprite PNGs — boost saturation + brightness for vibrancy.
No Leonardo regeneration — just PIL color enhancement."""
from pathlib import Path
from PIL import Image, ImageEnhance

SPRITES = Path("/root/PatPatFlutter/assets/sprites")
BACKUP = Path("/root/PatPatFlutter/assets/sprites/_pre_boost_backup")
BACKUP.mkdir(exist_ok=True)

ALL = [
    "jelly_purple", "jelly_yellow", "jelly_blue", "jelly_green", "jelly_pink", "jelly_orange",
    "jelly_rocket", "jelly_bomb", "jelly_rainbow",
]

for name in ALL:
    src = SPRITES / f"{name}.png"
    if not src.exists():
        print(f"  - {name} missing")
        continue
    # Backup once
    bk = BACKUP / f"{name}.png"
    if not bk.exists():
        bk.write_bytes(src.read_bytes())
    img = Image.open(src).convert("RGBA")
    # Split alpha so enhancement only touches RGB
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))
    # Saturation boost 1.45x
    rgb = ImageEnhance.Color(rgb).enhance(1.45)
    # Brightness boost 1.10x
    rgb = ImageEnhance.Brightness(rgb).enhance(1.10)
    # Contrast slight 1.05x
    rgb = ImageEnhance.Contrast(rgb).enhance(1.05)
    r2, g2, b2 = rgb.split()
    out = Image.merge("RGBA", (r2, g2, b2, a))
    out.save(src, "PNG", optimize=True)
    print(f"  ✓ {name}")
print("Done.")
