import 'dart:ui';

enum JellyType {
  purple(Color(0xFFE63946)),  // RED strawberry / red bird
  yellow(Color(0xFFFFD91A)),  // YELLOW banana / yellow bird
  blue(Color(0xFF338CFF)),    // BLUE blueberry / blue bird
  green(Color(0xFF33D973)),   // GREEN lime / green bird
  pink(Color(0xFFFF4D80)),    // PINK dragon fruit / pink bird
  orange(Color(0xFFFF801A)),  // ORANGE orange / orange bird
  black(Color(0xFF1A1A1A));   // BLACK raven (NEW — visually distinct from red+orange)

  final Color color;
  const JellyType(this.color);
}

enum SpecialType {
  none,
  rocketHorizontal,
  rocketVertical,
  bomb,
  rainbow,
  lightning,
}

enum ObstacleType {
  none,
  ice1,
  ice2,
  box,
  fog,
  chain1,
  chain2,
  chocolate,
  honey,
  portal,
  iceWall,
  bubble,
}

enum GameState {
  idle,
  swapping,
  matching,
  destroying,
  falling,
  refilling,
  checking,
  boosterActive,
  levelComplete,
  gameOver,
  paused,
}

enum BoosterType {
  // Cost balanced against ScoreCalculator.coinsForLevel:
  //   mid-game (level 30-50) ≈ 100-200 coins/level
  //   • ExtraMoves (recovery, +3 moves)        — ~1 mid-game level
  //   • Hammer (single-tile remove)            — ~1.5 mid-game levels
  //   • ColorBlast (wipe one whole color)      — ~2 mid-game levels (premium)
  hammer('Çekiç', 150),
  colorBlast('Renk Patlatma', 250),
  extraMoves('+3 Hamle', 100);

  final String displayName;
  final int cost;
  const BoosterType(this.displayName, this.cost);
}

enum GoalType {
  collectJelly,
  breakIce,
  clearChocolate,
  makeCombos,
}

enum MatchDirection { horizontal, vertical }

enum MatchShape { line3, line4, line5, tShape, lShape }

enum ActiveBoosterMode { none, hammerSelect, colorBlastSelect }

enum SwapDirection { up, down, left, right }
