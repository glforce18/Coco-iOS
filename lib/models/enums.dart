import 'dart:ui';

enum JellyType {
  purple(Color(0xFF8B24DB)),
  yellow(Color(0xFFFFD91A)),
  blue(Color(0xFF338CFF)),
  green(Color(0xFF33D973)),
  pink(Color(0xFFFF4D80)),
  orange(Color(0xFFFF801A));

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
  hammer('Cekic', 100),
  colorBlast('Renk Patlatma', 150),
  extraMoves('+3 Hamle', 80);

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
