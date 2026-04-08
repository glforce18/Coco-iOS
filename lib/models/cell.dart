import 'package:patpat_game/models/enums.dart';

class Cell {
  final int row;
  final int col;
  final JellyType? jellyType;
  final SpecialType specialType;
  final ObstacleType obstacle;
  final bool isMatched;

  const Cell({
    required this.row,
    required this.col,
    this.jellyType,
    this.specialType = SpecialType.none,
    this.obstacle = ObstacleType.none,
    this.isMatched = false,
  });

  bool get isEmpty =>
      jellyType == null &&
      obstacle == ObstacleType.none;

  bool get hasJelly => jellyType != null;

  bool get isBlocked =>
      obstacle == ObstacleType.ice1 ||
      obstacle == ObstacleType.ice2 ||
      obstacle == ObstacleType.box ||
      obstacle == ObstacleType.fog ||
      obstacle == ObstacleType.chocolate;

  bool get isChained =>
      obstacle == ObstacleType.chain1 || obstacle == ObstacleType.chain2;

  bool get canMatch =>
      hasJelly &&
      !isChained &&
      obstacle != ObstacleType.box &&
      obstacle != ObstacleType.chocolate &&
      obstacle != ObstacleType.fog;

  bool get isBubble => obstacle == ObstacleType.bubble;
  bool get isIceWall => obstacle == ObstacleType.iceWall;
  bool get isPortal => obstacle == ObstacleType.portal;

  Cell copyWith({
    int? row,
    int? col,
    JellyType? jellyType,
    bool clearJelly = false,
    SpecialType? specialType,
    ObstacleType? obstacle,
    bool? isMatched,
  }) {
    return Cell(
      row: row ?? this.row,
      col: col ?? this.col,
      jellyType: clearJelly ? null : (jellyType ?? this.jellyType),
      specialType: specialType ?? this.specialType,
      obstacle: obstacle ?? this.obstacle,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  String toString() => 'Cell($row,$col ${jellyType?.name ?? "empty"} '
      '${specialType != SpecialType.none ? specialType.name : ""} '
      '${obstacle != ObstacleType.none ? obstacle.name : ""})';
}
