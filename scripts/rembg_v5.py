"""rembg + crop + resize on v5 sprites → assets/sprites/ (only the 6 base products)"""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_v5")
DST = Path("/root/PatPatFlutter/assets/sprites")

session = new_session("u2net")

# Only the 6 base products — keep specials (rocket/bomb/rainbow) from v4.
BASE = ["jelly_purple", "jelly_yellow", "jelly_blue", "jelly_green", "jelly_pink", "jelly_orange"]

for name in BASE:
    src_file = SRC / f"{name}.png"
    if not src_file.exists():
        print(f"  - {name} missing, skip")
        continue
    data = src_file.read_bytes()
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
    dst = DST / f"{name}.png"
    img.save(dst, "PNG", optimize=True)
    print(f"  ✓ {name}")
print("Done.")
