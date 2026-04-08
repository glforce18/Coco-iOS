import 'package:patpat_game/models/cell.dart';

class GameGrid {
  final int rows;
  final int cols;
  final List<List<Cell>> _data;
  int _version = 0;

  int get version => _version;

  GameGrid({required this.rows, required this.cols})
      : _data = List.generate(
          rows,
          (r) => List.generate(cols, (c) => Cell(row: r, col: c)),
        );

  GameGrid.fromData(this._data)
      : rows = _data.length,
        cols = _data.isEmpty ? 0 : _data[0].length;

  Cell get(int row, int col) => _data[row][col];

  void set(int row, int col, Cell cell) {
    _data[row][col] = cell;
  }

  void bumpVersion() => _version++;

  List<List<Cell>> get raw => _data;

  List<List<Cell>> snapshot() {
    return List.generate(
      rows,
      (r) => List.generate(cols, (c) => _data[r][c]),
    );
  }
}
