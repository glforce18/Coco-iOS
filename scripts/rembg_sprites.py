"""Run rembg on the final sprites then move to assets/sprites/."""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io
import shutil

SRC = Path("/root/PatPatFlutter/assets/tropical/sprites_final")
DST = Path("/root/PatPatFlutter/assets/sprites")

session = new_session("u2net")


def main():
    files = sorted(SRC.glob("jelly_*.png"))
    print(f"Cleaning {len(files)} sprites...")
    for f in files:
        try:
            data = f.read_bytes()
            out = remove(data, session=session)
            img = Image.open(io.BytesIO(out)).convert("RGBA")
            # Crop to bounding box of non-transparent pixels for tighter sprite
            bbox = img.getbbox()
            if bbox:
                img = img.crop(bbox)
                # Re-pad to square with transparent border
                w, h = img.size
                m = max(w, h)
                pad = Image.new("RGBA", (m, m), (0, 0, 0, 0))
                pad.paste(img, ((m - w) // 2, (m - h) // 2))
                img = pad
            # Resize to 256x256 for sprite (match other game sprites size)
            img = img.resize((256, 256), Image.LANCZOS)
            dst_path = DST / f.name
            img.save(dst_path, "PNG", optimize=True)
            print(f"  ✓ {f.name} → {dst_path}")
        except Exception as e:
            print(f"  ERR {f.name}: {e}")


if __name__ == "__main__":
    main()
