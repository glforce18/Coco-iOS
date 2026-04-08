import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patpat_game/models/player_progress.dart';

class ProgressStorage {
  static const _prefsKey = 'patpat_progress';

  static Future<PlayerProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null) return PlayerProgress();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final progress = PlayerProgress(
        currentLevel: map['currentLevel'] ?? 1,
        stars: _decodeIntMap(map['stars']),
        highScores: _decodeIntMap(map['highScores']),
        totalScore: map['totalScore'] ?? 0,
        lives: map['lives'] ?? 5,
        lastLifeLostTime: map['lastLifeLostTime'] ?? 0,
        coins: map['coins'] ?? 500,
        hammerCount: map['hammerCount'] ?? 3,
        colorBlastCount: map['colorBlastCount'] ?? 2,
        extraMovesCount: map['extraMovesCount'] ?? 3,
        soundEnabled: map['soundEnabled'] ?? true,
        musicEnabled: map['musicEnabled'] ?? true,
        vibrationEnabled: map['vibrationEnabled'] ?? true,
        dailyRewardStreak: map['dailyRewardStreak'] ?? 0,
        lastDailyRewardDay: map['lastDailyRewardDay'] ?? 0,
        piggyBankCoins: map['piggyBankCoins'] ?? 0,
        achievements: Set<String>.from(map['achievements'] ?? []),
        tutorialCompleted: map['tutorialCompleted'] ?? false,
      );
      progress.regenerateLives();
      return progress;
    } catch (_) {
      return PlayerProgress();
    }
  }

  static Future<void> save(PlayerProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'currentLevel': p.currentLevel,
      'stars': _encodeIntMap(p.stars),
      'highScores': _encodeIntMap(p.highScores),
      'totalScore': p.totalScore,
      'lives': p.lives,
      'lastLifeLostTime': p.lastLifeLostTime,
      'coins': p.coins,
      'hammerCount': p.hammerCount,
      'colorBlastCount': p.colorBlastCount,
      'extraMovesCount': p.extraMovesCount,
      'soundEnabled': p.soundEnabled,
      'musicEnabled': p.musicEnabled,
      'vibrationEnabled': p.vibrationEnabled,
      'dailyRewardStreak': p.dailyRewardStreak,
      'lastDailyRewardDay': p.lastDailyRewardDay,
      'piggyBankCoins': p.piggyBankCoins,
      'achievements': p.achievements.toList(),
      'tutorialCompleted': p.tutorialCompleted,
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Map<int, int> _decodeIntMap(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  static Map<String, int> _encodeIntMap(Map<int, int> map) {
    return map.map((k, v) => MapEntry(k.toString(), v));
  }
}
