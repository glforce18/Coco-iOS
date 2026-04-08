import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/models/achievement.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/data/progress_storage.dart';
import 'package:patpat_game/data/cloud_sync_manager.dart';

class PlayerProgressNotifier extends StateNotifier<PlayerProgress> {
  PlayerProgressNotifier() : super(PlayerProgress());

  Future<void> load() async {
    state = await ProgressStorage.load();
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
    );
  }

  Future<void> completeLevel(int level, int stars, int score, int coins) async {
    state.completeLevel(level, stars, score, coins);
    state = _copyState();
    await ProgressStorage.save(state);
  }

  Future<void> useLife() async {
    state.useLife();
    state = _copyState();
    await ProgressStorage.save(state);
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
      case BillingManager.removeAdsId:
        state.removeAdsPurchased = true;
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
    return reward;
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
