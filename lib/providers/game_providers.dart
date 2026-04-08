import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/data/progress_storage.dart';

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
