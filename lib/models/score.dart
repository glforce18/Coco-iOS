import 'dart:math';

class ScoreCalculator {
  ScoreCalculator._();

  static const _baseScore = 10;
  static const _chainMultiplier = 1.5;

  static int calculate(int matchCount, int chainLevel) {
    return (matchCount * _baseScore * pow(_chainMultiplier, chainLevel - 1)).toInt();
  }

  static int starsForScore(int score, int targetScore) {
    if (score >= targetScore * 2) return 3;
    if (score >= (targetScore * 1.5).toInt()) return 2;
    if (score >= targetScore) return 1;
    return 0;
  }

  static int coinsForLevel(int level, int stars) {
    final base = 20 + level * 2;
    final starBonus = stars * 10;
    int bossBonus = 0;
    if (level > 0 && level % 20 == 0) {
      bossBonus = 100;
    } else if (level > 0 && level % 10 == 0) {
      bossBonus = 50;
    }
    return base + starBonus + bossBonus;
  }
}
