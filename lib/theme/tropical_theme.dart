import 'package:flutter/material.dart';

/// Tropical Adventure design tokens — palette, typography, motion, spacing.
/// Theme: ada/tropikal macera + Royal Match premium 3D render kalitesi.
class TT {
  TT._();

  // ─── Sky / Ocean — primary background palette ───
  static const skyDawn = Color(0xFFFFC58A); // warm sunset orange
  static const skyMid = Color(0xFFFF9E6D);
  static const skyDusk = Color(0xFFE85F5C);
  static const oceanLight = Color(0xFF6FD3E6); // turquoise
  static const ocean = Color(0xFF1FB4D4);
  static const oceanDeep = Color(0xFF0E6E8A);
  static const oceanNight = Color(0xFF053040);

  // ─── Sand / Driftwood — surface chrome ───
  static const sandLight = Color(0xFFFFF1D9);
  static const sand = Color(0xFFF5DBA8);
  static const sandDark = Color(0xFFD9B074);
  static const driftWood = Color(0xFF8B5A2B);
  static const driftWoodDark = Color(0xFF5C3A1A);
  static const bambooLight = Color(0xFFE6C885);
  static const bamboo = Color(0xFFB58D45);
  static const bambooDark = Color(0xFF6E5320);

  // ─── Treasure Gold — premium accents ───
  static const goldShine = Color(0xFFFFE89C);
  static const goldBright = Color(0xFFFFCB3D);
  static const gold = Color(0xFFE8A317);
  static const goldDeep = Color(0xFF9E6A0A);
  static const goldShadow = Color(0xFF5C3F08);

  // ─── Tropical accents ───
  static const palmLight = Color(0xFF7BD66E);
  static const palm = Color(0xFF3CA84F);
  static const palmDark = Color(0xFF1F6B30);
  static const coralLight = Color(0xFFFF8E7A);
  static const coral = Color(0xFFE85A5A); // for cherry-style accents (daily ribbon)
  static const coralDark = Color(0xFFA02838);
  static const lagoonLight = Color(0xFF8EE6D9);
  static const lagoon = Color(0xFF26B89E);
  static const lagoonDark = Color(0xFF0E6F5E);

  // ─── Stars (level rating) ───
  static const starFilled = Color(0xFFFFD24A);
  static const starGlow = Color(0xFFFFF1A8);
  static const starEmpty = Color(0xFF3A2410);

  // ─── Ink / text ───
  static const inkDark = Color(0xFF2A1810);
  static const inkMid = Color(0xFF5C3A1A);
  static const inkLight = Color(0xFFFFF1D9);
  static const inkOcean = Color(0xFF053040);

  // ─── Status / utility ───
  static const danger = Color(0xFFE63946);
  static const success = Color(0xFF2EB05B);
  static const lock = Color(0xFF8B6F4A);

  // ─── Gradients ───
  /// Sky-to-ocean BG gradient (used as fallback under image BGs).
  static const skyOceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyDawn, skyMid, oceanLight, ocean],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  /// Ocean depth gradient (game screen).
  static const oceanDepthGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ocean, oceanDeep, oceanNight],
    stops: [0.0, 0.55, 1.0],
  );

  /// Sand panel gradient (sandy parchment surface).
  static const sandPanelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sandLight, sand, sandDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Driftwood panel gradient.
  static const driftPanelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7A4A20), Color(0xFF5C3A1A), Color(0xFF3D2712)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Treasure gold metallic frame (5-stop highlight → mid → deep → mid → highlight).
  static const goldFrameGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldShine, goldBright, gold, goldDeep, gold, goldBright, goldShine],
    stops: [0.0, 0.18, 0.34, 0.5, 0.66, 0.82, 1.0],
  );

  /// Palm green button gradient.
  static const palmButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [palmLight, palm, palmDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Coral red button gradient (premium / important CTAs).
  static const coralButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [coralLight, coral, coralDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Bamboo wood button gradient (secondary).
  static const bambooButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bambooLight, bamboo, bambooDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Lagoon turquoise button gradient.
  static const lagoonButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lagoonLight, lagoon, lagoonDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Premium gold button gradient (treasure).
  static const goldButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldShine, goldBright, goldDeep],
    stops: [0.0, 0.5, 1.0],
  );

  // ─── Spacing scale (8pt baseline, tropical "wave" rhythm) ───
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space7 = 32.0;
  static const space8 = 40.0;
  static const space9 = 56.0;
  static const space10 = 72.0;

  // ─── Radius scale ───
  static const r1 = 8.0;
  static const r2 = 12.0;
  static const r3 = 18.0;
  static const r4 = 24.0;
  static const r5 = 32.0;

  // ─── Motion timings ───
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const wave = Duration(milliseconds: 1600);

  // ─── Typography ───
  static TextStyle get displayHero => const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: sandLight,
        letterSpacing: 1.5,
        height: 1.0,
        shadows: [
          Shadow(color: Color(0xCC2A1810), offset: Offset(0, 4), blurRadius: 8),
          Shadow(color: Color(0x66000000), offset: Offset(0, 0), blurRadius: 16),
        ],
      );

  static TextStyle get displayLarge => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: sandLight,
        letterSpacing: 1.2,
        height: 1.05,
        shadows: [Shadow(color: Color(0xCC2A1810), offset: Offset(0, 3), blurRadius: 6)],
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: sandLight,
        letterSpacing: 0.8,
        height: 1.1,
        shadows: [Shadow(color: Color(0xCC2A1810), offset: Offset(0, 2), blurRadius: 4)],
      );

  static TextStyle get titleLarge => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: inkDark,
        letterSpacing: 0.5,
        height: 1.15,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: inkDark,
        letterSpacing: 0.4,
        height: 1.2,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: inkDark,
        letterSpacing: 0.3,
        height: 1.25,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: inkDark,
        height: 1.4,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: inkDark,
        height: 1.4,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: inkMid,
        height: 1.35,
      );

  static TextStyle get labelButton => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: sandLight,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 3)],
      );

  static TextStyle get labelChip => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: sandLight,
        letterSpacing: 0.8,
        shadows: [Shadow(color: Color(0x99000000), offset: Offset(0, 1), blurRadius: 2)],
      );

  static TextStyle get numberStat => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: sandLight,
        letterSpacing: 0.6,
        shadows: [Shadow(color: Color(0xCC2A1810), offset: Offset(0, 2), blurRadius: 4)],
      );
}

/// Asset path constants (tropical theme).
class TA {
  TA._();

  // Backgrounds
  static const String mainMenuBg = 'assets/tropical/backgrounds/main_menu_bg.png';
  static const String gameBg = 'assets/tropical/backgrounds/game_bg.png';
  static const String gameJungleBg = 'assets/tropical/backgrounds/game_jungle_bg.png';
  static const String shopBg = 'assets/tropical/backgrounds/shop_bg.png';
  static const String profileBg = 'assets/tropical/backgrounds/profile_bg.png';
  static const String dailyRewardBg = 'assets/tropical/backgrounds/daily_reward_bg.png';
  static const String spinWheelBg = 'assets/tropical/backgrounds/spin_wheel_bg.png';
  static const String eventBg = 'assets/tropical/backgrounds/event_bg.png';
  static const String mascotHomeBg = 'assets/tropical/backgrounds/mascot_home_bg.png';
  static const String cocoHomeInterior = 'assets/tropical/backgrounds/coco_home_interior.png';
  static const String nestSceneBg = 'assets/tropical/backgrounds/nest_scene_bg.png';
  static const String achievementBg = 'assets/tropical/backgrounds/achievement_bg.png';
  static const String noLivesBg = 'assets/tropical/backgrounds/no_lives_bg.png';
  static const String splashHero = 'assets/tropical/backgrounds/splash_alchemy_hero.png';
  static const String mainMenuHero = 'assets/tropical/backgrounds/main_menu_alchemy_hero.png';
  static const String bossIntroCard = 'assets/tropical/backgrounds/boss_intro_card.png';

  // Region BGs (12)
  static String regionBg(String regionAsset) =>
      'assets/tropical/backgrounds/region_$regionAsset.png';

  // Mascot
  static const String mascotIdle = 'assets/tropical/mascot/mascot_idle.png';
  static const String mascotHappy = 'assets/tropical/mascot/mascot_happy.png';
  static const String mascotVictory = 'assets/tropical/mascot/mascot_victory.png';
  static const String mascotSad = 'assets/tropical/mascot/mascot_sad.png';
  static const String mascotSleeping = 'assets/tropical/mascot/mascot_sleeping.png';
  static const String mascotThinking = 'assets/tropical/mascot/mascot_thinking.png';
  static const String mascotShopping = 'assets/tropical/mascot/mascot_shopping.png';
  static const String mascotVip = 'assets/tropical/mascot/mascot_vip.png';
  static const String mascotHero = 'assets/tropical/mascot/mascot_hero_alchemy.png';

  // Map nodes
  static const String nodeLocked = 'assets/tropical/icons/node_locked.png';
  static const String nodeUnlocked = 'assets/tropical/icons/node_unlocked.png';
  static const String nodeCurrent = 'assets/tropical/icons/node_current.png';
  static const String nodeCompleted = 'assets/tropical/icons/node_completed.png';

  // Boosters
  static const String boosterHammer = 'assets/tropical/icons/booster_hammer.png';
  static const String boosterColorBlast = 'assets/tropical/icons/booster_color_blast.png';
  static const String boosterExtraMoves = 'assets/tropical/icons/booster_extra_moves.png';

  // Region pills
  static String regionPill(String slug) => 'assets/tropical/nodes/rpill_$slug.png';

  // Decor
  static const String decorPalmLeaves = 'assets/tropical/decor/decor_palm_leaves.png';
  static const String decorCoconut = 'assets/tropical/decor/decor_coconut.png';
  static const String decorPearl = 'assets/tropical/decor/decor_pearl.png';
  static const String decorStarfish = 'assets/tropical/decor/decor_starfish.png';
  static const String decorCrab = 'assets/tropical/decor/decor_crab.png';
  static const String decorSeashell = 'assets/tropical/decor/decor_seashell.png';
  static const String decorCompass = 'assets/tropical/decor/decor_compass.png';
  static const String decorMapScroll = 'assets/tropical/decor/decor_map_scroll.png';
  static const String decorGoldCoin = 'assets/tropical/decor/decor_gold_coin.png';
  static const String decorPirateFlag = 'assets/tropical/decor/decor_pirate_flag.png';
  static const String decorTreasureChest = 'assets/tropical/decor/treasure_chest_hero.png';

  // Daily rewards 1-7
  static String dailyReward(int day) => 'assets/tropical/rewards/daily_$day.png';

  // Shop products
  static const String shopCoins500 = 'assets/tropical/rewards/shop_coins_500.png';
  static const String shopCoins1500 = 'assets/tropical/rewards/shop_coins_1500.png';
  static const String shopCoins5000 = 'assets/tropical/rewards/shop_coins_5000.png';
  static const String shopStarter = 'assets/tropical/rewards/shop_starter_bundle.png';
  static const String shopRemoveAds = 'assets/tropical/rewards/shop_remove_ads.png';
  // shopVip asset reference removed — VIP subscription hidden until v1.1.
  static const String shopBoostersX3 = 'assets/tropical/rewards/shop_boosters_x3.png';
  static const String shopLives = 'assets/tropical/rewards/shop_lives_pack.png';

  // Achievement icon path resolver
  static String achievement(String slug) => 'assets/tropical/achievements/ach_$slug.png';
}
