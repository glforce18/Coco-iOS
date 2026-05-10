"""Tropical theme asset plan for PatPat — Phase 1 (essentials)."""

from leonardo_generate import PHOENIX, THREE_D, LUCID_ORIGIN

STYLE_BASE = (
    "premium 3D game render, Pixar quality, Royal Match style, vibrant cinematic lighting, "
    "ultra detailed, soft global illumination, polished octane render, mobile game asset"
)

NEG_CHARACTER = "ugly, deformed, low quality, extra limbs, mutated, blurry, jpeg artifacts, watermark, text, signature, frame, border"
NEG_SCENE = "people, characters, ugly, low quality, blurry, jpeg artifacts, watermark, text, signature, ui overlay, hud, frame, border"
NEG_ICON = "background, scene, frame, border, complex composition, low quality, blurry, watermark, text, signature, multiple objects"


def bg(name, prompt, w=768, h=1280):
    return {
        "name": name, "dir": "backgrounds",
        "prompt": f"{prompt}. {STYLE_BASE}, vertical composition with empty top sky for UI overlays",
        "w": w, "h": h, "model": PHOENIX, "alchemy": False, "neg": NEG_SCENE,
    }


def region(name, prompt):
    return {
        "name": name, "dir": "backgrounds",
        "prompt": f"{prompt}. {STYLE_BASE}, vertical scrolling background for game map screen, no characters",
        "w": 768, "h": 1280, "model": PHOENIX, "alchemy": False, "neg": NEG_SCENE,
    }


def mascot(name, prompt, w=640, h=896):
    return {
        "name": name, "dir": "mascot",
        "prompt": f"{prompt}, cute friendly cartoon parrot mascot named Coco, blue and yellow plumage with red crest, big expressive eyes, isolated on solid white background, full body, character sheet pose, {STYLE_BASE}",
        "w": w, "h": h, "model": PHOENIX, "alchemy": False, "neg": NEG_CHARACTER + ", scene, environment, background details",
    }


def icon(name, prompt, dir_="icons", w=512, h=512):
    return {
        "name": name, "dir": dir_,
        "prompt": f"{prompt}, isolated on transparent or simple soft gradient background, centered, premium 3D rendered game icon, vibrant tropical colors, glossy finish, {STYLE_BASE}",
        "w": w, "h": h, "model": PHOENIX, "alchemy": False, "neg": NEG_ICON,
    }


# ── PHASE 1: 66 essential assets ──

PHASE_1 = []

# Hero screen backgrounds (10) — 768x1280
PHASE_1 += [
    bg("main_menu_bg", "tropical island vista at golden hour, palm trees curving, turquoise lagoon, distant volcano peak, sunset sky with orange purple clouds, treasure chest half buried in sand, lush jungle, gentle waves, cinematic"),
    bg("game_bg", "tropical beach scene framed by palm leaves on left and right edges, sandy beach background, soft bokeh ocean, wooden game board hint at center, decorative coconuts and shells around"),
    bg("shop_bg", "pirate trading post on tropical island, wooden bazaar stalls, crates of fruit and gold, hanging lanterns, palm shadows, warm afternoon light, market vibe"),
    bg("profile_bg", "cozy beach hut interior, hammock, wooden walls, parrot perch, sunlight streaming through bamboo blinds, treasure chest in corner, plants, warm inviting"),
    bg("daily_reward_bg", "open treasure chest on sandy beach with gold coins and gems spilling out, sunbeam from above, sparkling magical particles, palm shadows"),
    bg("spin_wheel_bg", "ancient tiki idol cave entrance with glowing carvings, magical mystical atmosphere, blue and orange firelight, tribal totems, mysterious"),
    bg("event_bg", "pirate galleon ship docked at tropical pier at sunset, lanterns, rope rigging, palm silhouettes, dramatic sky, adventure mood"),
    bg("mascot_home_bg", "beach cottage with garden, white wooden walls, hammock, palm leaves, warm afternoon light, pet bowl, tropical flowers, homely atmosphere"),
    bg("achievement_bg", "ancient tropical temple trophy room, gold idols and trophies on stone shelves, vines, dramatic torchlight, mystical adventure vibe"),
    bg("no_lives_bg", "sleeping parrot in hammock between palm trees at sunset, peaceful beach, soft warm light, dreamy"),
]

# Region map backgrounds (12) — vertical scroll
REGIONS = [
    ("coral_beach", "sunny coral beach with white sand and turquoise water, gentle palm trees, scattered seashells, calm tropical waves"),
    ("coconut_island", "lush coconut palm grove on small tropical island, crystal clear lagoon, coconuts on sand, midday sun"),
    ("lagoon_palace", "majestic turquoise lagoon with crystal blue water, exotic flowers, water lilies, ancient stone arches partially submerged"),
    ("palm_valley", "tall palm valley with cascading streams, ferns, tropical flowers, dappled sunlight, dense green foliage"),
    ("sailor_harbor", "wooden tropical harbor with fishing boats, lanterns, ropes, sunset over the bay, weathered docks, adventure mood"),
    ("treasure_cave", "golden treasure cave entrance with stalactites, gold coins glimmering inside, mystical magical light, jungle vines around"),
    ("volcano_island", "active volcano island with red lava streams, dark rocky terrain, dramatic ash sky, palm silhouettes near base, intense"),
    ("ice_isle", "frozen tropical island, palm trees with ice and snow, icebergs in turquoise water, blue cold light, exotic frozen wonder"),
    ("coral_reef", "underwater coral garden with vibrant pink orange purple corals, schools of tropical fish, sunbeams from surface, magical"),
    ("hidden_temple", "ancient overgrown jungle temple with vines and roots, mossy stone pyramids, mysterious carvings, soft mystical light"),
    ("waterfall_paradise", "multi-tier tropical waterfalls cascading into lagoon, rainbow mist, lush jungle, exotic birds, dreamlike"),
    ("lost_city", "submerged ancient city ruins underwater, fish swimming through stone columns, sunbeams, mysterious atlantis vibe"),
]
for slug, desc in REGIONS:
    PHASE_1.append(region(f"region_{slug}", desc))

# Mascot poses — Coco the Parrot (8) — 640x896
PHASE_1 += [
    mascot("mascot_idle", "standing waving one wing happily, friendly smile"),
    mascot("mascot_happy", "celebrating with both wings up, joyful expression, sparkles around"),
    mascot("mascot_victory", "holding gold trophy, triumphant pose, golden glow"),
    mascot("mascot_sad", "drooping wings, sad teary eyes, pouting"),
    mascot("mascot_sleeping", "curled up sleeping with closed eyes, peaceful, zzz bubbles"),
    mascot("mascot_thinking", "wing on chin thinking pose, curious confused expression, question mark above"),
    mascot("mascot_shopping", "carrying shopping bag with coin, excited smile"),
    mascot("mascot_vip", "wearing royal golden crown and cape, regal proud pose, sparkles"),
]

# Map node states (4) — 512x512
PHASE_1 += [
    icon("node_locked", "wooden palm tree round signpost with iron padlock, weathered, bound by rope"),
    icon("node_unlocked", "wooden round plaque with empty star slots, polished tropical wood, ready for stars"),
    icon("node_current", "glowing tropical tiki torch with flame, golden bamboo signpost, magical aura, vibrant attention-grabbing"),
    icon("node_completed", "ornate gold star plaque on bamboo, three filled stars, golden trim, achievement vibe"),
]

# Booster artwork (3) — 512x512
PHASE_1 += [
    icon("booster_hammer", "tribal wooden hammer with shells and feathers, polished wood handle, glowing tip"),
    icon("booster_color_blast", "rainbow conch shell glowing with magical colors, exploding rainbow particles around it"),
    icon("booster_extra_moves", "golden compass with sand hourglass next to it, magical glow, treasure motif"),
]

# Region selector pills (12 — small icon per region) — 256x256
REGION_ICONS = [
    ("rpill_coral_beach", "small coral and seashell"),
    ("rpill_coconut_island", "stylized coconut palm tree"),
    ("rpill_lagoon_palace", "small turquoise lagoon arch"),
    ("rpill_palm_valley", "palm tree with waterfall stripe"),
    ("rpill_sailor_harbor", "small fishing boat with sail"),
    ("rpill_treasure_cave", "treasure chest with gold"),
    ("rpill_volcano_island", "small volcano with lava"),
    ("rpill_ice_isle", "frozen palm tree with snowflake"),
    ("rpill_coral_reef", "coral with tropical fish"),
    ("rpill_hidden_temple", "stone temple pyramid with vines"),
    ("rpill_waterfall_paradise", "tropical waterfall with rainbow"),
    ("rpill_lost_city", "underwater stone column"),
]
for slug, desc in REGION_ICONS:
    PHASE_1.append(icon(slug, desc, dir_="nodes", w=384, h=384))

# Daily reward cards (7) — 512x768
DAILY_REWARDS = [
    ("daily_1", "small wooden chest with few coins inside, day 1 starter reward, simple"),
    ("daily_2", "open coin pouch with small gold coins, day 2 reward, simple"),
    ("daily_3", "wooden chest with gold coins and gem, day 3 reward"),
    ("daily_4", "leather pouch with gem stones, day 4 reward"),
    ("daily_5", "ornate chest with gold coins and ruby gem overflowing, day 5 reward"),
    ("daily_6", "luxurious treasure box with gold and rare gems, magical glow, day 6 reward"),
    ("daily_7", "ultimate massive treasure trove with crown, gold, gems, magical sparkles, day 7 grand prize"),
]
for slug, desc in DAILY_REWARDS:
    PHASE_1.append(icon(slug, desc, dir_="rewards", w=512, h=640))

# Critical UI decorative elements (10) — 512x512
DECOR = [
    ("decor_palm_leaves", "tropical palm leaves cluster, fresh green, isolated decoration element"),
    ("decor_coconut", "single tropical coconut, glossy brown, isolated"),
    ("decor_pearl", "iridescent pearl in open clamshell, shiny"),
    ("decor_starfish", "orange tropical starfish on white, isolated"),
    ("decor_crab", "cute red tropical crab, smiling, mascot-friendly cartoon"),
    ("decor_seashell", "spiral pink seashell, polished shiny, isolated"),
    ("decor_compass", "golden ornate pirate compass, treasure motif"),
    ("decor_map_scroll", "rolled treasure map scroll, parchment, weathered"),
    ("decor_gold_coin", "single gold pirate coin with palm tree imprint, shiny"),
    ("decor_pirate_flag", "small pirate flag with skull and crossbones on bamboo pole, friendly"),
]
for slug, desc in DECOR:
    PHASE_1.append(icon(slug, desc, dir_="decor"))

# ── PHASE 2: 38 polish assets ──

PHASE_2 = []

# Achievement icons (25) — 384x384
ACHIEVEMENTS = [
    ("ach_first_match", "first 3-jelly match achievement icon, star with three small jellies"),
    ("ach_first_combo", "lightning combo achievement, two crossed jellies with electric spark"),
    ("ach_score_10k", "10000 score achievement, gold trophy with 10K mark"),
    ("ach_score_100k", "100000 score achievement, ornate trophy with rays"),
    ("ach_score_1m", "1 million score achievement, legendary diamond trophy"),
    ("ach_level_50", "level 50 achievement, ribbon with number 50, gold"),
    ("ach_level_100", "level 100 achievement, royal banner with 100, premium"),
    ("ach_level_240", "complete all levels achievement, golden crown with 240"),
    ("ach_3stars_50", "fifty 3-star levels achievement, three stars with 50 ribbon"),
    ("ach_perfect_run", "perfect run no boosters achievement, halo over jelly"),
    ("ach_speed_demon", "speed demon achievement, lightning bolt with timer"),
    ("ach_combo_master", "combo master achievement, fireworks of jellies"),
    ("ach_bomb_user", "bomb expert achievement, cartoon bomb with star"),
    ("ach_rocket_user", "rocket expert achievement, cartoon rocket with sparkles"),
    ("ach_rainbow_user", "rainbow expert achievement, rainbow jelly with star"),
    ("ach_lightning_user", "lightning expert achievement, lightning bolt with star"),
    ("ach_daily_streak_7", "7 day streak achievement, calendar with fire"),
    ("ach_daily_streak_30", "30 day streak achievement, golden calendar with crown"),
    ("ach_money_saver", "money saver achievement, piggy bank with coins"),
    ("ach_big_spender", "big spender achievement, golden treasure shower"),
    ("ach_event_winner", "event winner achievement, gold medal with banner"),
    ("ach_friend_helper", "friend helper achievement, two hands shake with hearts"),
    ("ach_tutorial_done", "tutorial complete achievement, graduation cap with star"),
    ("ach_first_purchase", "first purchase achievement, shopping bag with star"),
    ("ach_vip_member", "VIP achievement, royal crown with V"),
]
for slug, desc in ACHIEVEMENTS:
    PHASE_2.append(icon(slug, desc, dir_="achievements", w=384, h=384))

# Shop product cards (8) — 512x640
SHOP = [
    ("shop_coins_500", "small pile of 500 gold pirate coins, glittering"),
    ("shop_coins_1500", "medium chest with 1500 gold coins overflowing"),
    ("shop_coins_5000", "huge treasure trove with 5000 gold coins, gems, premium"),
    ("shop_starter_bundle", "starter bundle box with boosters and coins, ribbon-tied"),
    ("shop_remove_ads", "pirate flag with no symbol over advertisement, clean look"),
    ("shop_vip_monthly", "royal golden parrot crown with VIP banner"),
    ("shop_boosters_x3", "three booster items wrapped together with banner"),
    ("shop_lives_pack", "heart container with magical lives potion bottles"),
]
for slug, desc in SHOP:
    PHASE_2.append(icon(slug, desc, dir_="rewards", w=512, h=640))

# Hero alchemy (5) — 1024x1024 with alchemy
ALCHEMY = [
    {"name": "splash_alchemy_hero", "dir": "backgrounds",
     "prompt": "tropical island adventure scene with cute parrot Coco mascot in foreground waving, treasure chest, lagoon, palm trees, golden sunset, ultra premium Pixar 3D render, mobile game splash screen art, vertical composition with logo space at top",
     "model": PHOENIX, "w": 832, "h": 1248, "alchemy": True, "neg": NEG_SCENE},
    {"name": "main_menu_alchemy_hero", "dir": "backgrounds",
     "prompt": "majestic tropical island with multiple regions visible — coral beach, lagoon, distant volcano — golden hour cinematic, treasure motif, premium Royal Match quality 3D render, vertical composition",
     "model": PHOENIX, "w": 832, "h": 1248, "alchemy": True, "neg": NEG_SCENE},
    {"name": "mascot_hero_alchemy", "dir": "mascot",
     "prompt": "Coco the parrot mascot character, blue and yellow plumage, red crest, big sparkling eyes, holding treasure chest, full body hero pose, isolated white background, ultra premium Pixar 3D character render, character sheet quality",
     "model": PHOENIX, "w": 832, "h": 1248, "alchemy": True, "neg": NEG_CHARACTER + ", scene, background details, environment"},
    {"name": "treasure_chest_hero", "dir": "decor",
     "prompt": "ornate ancient pirate treasure chest overflowing with gold coins, gems, pearls, magical golden glow, hero icon for game, premium 3D render, isolated on simple soft gradient background",
     "model": PHOENIX, "w": 1024, "h": 1024, "alchemy": True, "neg": NEG_ICON},
    {"name": "boss_intro_card", "dir": "backgrounds",
     "prompt": "epic boss level intro card scene, mystical tropical temple with glowing eye, dark stormy sky, dramatic lightning, premium 3D render, vertical card composition",
     "model": PHOENIX, "w": 832, "h": 1248, "alchemy": True, "neg": NEG_SCENE},
]
PHASE_2 += ALCHEMY


def asset_count():
    return {"phase_1": len(PHASE_1), "phase_2": len(PHASE_2), "total": len(PHASE_1) + len(PHASE_2)}


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "count":
        print(asset_count())
    elif len(sys.argv) > 1 and sys.argv[1] == "list":
        for a in PHASE_1 + PHASE_2:
            print(f"{a['dir']:15s} {a['name']:30s} {a.get('w',768)}x{a.get('h',1024)} alch={a.get('alchemy',False)}")
