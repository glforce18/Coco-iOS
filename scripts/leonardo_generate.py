#!/usr/bin/env python3
"""Leonardo asset generator for PatPat tropical theme."""
import json
import os
import sys
import time
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

API = "https://cloud.leonardo.ai/api/rest/v1"
KEY = Path("/root/.leonardo-api-key").read_text().strip()
HEADERS = {"Authorization": f"Bearer {KEY}", "Content-Type": "application/json", "accept": "application/json"}

PHOENIX = "de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3"
THREE_D = "d69c8273-6b17-4a30-a13e-d6637ae1c644"
VISION_XL = "5c232a9e-9061-4777-980a-ddc8e65647c6"
LIGHTNING_XL = "b24e16ff-06e3-43eb-8d33-4416c2d75876"
LUCID_ORIGIN = "7b592283-e8a7-4c5a-9ba6-d18c31f258b9"

ROOT = Path("/root/PatPatFlutter/assets/tropical")
MANIFEST = ROOT / "manifest.json"

NEG_BASE = "text, watermark, signature, logo, ugly, low quality, blurry, extra limbs, deformed, distorted, jpeg artifacts, banding, frame, border"


def http(method, path, body=None):
    url = f"{API}{path}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=HEADERS, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        body_txt = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} {method} {path}: {body_txt[:300]}") from None


def submit(prompt, *, model=PHOENIX, w=768, h=1024, alchemy=False, num=1, neg_extra=""):
    body = {
        "prompt": prompt,
        "modelId": model,
        "width": w,
        "height": h,
        "num_images": num,
        "alchemy": alchemy,
        "public": False,
        "negative_prompt": NEG_BASE + (", " + neg_extra if neg_extra else ""),
    }
    if model == PHOENIX:
        body["contrast"] = 3.5  # Phoenix-specific
        body["styleUUID"] = "111dc692-d470-4eec-b791-3475abac4c46"  # Dynamic
    res = http("POST", "/generations", body)
    return res["sdGenerationJob"]["generationId"]


def wait(gen_id, timeout=180):
    start = time.time()
    while time.time() - start < timeout:
        r = http("GET", f"/generations/{gen_id}")
        gen = r.get("generations_by_pk") or {}
        status = gen.get("status")
        if status == "COMPLETE":
            urls = [img["url"] for img in gen.get("generated_images", [])]
            return urls
        if status == "FAILED":
            raise RuntimeError(f"Generation {gen_id} FAILED")
        time.sleep(3)
    raise TimeoutError(f"Generation {gen_id} did not complete in {timeout}s")


def download(url, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (compatible; PatPatAssetFetcher/1.0)",
        "Accept": "image/*,*/*;q=0.8",
    })
    with urllib.request.urlopen(req, timeout=120) as r:
        dst.write_bytes(r.read())
    return dst


def load_manifest():
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text())
    return {"assets": {}}


def save_manifest(m):
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(m, indent=2, ensure_ascii=False))


def make_asset(asset):
    """asset: dict {name, prompt, dir, model?, w?, h?, alchemy?, neg?}"""
    name = asset["name"]
    dst = ROOT / asset["dir"] / f"{name}.png"
    if dst.exists() and not asset.get("force", False):
        return ("skip", name, str(dst))
    try:
        gen_id = submit(
            asset["prompt"],
            model=asset.get("model", PHOENIX),
            w=asset.get("w", 768),
            h=asset.get("h", 1024),
            alchemy=asset.get("alchemy", False),
            neg_extra=asset.get("neg", ""),
        )
        urls = wait(gen_id)
        if not urls:
            return ("err", name, "no urls")
        download(urls[0], dst)
        return ("ok", name, str(dst))
    except Exception as e:
        return ("err", name, str(e))


def run_batch(assets, workers=8):
    print(f"Generating {len(assets)} assets, {workers} parallel slots…")
    manifest = load_manifest()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(make_asset, a): a for a in assets}
        for fut in as_completed(futures):
            status, name, info = fut.result()
            done += 1
            print(f"[{done}/{len(assets)}] {status}\t{name}\t{info}")
            if status == "ok":
                manifest["assets"][name] = {
                    "path": info,
                    "prompt": next(a for a in assets if a["name"] == name)["prompt"][:120],
                    "ts": int(time.time()),
                }
                save_manifest(manifest)
    print("Done.")


def remaining_tokens():
    me = http("GET", "/me")
    u = me["user_details"][0]
    return {"apiPaid": u.get("apiPaidTokens"), "apiSub": u.get("apiSubscriptionTokens")}


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "tokens"
    if cmd == "tokens":
        print(json.dumps(remaining_tokens(), indent=2))
    elif cmd == "phase1":
        from asset_plan import PHASE_1
        run_batch(PHASE_1, workers=8)
    elif cmd == "phase2":
        from asset_plan import PHASE_2
        run_batch(PHASE_2, workers=8)
    elif cmd == "all":
        from asset_plan import PHASE_1, PHASE_2
        run_batch(PHASE_1 + PHASE_2, workers=8)
    elif cmd == "retry":
        # Retry only missing/error assets
        from asset_plan import PHASE_1, PHASE_2
        from pathlib import Path as _P
        missing = [a for a in PHASE_1 + PHASE_2 if not (ROOT / a["dir"] / f"{a['name']}.png").exists()]
        print(f"Retrying {len(missing)} missing assets")
        run_batch(missing, workers=6)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
