"""Run rembg on mascot + achievement icons + decor → save as transparent PNGs."""
from pathlib import Path
from rembg import remove, new_session
from PIL import Image
import io
import sys

ROOT = Path("/root/PatPatFlutter/assets/tropical")

TARGETS = [
    ROOT / "mascot",       # 9 mascot poses
    ROOT / "decor",        # 11 decor items
    ROOT / "icons",        # 7 boosters + nodes
    ROOT / "achievements", # 25 achievement icons
    ROOT / "rewards",      # 15 reward cards
    ROOT / "nodes",        # 12 region pills
]

session = new_session("u2net")  # general-purpose model


def clean(src: Path):
    if not src.suffix == ".png":
        return
    try:
        data = src.read_bytes()
        out = remove(data, session=session)
        # ensure RGBA
        img = Image.open(io.BytesIO(out)).convert("RGBA")
        img.save(src, "PNG", optimize=True)
        return True
    except Exception as e:
        print(f"  ERR {src.name}: {e}")
        return False


def main():
    targets = sys.argv[1:] if len(sys.argv) > 1 else [d.name for d in TARGETS]
    total = 0
    ok = 0
    for d in TARGETS:
        if d.name not in targets:
            continue
        files = sorted(d.glob("*.png"))
        print(f"\n[{d.name}] {len(files)} files")
        for f in files:
            total += 1
            if clean(f):
                ok += 1
                print(f"  ✓ {f.name}")
    print(f"\nDone. {ok}/{total} cleaned")


if __name__ == "__main__":
    main()
