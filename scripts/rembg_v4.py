"""rembg + crop + resize on v4 sprites → assets/sprites/"""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_v4")
DST = Path("/root/PatPatFlutter/assets/sprites")

session = new_session("u2net")

for f in sorted(SRC.glob("jelly_*.png")):
    data = f.read_bytes()
    out = remove(data, session=session)
    img = Image.open(io.BytesIO(out)).convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        w, h = img.size
        m = max(w, h)
        pad = Image.new("RGBA", (m, m), (0, 0, 0, 0))
        pad.paste(img, ((m - w) // 2, (m - h) // 2))
        img = pad
    img = img.resize((256, 256), Image.LANCZOS)
    dst = DST / f.name
    img.save(dst, "PNG", optimize=True)
    print(f"  ✓ {f.name}")
print("Done.")
