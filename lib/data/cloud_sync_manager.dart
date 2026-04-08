import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/auth/auth_manager.dart';

class CloudSyncManager {
  static final CloudSyncManager _instance = CloudSyncManager._();
  static CloudSyncManager get instance => _instance;
  CloudSyncManager._();

  /// Push local progress to Firestore.
  Future<void> push(PlayerProgress progress) async {
    if (!AuthManager.instance.firebaseReady) return;
    final accountId = AuthManager.instance.accountId;
    if (accountId == 'guest') return;

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('players').doc(accountId).set({
        'progress_json': jsonEncode(_progressToMap(progress)),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — local progress is authoritative
    }
  }

  /// Pull cloud progress from Firestore.
  Future<PlayerProgress?> pull() async {
    if (!AuthManager.instance.firebaseReady) return null;
    final accountId = AuthManager.instance.accountId;
    if (accountId == 'guest') return null;

    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('players').doc(accountId).get();
      if (!doc.exists) return null;

      final json = doc.data()?['progress_json'] as String?;
      if (json == null) return null;

      return _progressFromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _progressToMap(PlayerProgress p) => {
        'currentLevel': p.currentLevel,
        'stars': p.stars.map((k, v) => MapEntry(k.toString(), v)),
        'highScores': p.highScores.map((k, v) => MapEntry(k.toString(), v)),
        'totalScore': p.totalScore,
        'lives': p.lives,
        'coins': p.coins,
        'hammerCount': p.hammerCount,
        'colorBlastCount': p.colorBlastCount,
        'extraMovesCount': p.extraMovesCount,
        'removeAdsPurchased': p.removeAdsPurchased,
        'vipActive': p.vipActive,
        'starterBundleClaimed': p.starterBundleClaimed,
        'achievements': p.achievements.toList(),
        'tutorialCompleted': p.tutorialCompleted,
        'dailyRewardStreak': p.dailyRewardStreak,
        'piggyBankCoins': p.piggyBankCoins,
      };

  PlayerProgress _progressFromMap(Map<String, dynamic> map) => PlayerProgress(
        currentLevel: map['currentLevel'] ?? 1,
        stars: (map['stars'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
            {},
        highScores: (map['highScores'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
            {},
        totalScore: map['totalScore'] ?? 0,
        lives: map['lives'] ?? 5,
        coins: map['coins'] ?? 500,
        hammerCount: map['hammerCount'] ?? 3,
        colorBlastCount: map['colorBlastCount'] ?? 2,
        extraMovesCount: map['extraMovesCount'] ?? 3,
        removeAdsPurchased: map['removeAdsPurchased'] ?? false,
        vipActive: map['vipActive'] ?? false,
        starterBundleClaimed: map['starterBundleClaimed'] ?? false,
        achievements: Set<String>.from(map['achievements'] ?? []),
        tutorialCompleted: map['tutorialCompleted'] ?? false,
        dailyRewardStreak: map['dailyRewardStreak'] ?? 0,
        piggyBankCoins: map['piggyBankCoins'] ?? 0,
      );
}
