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
        winStreak: map['winStreak'] ?? 0,
        coins: map['coins'] ?? 500,
        hammerCount: map['hammerCount'] ?? 3,
        colorBlastCount: map['colorBlastCount'] ?? 2,
        extraMovesCount: map['extraMovesCount'] ?? 3,
        removeAdsPurchased: map['removeAdsPurchased'] ?? false,
        vipActive: map['vipActive'] ?? false,
        starterBundleClaimed: map['starterBundleClaimed'] ?? false,
        soundEnabled: map['soundEnabled'] ?? true,
        musicEnabled: map['musicEnabled'] ?? true,
        vibrationEnabled: map['vibrationEnabled'] ?? true,
        dailyRewardStreak: map['dailyRewardStreak'] ?? 0,
        lastDailyRewardDay: map['lastDailyRewardDay'] ?? 0,
        piggyBankCoins: map['piggyBankCoins'] ?? 0,
        achievements: Set<String>.from(map['achievements'] ?? []),
        decorations: Set<String>.from(map['decorations'] ?? []),
        tutorialCompleted: map['tutorialCompleted'] ?? false,
        lastSpinTime: map['lastSpinTime'] ?? 0,
        lastEventWeek: map['lastEventWeek'] ?? 0,
        eventProgress: _decodeStringIntMap(map['eventProgress']),
        totalCombos: map['totalCombos'] ?? 0,
        totalBoostersUsed: map['totalBoostersUsed'] ?? 0,
        totalIceBroken: map['totalIceBroken'] ?? 0,
        totalChocolateCleared: map['totalChocolateCleared'] ?? 0,
        totalSpecialsCreated: map['totalSpecialsCreated'] ?? 0,
        shopVisited: map['shopVisited'] ?? false,
        wheelSpun: map['wheelSpun'] ?? false,
        eggSlots: _decodeEggSlots(map['eggSlots']),
        hatchedBirds: Set<String>.from(map['hatchedBirds'] ?? []),
        notifsEnabled: map['notifsEnabled'] ?? true,
        notifsLifeFull: map['notifsLifeFull'] ?? true,
        notifsDaily: map['notifsDaily'] ?? true,
        notifsEgg: map['notifsEgg'] ?? true,
        notifsDailyReward: map['notifsDailyReward'] ?? true,
        notifsCampaign: map['notifsCampaign'] ?? true,
        notifsAskedAt: map['notifsAskedAt'] ?? 0,
        fcmToken: map['fcmToken'] ?? '',
        lastPremiumPromoShownAt: map['lastPremiumPromoShownAt'] ?? 0,
        lastSeenUpdateVersion: map['lastSeenUpdateVersion'] ?? '',
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
      'winStreak': p.winStreak,
      'coins': p.coins,
      'hammerCount': p.hammerCount,
      'colorBlastCount': p.colorBlastCount,
      'extraMovesCount': p.extraMovesCount,
      'removeAdsPurchased': p.removeAdsPurchased,
      'vipActive': p.vipActive,
      'starterBundleClaimed': p.starterBundleClaimed,
      'soundEnabled': p.soundEnabled,
      'musicEnabled': p.musicEnabled,
      'vibrationEnabled': p.vibrationEnabled,
      'dailyRewardStreak': p.dailyRewardStreak,
      'lastDailyRewardDay': p.lastDailyRewardDay,
      'piggyBankCoins': p.piggyBankCoins,
      'achievements': p.achievements.toList(),
      'decorations': p.decorations.toList(),
      'tutorialCompleted': p.tutorialCompleted,
      'lastSpinTime': p.lastSpinTime,
      'lastEventWeek': p.lastEventWeek,
      'eventProgress': p.eventProgress,
      'totalCombos': p.totalCombos,
      'totalBoostersUsed': p.totalBoostersUsed,
      'totalIceBroken': p.totalIceBroken,
      'totalChocolateCleared': p.totalChocolateCleared,
      'totalSpecialsCreated': p.totalSpecialsCreated,
      'shopVisited': p.shopVisited,
      'wheelSpun': p.wheelSpun,
      'eggSlots': p.eggSlots.map((e) => e.toMap()).toList(),
      'hatchedBirds': p.hatchedBirds.toList(),
      'notifsEnabled': p.notifsEnabled,
      'notifsLifeFull': p.notifsLifeFull,
      'notifsDaily': p.notifsDaily,
      'notifsEgg': p.notifsEgg,
      'notifsDailyReward': p.notifsDailyReward,
      'notifsCampaign': p.notifsCampaign,
      'notifsAskedAt': p.notifsAskedAt,
      'fcmToken': p.fcmToken,
      'lastPremiumPromoShownAt': p.lastPremiumPromoShownAt,
      'lastSeenUpdateVersion': p.lastSeenUpdateVersion,
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

  static Map<String, int> _decodeStringIntMap(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  static List<EggSlot> _decodeEggSlots(dynamic raw) {
    if (raw == null) return [EggSlot(), EggSlot(), EggSlot()];
    return (raw as List).map((m) => EggSlot.fromMap(m as Map<String, dynamic>)).toList();
  }
}
