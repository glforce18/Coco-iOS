import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/game/level_generator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/position.dart';

void main() {
  group('LevelGenerator', () {
    group('calculateDifficulty', () {
      test('level 1 difficulty is near 0', () {
        final d = LevelGenerator.calculateDifficulty(1);
        expect(d, lessThan(0.05));
        expect(d, greaterThanOrEqualTo(0.0));
      });

      test('level 120 difficulty is near 0.5', () {
        final d = LevelGenerator.calculateDifficulty(120);
        expect(d, greaterThan(0.4));
        expect(d, lessThan(0.6));
      });

      test('level 240 difficulty is near 1', () {
        final d = LevelGenerator.calculateDifficulty(240);
        expect(d, greaterThan(0.95));
        expect(d, lessThanOrEqualTo(1.0));
      });

      test('difficulty increases over levels (general trend)', () {
        final d10 = LevelGenerator.calculateDifficulty(10);
        final d50 = LevelGenerator.calculateDifficulty(50);
        final d100 = LevelGenerator.calculateDifficulty(100);
        final d200 = LevelGenerator.calculateDifficulty(200);
        // General upward trend (micro-variation may cause local dips).
        expect(d50, greaterThan(d10));
        expect(d100, greaterThan(d50));
        expect(d200, greaterThan(d100));
      });

      test('difficulty is always clamped to [0, 1]', () {
        for (var level = 1; level <= 240; level++) {
          final d = LevelGenerator.calculateDifficulty(level);
          expect(d, greaterThanOrEqualTo(0.0),
              reason: 'Level $level difficulty < 0');
          expect(d, lessThanOrEqualTo(1.0),
              reason: 'Level $level difficulty > 1');
        }
      });
    });

    group('generate — level 1', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(1);
      });

      test('valid grid dimensions (9x7)', () {
        expect(config.rows, equals(9));
        expect(config.cols, equals(7));
      });

      test('moves in valid range [10, 30]', () {
        expect(config.maxMoves, greaterThanOrEqualTo(10));
        expect(config.maxMoves, lessThanOrEqualTo(30));
      });

      test('goals are non-empty', () {
        expect(config.goals, isNotEmpty);
      });

      test('region is candyGarden', () {
        expect(config.region, equals(GameRegion.candyGarden));
      });

      test('level 1 has 4 colors', () {
        expect(config.availableTypes.length, equals(4));
        expect(config.availableTypes, contains(JellyType.purple));
        expect(config.availableTypes, contains(JellyType.yellow));
        expect(config.availableTypes, contains(JellyType.blue));
        expect(config.availableTypes, contains(JellyType.green));
        expect(config.availableTypes, isNot(contains(JellyType.pink)));
        expect(config.availableTypes, isNot(contains(JellyType.orange)));
      });

      test('level 1 has no obstacles', () {
        expect(config.obstacles, isEmpty);
      });

      test('level 1 has no time limit', () {
        expect(config.timeLimit, equals(0));
      });

      test('level 1 is not boss or miniboss', () {
        expect(config.isBoss, isFalse);
        expect(config.isMiniBoss, isFalse);
      });

      test('target score in valid range', () {
        expect(config.targetScore, greaterThanOrEqualTo(250));
        expect(config.targetScore, lessThanOrEqualTo(3500));
      });
    });

    group('generate — level 2', () {
      test('level 2 also has 4 colors', () {
        final config = LevelGenerator.generate(2);
        expect(config.availableTypes.length, equals(4));
      });
    });

    group('generate — level 3', () {
      test('level 3 has 5 colors (adds pink)', () {
        final config = LevelGenerator.generate(3);
        expect(config.availableTypes.length, equals(5));
        expect(config.availableTypes, contains(JellyType.pink));
      });
    });

    group('generate — level 20 (boss)', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(20);
      });

      test('level 20 is boss', () {
        expect(config.isBoss, isTrue);
        expect(config.isMiniBoss, isFalse);
      });

      test('level 20 boss does NOT have a timer (first region boss)', () {
        expect(config.timeLimit, equals(0));
      });

      test('level 20 is in candyGarden', () {
        expect(config.region, equals(GameRegion.candyGarden));
      });
    });

    group('generate — level 40 (boss with timer)', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(40);
      });

      test('level 40 is boss', () {
        expect(config.isBoss, isTrue);
      });

      test('level 40 boss has a timer', () {
        // 80 + max(0, 120 - 40) = 80 + 80 = 160
        expect(config.timeLimit, equals(160));
      });
    });

    group('generate — level 50 (miniboss with timer)', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(50);
      });

      test('level 50 is miniboss', () {
        expect(config.isMiniBoss, isTrue);
        expect(config.isBoss, isFalse);
      });

      test('level 50 miniboss has timer of 100', () {
        expect(config.timeLimit, equals(100));
      });
    });

    group('generate — level 30 (miniboss, no timer)', () {
      test('level 30 is miniboss but no timer (level < 41)', () {
        final config = LevelGenerator.generate(30);
        expect(config.isMiniBoss, isTrue);
        expect(config.timeLimit, equals(0));
      });
    });

    group('generate — level 100', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(100);
      });

      test('level 100 has 6 colors', () {
        expect(config.availableTypes.length, equals(6));
        expect(config.availableTypes, contains(JellyType.orange));
      });

      test('level 100 is boss', () {
        expect(config.isBoss, isTrue);
      });

      test('level 100 has obstacles', () {
        expect(config.obstacles, isNotEmpty);
      });
    });

    group('generate — level 240', () {
      late LevelConfig config;

      setUp(() {
        config = LevelGenerator.generate(240);
      });

      test('valid config with 9x7 grid', () {
        expect(config.rows, equals(9));
        expect(config.cols, equals(7));
      });

      test('region is celestialTower', () {
        expect(config.region, equals(GameRegion.celestialTower));
      });

      test('level 240 is boss', () {
        expect(config.isBoss, isTrue);
      });

      test('has high target score', () {
        expect(config.targetScore, greaterThan(2000));
      });

      test('moves in valid range', () {
        expect(config.maxMoves, greaterThanOrEqualTo(10));
        expect(config.maxMoves, lessThanOrEqualTo(30));
      });

      test('goals are non-empty', () {
        expect(config.goals, isNotEmpty);
      });
    });

    group('all 240 levels generate without error', () {
      test('generate all levels', () {
        for (var level = 1; level <= 240; level++) {
          final config = LevelGenerator.generate(level);

          expect(config.levelNumber, equals(level),
              reason: 'Level $level: wrong levelNumber');
          expect(config.rows, equals(9),
              reason: 'Level $level: wrong rows');
          expect(config.cols, equals(7),
              reason: 'Level $level: wrong cols');
          expect(config.maxMoves, greaterThanOrEqualTo(10),
              reason: 'Level $level: moves < 10');
          expect(config.maxMoves, lessThanOrEqualTo(30),
              reason: 'Level $level: moves > 30');
          expect(config.goals, isNotEmpty,
              reason: 'Level $level: no goals');
          expect(config.targetScore, greaterThanOrEqualTo(250),
              reason: 'Level $level: score < 250');
          expect(config.targetScore, lessThanOrEqualTo(3500),
              reason: 'Level $level: score > 3500');
          expect(config.timeLimit, greaterThanOrEqualTo(0),
              reason: 'Level $level: negative time limit');
          expect(config.availableTypes.length, greaterThanOrEqualTo(4),
              reason: 'Level $level: too few colors');
          expect(config.availableTypes.length, lessThanOrEqualTo(6),
              reason: 'Level $level: too many colors');

          // Goal counts must be in [5, 80].
          for (final goal in config.goals) {
            expect(goal.count, greaterThanOrEqualTo(5),
                reason: 'Level $level: goal count < 5');
            expect(goal.count, lessThanOrEqualTo(80),
                reason: 'Level $level: goal count > 80');
          }

          // Obstacles should be within grid bounds.
          for (final pos in config.obstacles.keys) {
            expect(pos.row, greaterThanOrEqualTo(0),
                reason: 'Level $level: obstacle row < 0');
            expect(pos.row, lessThan(9),
                reason: 'Level $level: obstacle row >= 9');
            expect(pos.col, greaterThanOrEqualTo(0),
                reason: 'Level $level: obstacle col < 0');
            expect(pos.col, lessThan(7),
                reason: 'Level $level: obstacle col >= 7');
          }

          // No obstacles before level 9.
          if (level < 9) {
            expect(config.obstacles, isEmpty,
                reason: 'Level $level: has obstacles before level 9');
          }
        }
      });
    });

    group('obstacle generation', () {
      test('level 9 introduces first obstacles', () {
        final config = LevelGenerator.generate(9);
        expect(config.obstacles, isNotEmpty);
      });

      test('obstacles have symmetric placement', () {
        // Check a mid-level that has obstacles.
        final config = LevelGenerator.generate(50);
        if (config.obstacles.length >= 2) {
          // At least some positions should have mirrors.
          var mirroredCount = 0;
          for (final pos in config.obstacles.keys) {
            if (pos.col < 3) {
              final mirror = Position(pos.row, 6 - pos.col);
              if (config.obstacles.containsKey(mirror)) {
                mirroredCount++;
              }
            }
          }
          // There should be at least one mirrored pair.
          expect(mirroredCount, greaterThan(0),
              reason: 'No mirrored obstacle pairs found');
        }
      });
    });

    group('available obstacles by level', () {
      test('level 9 only has ice1', () {
        final config = LevelGenerator.generate(9);
        final types = config.obstacles.values.toSet();
        // Level 9 only has ice1 available (ice2 unlocks at level 10).
        if (config.obstacles.isNotEmpty) {
          expect(types.every((t) => t == ObstacleType.ice1), isTrue,
              reason: 'Level 9 should only have ice1');
        }
      });

      test('level 72+ can have chocolate', () {
        // Generate enough levels in the 72+ range to find chocolate.
        var foundChocolate = false;
        for (var level = 72; level <= 100; level++) {
          final config = LevelGenerator.generate(level);
          if (config.obstacles.values.contains(ObstacleType.chocolate)) {
            foundChocolate = true;
            break;
          }
        }
        expect(foundChocolate, isTrue,
            reason: 'Chocolate should appear in levels 72-100');
      });
    });

    group('deterministic generation', () {
      test('same level always produces same config', () {
        final config1 = LevelGenerator.generate(42);
        final config2 = LevelGenerator.generate(42);

        expect(config1.maxMoves, equals(config2.maxMoves));
        expect(config1.targetScore, equals(config2.targetScore));
        expect(config1.timeLimit, equals(config2.timeLimit));
        expect(config1.goals.length, equals(config2.goals.length));
        expect(config1.obstacles.length, equals(config2.obstacles.length));
        expect(config1.availableTypes, equals(config2.availableTypes));
      });
    });

    group('region assignment', () {
      test('level 1 is candyGarden', () {
        expect(LevelGenerator.generate(1).region, GameRegion.candyGarden);
      });

      test('level 21 is colorHill', () {
        expect(LevelGenerator.generate(21).region, GameRegion.colorHill);
      });

      test('level 221 is celestialTower', () {
        expect(LevelGenerator.generate(221).region, GameRegion.celestialTower);
      });
    });
  });
}
