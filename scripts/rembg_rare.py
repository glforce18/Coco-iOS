"""rembg + boost rare birds → assets/sprites/rare/"""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image, ImageEnhance
import io

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_v10")
DST = Path("/root/PatPatFlutter/assets/sprites/rare")
DST.mkdir(parents=True, exist_ok=True)
session = new_session("u2net")

RARE = ["rare_gold", "rare_iridescent", "rare_fire", "rare_ice", "rare_neon"]

for name in RARE:
    src = SRC / f"{name}.png"
    if not src.exists():
        continue
    img = Image.open(io.BytesIO(remove(src.read_bytes(), session=session))).convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        w, h = img.size
        m = max(w, h)
        pad = Image.new("RGBA", (m, m), (0, 0, 0, 0))
        pad.paste(img, ((m - w) // 2, (m - h) // 2))
        img = pad
    img = img.resize((256, 256), Image.LANCZOS)
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageEnhance.Color(rgb).enhance(1.45)
    rgb = ImageEnhance.Brightness(rgb).enhance(1.08)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.3)
    r2, g2, b2 = rgb.split()
    out = Image.merge("RGBA", (r2, g2, b2, a))
    out.save(DST / f"{name}.png", "PNG", optimize=True)
    print(f"  ✓ {name}")
print("Done.")
