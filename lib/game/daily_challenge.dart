import 'dart:math';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/position.dart';

/// Types of daily challenges.
enum ChallengeType {
  limitedColors,
  allObstacles,
  timed,
  minimalMoves,
  comboChallenge,
}

/// Generates a daily challenge based on the current date.
class DailyChallengeGenerator {
  DailyChallengeGenerator._();

  /// Returns today's challenge type (deterministic per date).
  static ChallengeType todaysChallengeType() {
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2026, 1, 1)).inDays;
    return ChallengeType.values[daysSinceEpoch % ChallengeType.values.length];
  }

  /// Generates a [LevelConfig] for today's daily challenge.
  static LevelConfig generate() {
    final type = todaysChallengeType();
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed);

    switch (type) {
      case ChallengeType.limitedColors:
        return _limitedColors(rng);
      case ChallengeType.allObstacles:
        return _allObstacles(rng);
      case ChallengeType.timed:
        return _timed(rng);
      case ChallengeType.minimalMoves:
        return _minimalMoves(rng);
      case ChallengeType.comboChallenge:
        return _comboChallenge(rng);
    }
  }

  // ── limitedColors ─────────────────────────────────────────────────────
  // Only 3 jelly colors — easier matching but higher target score.
  static LevelConfig _limitedColors(Random rng) {
    final colors = [JellyType.purple, JellyType.yellow, JellyType.blue];
    colors.shuffle(rng);

    return LevelConfig(
      levelNumber: 0,
      maxMoves: 20,
      goals: [
        LevelGoal(jellyType: colors[0], count: 30),
        LevelGoal(jellyType: colors[1], count: 25),
      ],
      availableTypes: colors,
      region: GameRegion.candyGarden,
      targetScore: 1800,
    );
  }

  // ── allObstacles ──────────────────────────────────────────────────────
  // Board filled with diverse obstacles.
  static LevelConfig _allObstacles(Random rng) {
    final obstacles = <Position, ObstacleType>{};
    final obstaclePool = [
      ObstacleType.ice1,
      ObstacleType.ice2,
      ObstacleType.box,
      ObstacleType.chain1,
      ObstacleType.chain2,
      ObstacleType.fog,
      ObstacleType.honey,
      ObstacleType.chocolate,
    ];

    // Place 12 symmetric obstacles
    for (int i = 0; i < 6; i++) {
      final row = rng.nextInt(9);
      final col = rng.nextInt(3);
      final type = obstaclePool[rng.nextInt(obstaclePool.length)];
      obstacles[Position(row, col)] = type;
      obstacles[Position(row, 6 - col)] = type;
    }

    return LevelConfig(
      levelNumber: 0,
      maxMoves: 25,
      goals: [
        LevelGoal(jellyType: JellyType.green, count: 20),
        LevelGoal(jellyType: JellyType.pink, count: 20),
        LevelGoal(jellyType: JellyType.orange, count: 15),
      ],
      obstacles: obstacles,
      region: GameRegion.sparkleForest,
      targetScore: 2200,
    );
  }

  // ── timed ─────────────────────────────────────────────────────────────
  // 90 second time limit, unlimited moves, high target score.
  static LevelConfig _timed(Random rng) {
    return LevelConfig(
      levelNumber: 0,
      maxMoves: 999,
      goals: [
        LevelGoal(jellyType: JellyType.purple, count: 40),
        LevelGoal(jellyType: JellyType.yellow, count: 35),
      ],
      region: GameRegion.stormPeak,
      targetScore: 2500,
      timeLimit: 90,
    );
  }

  // ── minimalMoves ──────────────────────────────────────────────────────
  // Very few moves — requires strategic play.
  static LevelConfig _minimalMoves(Random rng) {
    return LevelConfig(
      levelNumber: 0,
      maxMoves: 12,
      goals: [
        LevelGoal(jellyType: JellyType.blue, count: 18),
        LevelGoal(jellyType: JellyType.green, count: 15),
      ],
      availableTypes: const [
        JellyType.blue,
        JellyType.green,
        JellyType.pink,
        JellyType.orange,
      ],
      region: GameRegion.crystalCave,
      targetScore: 1200,
    );
  }

  // ── comboChallenge ────────────────────────────────────────────────────
  // Moderate moves, 5 colors, need big combos to meet the high target.
  static LevelConfig _comboChallenge(Random rng) {
    return LevelConfig(
      levelNumber: 0,
      maxMoves: 18,
      goals: [
        LevelGoal(jellyType: JellyType.purple, count: 25),
        LevelGoal(jellyType: JellyType.yellow, count: 25),
        LevelGoal(jellyType: JellyType.pink, count: 20),
      ],
      availableTypes: const [
        JellyType.purple,
        JellyType.yellow,
        JellyType.blue,
        JellyType.green,
        JellyType.pink,
      ],
      region: GameRegion.funLand,
      targetScore: 2000,
    );
  }
}
