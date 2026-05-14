import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/models/achievement.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/data/progress_storage.dart';
import 'package:patpat_game/data/cloud_sync_manager.dart';
import 'package:patpat_game/notifications/notification_manager.dart';
import 'package:patpat_game/notifications/achievement_bus.dart';

/// Display state of a Yuva egg slot — derived from completed levels +
/// hatched flag in PlayerProgress.
///  - intact:   not yet at this slot's crackLevel
///  - cracked:  reached crackLevel, hasn't reached openLevel yet (eye candy)
///  - open:     reached openLevel, player can tap to hatch
///  - hatched:  player already hatched it (shown as the hatched bird)
enum EggDisplayState { intact, cracked, open, hatched }

class PlayerProgressNotifier extends StateNotifier<PlayerProgress> {
  PlayerProgressNotifier() : super(PlayerProgress());

  Future<void> load() async {
    state = await ProgressStorage.load();
    // Sync persisted audio prefs to live SoundManager on startup.
    SoundManager.instance.enabled = state.soundEnabled;
    SoundManager.instance.ambienceEnabled = state.musicEnabled;
    // Reschedule any active local notifications based on persisted state.
    await _syncNotifications();
  }

  /// Push the current notification preferences + scheduled notifs into
  /// NotificationManager. Call after any state mutation that may affect
  /// life regen, egg heat, daily reward, or notif toggles.
  Future<void> _syncNotifications() async {
    final n = NotificationManager.instance;
    n.masterEnabled = state.notifsEnabled;
    n.lifeFullEnabled = state.notifsLifeFull;
    n.dailyEnabled = state.notifsDaily;
    n.eggEnabled = state.notifsEgg;
    n.dailyRewardEnabled = state.notifsDailyReward;

    if (!state.notifsEnabled) {
      await n.cancelAll();
      return;
    }

    // ─ Life full
    final fullAt = _lifeFullAt();
    if (state.notifsLifeFull && fullAt != null) {
      await n.scheduleLifeFull(fullAt);
    } else {
      await n.cancelLifeFull();
    }

    // ─ Daily reminder (always for tomorrow 19:00)
    if (state.notifsDaily) {
      await n.scheduleDailyReminder();
    } else {
      await n.cancelDaily();
    }

    // ─ Egg ready (any slot reached its openLevel and is unhatched) or
    //   close to ready (within 5 levels of its openLevel).
    final completed = state.currentLevel - 1;
    bool nearReady = false;
    for (int i = 0; i < state.eggSlots.length; i++) {
      if (state.eggSlots[i].hatched) continue;
      final openLvl = EggSlot.openLevels[i];
      if (completed >= openLvl - 5) {
        nearReady = true;
        break;
      }
    }
    if (state.notifsEgg && nearReady) {
      // Fire next day at 09:30 — if user comes back & hatches, sync will cancel.
      final now = DateTime.now();
      final at = DateTime(now.year, now.month, now.day, 9, 30).add(const Duration(days: 1));
      await n.scheduleEggReady(at);
    } else {
      await n.cancelEgg();
    }

    // ─ Daily reward — only if NOT collected today
    if (state.notifsDailyReward) {
      final today = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
      if (state.lastDailyRewardDay < today) {
        await n.scheduleDailyRewardReady();
      } else {
        await n.cancelDailyReward();
      }
    } else {
      await n.cancelDailyReward();
    }
  }

  /// When all 5 lives are full, returns null. Otherwise the absolute time
  /// at which lives will reach 5 again. Mirrors regenerateLives() math.
  DateTime? _lifeFullAt() {
    if (state.lives >= 5 || state.lastLifeLostTime == 0) return null;
    final regenIntervalMs = state.vipActive ? 20 * 60 * 1000 : 30 * 60 * 1000;
    final missing = 5 - state.lives;
    final ts = state.lastLifeLostTime + missing * regenIntervalMs;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  /// Creates a new PlayerProgress with all fields copied from current state,
  /// triggering Riverpod rebuild via new object reference.
  PlayerProgress _copyState() {
    return PlayerProgress(
      currentLevel: state.currentLevel,
      stars: Map<int, int>.from(state.stars),
      highScores: Map<int, int>.from(state.highScores),
      totalScore: state.totalScore,
      lives: state.lives,
      lastLifeLostTime: state.lastLifeLostTime,
      winStreak: state.winStreak,
      coins: state.coins,
      hammerCount: state.hammerCount,
      colorBlastCount: state.colorBlastCount,
      extraMovesCount: state.extraMovesCount,
      removeAdsPurchased: state.removeAdsPurchased,
      vipActive: state.vipActive,
      starterBundleClaimed: state.starterBundleClaimed,
      soundEnabled: state.soundEnabled,
      musicEnabled: state.musicEnabled,
      vibrationEnabled: state.vibrationEnabled,
      dailyRewardStreak: state.dailyRewardStreak,
      lastDailyRewardDay: state.lastDailyRewardDay,
      piggyBankCoins: state.piggyBankCoins,
      achievements: Set<String>.from(state.achievements),
      decorations: Set<String>.from(state.decorations),
      eggSlots: state.eggSlots.map((e) => EggSlot(hatched: e.hatched)).toList(),
      hatchedBirds: Set<String>.from(state.hatchedBirds),
      tutorialCompleted: state.tutorialCompleted,
      lastSpinTime: state.lastSpinTime,
      lastEventWeek: state.lastEventWeek,
      eventProgress: Map<String, int>.from(state.eventProgress),
      totalCombos: state.totalCombos,
      totalBoostersUsed: state.totalBoostersUsed,
      totalIceBroken: state.totalIceBroken,
      totalChocolateCleared: state.totalChocolateCleared,
      totalSpecialsCreated: state.totalSpecialsCreated,
      shopVisited: state.shopVisited,
      wheelSpun: state.wheelSpun,
      notifsEnabled: state.notifsEnabled,
      notifsLifeFull: state.notifsLifeFull,
      notifsDaily: state.notifsDaily,
      notifsEgg: state.notifsEgg,
      notifsDailyReward: state.notifsDailyReward,
      notifsCampaign: state.notifsCampaign,
      notifsAskedAt: state.notifsAskedAt,
      fcmToken: state.fcmToken,
      lastPremiumPromoShownAt: state.lastPremiumPromoShownAt,
      lastSeenUpdateVersion: state.lastSeenUpdateVersion,
    );
  }

  Future<void> completeLevel(int level, int stars, int score, int coins) async {
    state.completeLevel(level, stars, score, coins);
    // Egg progression is purely level-based now — no heat to distribute.
    // Each slot cracks / opens at preset levels (10/25, 50/75, 150/175).
    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
    // Surface any achievements that were tipped over by this level.
    await checkAchievements();
  }

  /// Display state of an egg slot, derived from currentLevel + hatched flag.
  EggDisplayState eggStateFor(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= state.eggSlots.length) {
      return EggDisplayState.intact;
    }
    if (state.eggSlots[slotIndex].hatched) return EggDisplayState.hatched;
    final completed = state.currentLevel - 1;
    final crackLvl = EggSlot.crackLevels[slotIndex];
    final openLvl = EggSlot.openLevels[slotIndex];
    if (completed >= openLvl) return EggDisplayState.open;
    if (completed >= crackLvl) return EggDisplayState.cracked;
    return EggDisplayState.intact;
  }

  /// All bird IDs that can hatch — 7 common + 5 rare.
  static const commonBirds = <String>[
    'jelly_purple', 'jelly_yellow', 'jelly_blue', 'jelly_green',
    'jelly_pink', 'jelly_orange', 'jelly_black',
  ];
  static const rareBirds = <String>[
    'rare_gold', 'rare_iridescent', 'rare_fire', 'rare_ice', 'rare_neon',
  ];
  static List<String> get allBirds => [...commonBirds, ...rareBirds];

  /// Hatch an egg slot — only succeeds if the slot is in the OPEN state
  /// (player reached its openLevel and hasn't hatched it yet). Picks a
  /// random bird with 15% rare drop rate, marks the slot hatched, returns
  /// the newly hatched bird ID.
  Future<String?> hatchEgg(int slotIndex) async {
    if (eggStateFor(slotIndex) != EggDisplayState.open) return null;
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    final isRare = rng.nextDouble() < 0.15;
    final pool = isRare ? rareBirds : commonBirds;
    final birdId = pool[rng.nextInt(pool.length)];
    state.eggSlots[slotIndex] = EggSlot(hatched: true);
    state.hatchedBirds.add(birdId);
    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
    return birdId;
  }

  Future<void> useLife() async {
    state.useLife();
    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
  }

  /// Called when the player loses a level (game over). Drops one life and
  /// resets the win streak.
  Future<void> loseLevel() async {
    state.loseLevel();
    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
  }

  /// Merge cloud progress with local. Keep whichever is more advanced.
  /// After merge, save locally and push merged result to cloud.
  Future<void> mergeWithCloud(PlayerProgress cloudProgress) async {
    if (cloudProgress.currentLevel > state.currentLevel) {
      // Cloud is ahead — adopt cloud state but keep local settings
      final localSound = state.soundEnabled;
      final localMusic = state.musicEnabled;
      final localVibration = state.vibrationEnabled;
      state = PlayerProgress(
        currentLevel: cloudProgress.currentLevel,
        stars: Map<int, int>.from(cloudProgress.stars),
        highScores: Map<int, int>.from(cloudProgress.highScores),
        totalScore: cloudProgress.totalScore,
        lives: cloudProgress.lives,
        lastLifeLostTime: cloudProgress.lastLifeLostTime,
        winStreak: cloudProgress.winStreak,
        coins: cloudProgress.coins,
        hammerCount: cloudProgress.hammerCount,
        colorBlastCount: cloudProgress.colorBlastCount,
        extraMovesCount: cloudProgress.extraMovesCount,
        removeAdsPurchased: state.removeAdsPurchased || cloudProgress.removeAdsPurchased,
        vipActive: state.vipActive || cloudProgress.vipActive,
        starterBundleClaimed: state.starterBundleClaimed || cloudProgress.starterBundleClaimed,
        soundEnabled: localSound,
        musicEnabled: localMusic,
        vibrationEnabled: localVibration,
        dailyRewardStreak: cloudProgress.dailyRewardStreak,
        piggyBankCoins: cloudProgress.piggyBankCoins,
        achievements: Set<String>.from(cloudProgress.achievements),
        tutorialCompleted: cloudProgress.tutorialCompleted,
      );
    } else {
      // Local is ahead or equal — merge best stars & scores from cloud
      final mergedStars = Map<int, int>.from(state.stars);
      for (final entry in cloudProgress.stars.entries) {
        final local = mergedStars[entry.key] ?? 0;
        if (entry.value > local) mergedStars[entry.key] = entry.value;
      }
      final mergedScores = Map<int, int>.from(state.highScores);
      for (final entry in cloudProgress.highScores.entries) {
        final local = mergedScores[entry.key] ?? 0;
        if (entry.value > local) mergedScores[entry.key] = entry.value;
      }
      final mergedAchievements = Set<String>.from(state.achievements)
        ..addAll(cloudProgress.achievements);

      state = PlayerProgress(
        currentLevel: state.currentLevel,
        stars: mergedStars,
        highScores: mergedScores,
        totalScore: state.totalScore,
        lives: state.lives,
        lastLifeLostTime: state.lastLifeLostTime,
        coins: state.coins,
        hammerCount: state.hammerCount,
        colorBlastCount: state.colorBlastCount,
        extraMovesCount: state.extraMovesCount,
        removeAdsPurchased: state.removeAdsPurchased || cloudProgress.removeAdsPurchased,
        vipActive: state.vipActive || cloudProgress.vipActive,
        starterBundleClaimed: state.starterBundleClaimed || cloudProgress.starterBundleClaimed,
        soundEnabled: state.soundEnabled,
        musicEnabled: state.musicEnabled,
        vibrationEnabled: state.vibrationEnabled,
        dailyRewardStreak: state.dailyRewardStreak,
        lastDailyRewardDay: state.lastDailyRewardDay,
        piggyBankCoins: state.piggyBankCoins,
        achievements: mergedAchievements,
        tutorialCompleted: state.tutorialCompleted || cloudProgress.tutorialCompleted,
      );
    }

    await ProgressStorage.save(state);
    // Push merged result back to cloud
    await CloudSyncManager.instance.push(state);
  }

  /// Decrement a booster after the player actually used it in-game.
  /// Hammer/colorBlast: called when the booster's effect fires (cell tapped /
  /// color picked). ExtraMoves: called immediately on activation since +3
  /// moves applies instantly.
  Future<void> consumeBooster(BoosterType type) async {
    switch (type) {
      case BoosterType.hammer:
        if (state.hammerCount > 0) state.hammerCount--;
      case BoosterType.colorBlast:
        if (state.colorBlastCount > 0) state.colorBlastCount--;
      case BoosterType.extraMoves:
        if (state.extraMovesCount > 0) state.extraMovesCount--;
    }
    state.totalBoostersUsed++;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Buy a booster with coins.
  Future<void> buyBooster(BoosterType type) async {
    if (state.coins < type.cost) return;
    state.coins -= type.cost;
    switch (type) {
      case BoosterType.hammer:
        state.hammerCount++;
      case BoosterType.colorBlast:
        state.colorBlastCount++;
      case BoosterType.extraMoves:
        state.extraMovesCount++;
    }
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Deliver a purchased IAP product.
  Future<void> deliverIAP(String productId) async {
    switch (productId) {
      case BillingManager.coinsSmallId:
        state.coins += 500;
      case BillingManager.coinsMediumId:
        state.coins += 1500;
      case BillingManager.coinsLargeId:
        state.coins += 5000;
      case BillingManager.starterBundleId:
        state.coins += 500;
        state.lives = 5;
        state.starterBundleClaimed = true;
      case BillingManager.vipMonthlyId:
        state.vipActive = true;
    }
    state = _copyState();
    await ProgressStorage.save(state);
  }

  Future<void> updateSettings({
    bool? sound,
    bool? music,
    bool? vibration,
  }) async {
    if (sound != null) state.soundEnabled = sound;
    if (music != null) state.musicEnabled = music;
    if (vibration != null) state.vibrationEnabled = vibration;
    // Propagate to live audio system — sound flag controls SFX, music flag
    // controls ambience loop. Music off → stop running loop immediately.
    SoundManager.instance.enabled = state.soundEnabled;
    SoundManager.instance.ambienceEnabled = state.musicEnabled;
    if (!state.musicEnabled) {
      await SoundManager.instance.stopLoop();
    }
    state = _copyState();
    await ProgressStorage.save(state);
  }

  // ---------------------------------------------------------------------------
  // Daily Reward
  // ---------------------------------------------------------------------------

  /// Daily reward table: 7-day cycle.
  static const List<Map<String, int>> dailyRewards = [
    {'coins': 50},
    {'coins': 75},
    {'coins': 100, 'hammer': 1},
    {'coins': 100},
    {'coins': 150, 'colorBlast': 1},
    {'coins': 150},
    {'coins': 300, 'hammer': 2, 'colorBlast': 1, 'extraMoves': 2},
  ];

  /// Whether today's daily reward is available.
  bool get isDailyRewardAvailable {
    final today = _dayOfYear(DateTime.now());
    return state.lastDailyRewardDay != today;
  }

  /// Claim the daily reward. Returns the reward map or null if already claimed.
  Future<Map<String, int>?> claimDailyReward() async {
    if (!isDailyRewardAvailable) return null;

    final today = _dayOfYear(DateTime.now());
    final yesterday = _dayOfYear(DateTime.now().subtract(const Duration(days: 1)));

    // Check if streak continues or resets
    if (state.lastDailyRewardDay == yesterday) {
      state.dailyRewardStreak++;
    } else {
      state.dailyRewardStreak = 1;
    }
    state.lastDailyRewardDay = today;

    final dayIndex = (state.dailyRewardStreak - 1) % 7;
    final reward = dailyRewards[dayIndex];

    // Award the reward (VIP gets 2x coins)
    final coinReward = reward['coins'] ?? 0;
    state.coins += state.vipActive ? coinReward * 2 : coinReward;
    state.hammerCount += reward['hammer'] ?? 0;
    state.colorBlastCount += reward['colorBlast'] ?? 0;
    state.extraMovesCount += reward['extraMoves'] ?? 0;

    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
    return reward;
  }

  /// True when we should auto-show the premium promo modal: user has not
  /// purchased ads removal / VIP, has reached at least level 5, and we
  /// haven't shown the promo in the last 24 hours. completeLevel only
  /// surfaces this every ~10 levels to avoid feeling like begging.
  bool shouldShowPremiumPromo(int completedLevel) {
    if (state.removeAdsPurchased || state.vipActive) return false;
    if (completedLevel < 5) return false;
    if (completedLevel % 10 != 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = state.lastPremiumPromoShownAt;
    const day = 24 * 60 * 60 * 1000;
    return now - last >= day;
  }

  /// Mark the premium promo as just shown so we honor the 24h cooldown.
  Future<void> markPremiumPromoShown() async {
    state.lastPremiumPromoShownAt = DateTime.now().millisecondsSinceEpoch;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Mark a target update version as "seen" so we don't keep nagging the
  /// user about the same release banner.
  Future<void> markUpdateBannerSeen(String version) async {
    if (state.lastSeenUpdateVersion == version) return;
    state.lastSeenUpdateVersion = version;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Add a fixed amount of coins (used by rewarded-ad bonuses, e.g. the
  /// "watch ad to double daily reward" flow).
  Future<void> addBonusCoins(int coins) async {
    if (coins <= 0) return;
    state.coins += coins;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Update notification preferences. Pass nulls for unchanged fields.
  /// Persists + reschedules / cancels notifications accordingly.
  Future<void> updateNotifPrefs({
    bool? master,
    bool? lifeFull,
    bool? daily,
    bool? egg,
    bool? dailyReward,
    bool? campaign,
  }) async {
    if (master != null) state.notifsEnabled = master;
    if (lifeFull != null) state.notifsLifeFull = lifeFull;
    if (daily != null) state.notifsDaily = daily;
    if (egg != null) state.notifsEgg = egg;
    if (dailyReward != null) state.notifsDailyReward = dailyReward;
    if (campaign != null) state.notifsCampaign = campaign;
    state = _copyState();
    await ProgressStorage.save(state);
    await _syncNotifications();
  }

  /// Mark that we've shown the OS permission popup so we don't ask again.
  Future<void> markNotifsAsked() async {
    state.notifsAskedAt = DateTime.now().millisecondsSinceEpoch;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Persist the current FCM token (set by main.dart after registration).
  Future<void> setFcmToken(String token) async {
    if (state.fcmToken == token) return;
    state.fcmToken = token;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  static int _dayOfYear(DateTime d) {
    return d.year * 1000 + d.difference(DateTime(d.year)).inDays;
  }

  // ---------------------------------------------------------------------------
  // Spin Wheel
  // ---------------------------------------------------------------------------

  /// Free spin available every 4 hours (VIP: always free).
  bool get isFreeSpinAvailable {
    if (state.vipActive) return true;
    if (state.lastSpinTime == 0) return true;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - state.lastSpinTime;
    return elapsed >= 4 * 60 * 60 * 1000; // 4 hours
  }

  /// Milliseconds until next free spin.
  int get msUntilFreeSpin {
    if (isFreeSpinAvailable) return 0;
    const cooldown = 4 * 60 * 60 * 1000;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - state.lastSpinTime;
    return (cooldown - elapsed).clamp(0, cooldown);
  }

  /// Spin the wheel and award the prize at [prizeIndex].
  /// [free] = true if using free spin, false if paying 100 coins.
  /// Returns false if the spin cannot be performed.
  Future<bool> spinWheel(int prizeIndex, {required bool free}) async {
    if (!free) {
      if (state.coins < 100) return false;
      state.coins -= 100;
    }

    // Spin wheel prizes (8 segments)
    const prizes = <Map<String, int>>[
      {'coins': 50},
      {'coins': 100},
      {'coins': 200},
      {'coins': 300},
      {'hammer': 1},
      {'colorBlast': 1},
      {'extraMoves': 1},
      {'coins': 50},
    ];

    final prize = prizes[prizeIndex % prizes.length];
    state.coins += prize['coins'] ?? 0;
    state.hammerCount += prize['hammer'] ?? 0;
    state.colorBlastCount += prize['colorBlast'] ?? 0;
    state.extraMovesCount += prize['extraMoves'] ?? 0;

    state.lastSpinTime = DateTime.now().millisecondsSinceEpoch;
    state.wheelSpun = true;

    state = _copyState();
    await ProgressStorage.save(state);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  /// Check all achievements and unlock any newly earned ones.
  /// Returns the list of newly unlocked achievements (for showing popups).
  Future<List<Achievement>> checkAchievements() async {
    final newlyUnlocked = <Achievement>[];

    void check(Achievement a, bool condition) {
      if (!state.achievements.contains(a.id) && condition) {
        state.achievements.add(a.id);
        state.coins += a.coinReward;
        newlyUnlocked.add(a);
        AchievementBus.instance.emit(a);
      }
    }

    final ts = state.totalStars;
    final lvl = state.currentLevel - 1; // completed levels
    final perfects = state.perfectLevelCount;

    check(Achievement.firstMatch, lvl >= 1 || state.totalScore > 0);
    check(Achievement.combo5, state.totalCombos >= 5);
    check(Achievement.combo10, state.totalCombos >= 10);
    check(Achievement.stars50, ts >= 50);
    check(Achievement.stars100, ts >= 100);
    check(Achievement.stars200, ts >= 200);
    check(Achievement.level10, lvl >= 10);
    check(Achievement.level30, lvl >= 30);
    check(Achievement.level60, lvl >= 60);
    check(Achievement.level100, lvl >= 100);
    check(Achievement.level240, lvl >= 240);
    check(Achievement.coins1000, state.coins >= 1000);
    check(Achievement.coins5000, state.coins >= 5000);
    check(Achievement.daily7, state.dailyRewardStreak >= 7);
    check(Achievement.daily30, state.dailyRewardStreak >= 30);
    check(Achievement.perfectLevel, perfects >= 1);
    check(Achievement.perfect10, perfects >= 10);
    check(Achievement.boosterUser, state.totalBoostersUsed >= 10);
    check(Achievement.shopVisitor, state.shopVisited);
    check(Achievement.spinWheel, state.wheelSpun);
    check(Achievement.firstSpecial, state.totalSpecialsCreated >= 1);
    check(Achievement.iceBreaker, state.totalIceBroken >= 50);
    check(Achievement.chocolateLover, state.totalChocolateCleared >= 50);
    // speedRunner is checked at level completion time, not here
    check(Achievement.collector,
        state.achievements.length >= Achievement.values.length - 1);

    if (newlyUnlocked.isNotEmpty) {
      state = _copyState();
      await ProgressStorage.save(state);
    }

    return newlyUnlocked;
  }

  /// Buy a decoration for the mascot home.
  Future<bool> buyDecoration(String decorationId, int price) async {
    if (state.decorations.contains(decorationId)) return false;
    if (state.coins < price) return false;
    state.coins -= price;
    state.decorations.add(decorationId);
    state = _copyState();
    await ProgressStorage.save(state);
    return true;
  }

  /// Mark tutorial as completed.
  Future<void> completeTutorial() async {
    if (state.tutorialCompleted) return;
    state.tutorialCompleted = true;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  /// Mark shop as visited (for achievement tracking).
  Future<void> markShopVisited() async {
    if (state.shopVisited) return;
    state.shopVisited = true;
    state = _copyState();
    await ProgressStorage.save(state);
  }

  // ---------------------------------------------------------------------------
  // Weekly Events
  // ---------------------------------------------------------------------------

  /// Get current ISO week number.
  static int currentWeekNumber() {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(jan1).inDays;
    return ((dayOfYear - now.weekday + 10) / 7).floor();
  }

  /// Reset event progress if we're in a new week.
  Future<void> checkEventWeekReset() async {
    final week = currentWeekNumber();
    if (state.lastEventWeek != week) {
      state.lastEventWeek = week;
      state.eventProgress = {};
      state = _copyState();
      await ProgressStorage.save(state);
    }
  }

  /// Increment event task progress.
  Future<void> incrementEventProgress(String taskId, {int amount = 1}) async {
    state.eventProgress[taskId] =
        (state.eventProgress[taskId] ?? 0) + amount;
    state = _copyState();
    await ProgressStorage.save(state);
  }
}

final playerProgressProvider =
    StateNotifierProvider<PlayerProgressNotifier, PlayerProgress>((ref) {
  return PlayerProgressNotifier();
});
