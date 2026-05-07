import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/position.dart';

class LevelGoal {
  final JellyType jellyType;
  final int count;
  final GoalType goalType;
  int collected;

  LevelGoal({
    required this.jellyType,
    required this.count,
    this.goalType = GoalType.collectJelly,
    this.collected = 0,
  });

  bool get isComplete => collected >= count;

  LevelGoal copyReset() => LevelGoal(
        jellyType: jellyType,
        count: count,
        goalType: goalType,
        collected: 0,
      );
}

enum GameRegion {
  candyGarden('Şeker Bahçesi', 1, 20, 0),
  colorHill('Renk Tepesi', 21, 40, 15),
  balloonValley('Balon Vadisi', 41, 60, 40),
  sparkleForest('Işıltılı Orman', 61, 80, 75),
  funLand('Eğlence Ülkesi', 81, 100, 120),
  dreamWorld('Rüya Dünyası', 101, 120, 180),
  crystalCave('Kristal Mağara', 121, 140, 250),
  stormPeak('Fırtına Zirvesi', 141, 160, 320),
  lavaIsland('Lav Adası', 161, 180, 400),
  frozenKingdom('Buz Krallığı', 181, 200, 480),
  shadowRealm('Gölge Diyarı', 201, 220, 560),
  celestialTower('Göksel Kule', 221, 240, 650);

  final String displayName;
  final int startLevel;
  final int endLevel;
  final int starsRequired;
  const GameRegion(
      this.displayName, this.startLevel, this.endLevel, this.starsRequired);

  static GameRegion forLevel(int level) {
    for (final region in values) {
      if (level >= region.startLevel && level <= region.endLevel) return region;
    }
    return candyGarden;
  }
}

class LevelConfig {
  final int levelNumber;
  final int rows;
  final int cols;
  final int maxMoves;
  final List<LevelGoal> goals;
  final Map<Position, ObstacleType> obstacles;
  final List<JellyType> availableTypes;
  final GameRegion region;
  final int targetScore;
  final int timeLimit;

  const LevelConfig({
    required this.levelNumber,
    this.rows = 9,
    this.cols = 7,
    required this.maxMoves,
    required this.goals,
    this.obstacles = const {},
    this.availableTypes = const [
      JellyType.purple,
      JellyType.yellow,
      JellyType.blue,
      JellyType.green,
      JellyType.pink,
      JellyType.orange,
    ],
    required this.region,
    required this.targetScore,
    this.timeLimit = 0,
  });

  bool get isBoss => levelNumber > 0 && levelNumber % 20 == 0;
  bool get isMiniBoss =>
      levelNumber > 0 && levelNumber % 10 == 0 && levelNumber % 20 != 0;
}
