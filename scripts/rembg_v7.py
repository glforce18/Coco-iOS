"""rembg v7 jelly sprites → assets/sprites/"""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_v7")
DST = Path("/root/PatPatFlutter/assets/sprites")
session = new_session("u2net")

BASE = ["jelly_purple", "jelly_yellow", "jelly_blue", "jelly_green", "jelly_pink", "jelly_orange"]

for name in BASE:
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
    img.save(DST / f"{name}.png", "PNG", optimize=True)
    print(f"  ✓ {name}")
print("Done.")
