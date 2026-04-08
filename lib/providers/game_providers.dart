import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/billing/billing_manager.dart';
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
      tutorialCompleted: state.tutorialCompleted,
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
}

final playerProgressProvider =
    StateNotifierProvider<PlayerProgressNotifier, PlayerProgress>((ref) {
  return PlayerProgressNotifier();
});
