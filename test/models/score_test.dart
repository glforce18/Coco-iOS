import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/score.dart';

void main() {
  group('ScoreCalculator', () {
    group('calculate', () {
      test('base score for 3-match chain 1 = 30', () {
        // 3 * 10 * 1.5^0 = 3 * 10 * 1 = 30
        expect(ScoreCalculator.calculate(3, 1), equals(30));
      });

      test('chain multiplier: 3-match chain 2 = 45', () {
        // 3 * 10 * 1.5^1 = 30 * 1.5 = 45
        expect(ScoreCalculator.calculate(3, 2), equals(45));
      });

      test('chain 3: 4-match chain 3 = 90', () {
        // 4 * 10 * 1.5^2 = 40 * 2.25 = 90
        expect(ScoreCalculator.calculate(4, 3), equals(90));
      });
    });

    group('starsForScore', () {
      test('returns 3 stars when score >= targetScore * 2', () {
        expect(ScoreCalculator.starsForScore(2000, 1000), equals(3));
        expect(ScoreCalculator.starsForScore(1000, 500), equals(3));
      });

      test('returns 2 stars when score >= targetScore * 1.5', () {
        expect(ScoreCalculator.starsForScore(1500, 1000), equals(2));
        expect(ScoreCalculator.starsForScore(750, 500), equals(2));
      });

      test('returns 1 star when score >= targetScore', () {
        expect(ScoreCalculator.starsForScore(1000, 1000), equals(1));
        expect(ScoreCalculator.starsForScore(500, 500), equals(1));
      });

      test('returns 0 stars when score < targetScore', () {
        expect(ScoreCalculator.starsForScore(999, 1000), equals(0));
        expect(ScoreCalculator.starsForScore(0, 100), equals(0));
      });
    });

    group('coinsForLevel', () {
      test('coins for early level (level 1, 2 stars)', () {
        // base = 20 + 1*2 = 22, starBonus = 2*10 = 20, bossBonus = 0
        expect(ScoreCalculator.coinsForLevel(1, 2), equals(42));
      });

      test('coins for boss level (level 20, 3 stars)', () {
        // base = 20 + 20*2 = 60, starBonus = 3*10 = 30, bossBonus = 100
        expect(ScoreCalculator.coinsForLevel(20, 3), equals(190));
      });

      test('coins for mini boss level (level 10, 1 star)', () {
        // base = 20 + 10*2 = 40, starBonus = 1*10 = 10, bossBonus = 50
        expect(ScoreCalculator.coinsForLevel(10, 1), equals(100));
      });

      test('level 40 is boss level', () {
        // base = 20 + 40*2 = 100, starBonus = 3*10 = 30, bossBonus = 100
        expect(ScoreCalculator.coinsForLevel(40, 3), equals(230));
      });

      test('level 30 is mini boss level', () {
        // base = 20 + 30*2 = 80, starBonus = 2*10 = 20, bossBonus = 50
        expect(ScoreCalculator.coinsForLevel(30, 2), equals(150));
      });
    });
  });
}
