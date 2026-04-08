import 'package:patpat_game/models/enums.dart';

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  Position operator +(Position other) => Position(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode * 31);

  @override
  String toString() => 'Pos($row, $col)';

  bool isValid(int rows, int cols) => row >= 0 && row < rows && col >= 0 && col < cols;

  bool isAdjacentTo(Position other) {
    final dr = (row - other.row).abs();
    final dc = (col - other.col).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  static Position fromDirection(Position from, SwapDirection dir) {
    switch (dir) {
      case SwapDirection.up:
        return Position(from.row - 1, from.col);
      case SwapDirection.down:
        return Position(from.row + 1, from.col);
      case SwapDirection.left:
        return Position(from.row, from.col - 1);
      case SwapDirection.right:
        return Position(from.row, from.col + 1);
    }
  }
}
