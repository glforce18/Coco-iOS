"""rembg + boost the black sprite + place into assets/sprites/"""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image, ImageEnhance
import io

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_v9/jelly_black.png")
DST = Path("/root/PatPatFlutter/assets/sprites/jelly_black.png")

session = new_session("u2net")

# Remove BG
img = Image.open(io.BytesIO(remove(SRC.read_bytes(), session=session))).convert("RGBA")
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)
    w, h = img.size
    m = max(w, h)
    pad = Image.new("RGBA", (m, m), (0, 0, 0, 0))
    pad.paste(img, ((m - w) // 2, (m - h) // 2))
    img = pad
img = img.resize((256, 256), Image.LANCZOS)

# Apply boost (consistent with v1.9.9 sprites)
r, g, b, a = img.split()
rgb = Image.merge("RGB", (r, g, b))
rgb = ImageEnhance.Color(rgb).enhance(1.65)
rgb = ImageEnhance.Brightness(rgb).enhance(1.12)
rgb = ImageEnhance.Contrast(rgb).enhance(1.10)
rgb = ImageEnhance.Sharpness(rgb).enhance(1.4)
r2, g2, b2 = rgb.split()
out = Image.merge("RGBA", (r2, g2, b2, a))
out.save(DST, "PNG", optimize=True)
print(f"  ✓ jelly_black → {DST}")
