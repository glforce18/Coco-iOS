import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';

void main() {
  group('GameGrid', () {
    test('creates empty grid with correct dimensions', () {
      final grid = GameGrid(rows: 9, cols: 7);
      expect(grid.rows, equals(9));
      expect(grid.cols, equals(7));
      for (int r = 0; r < grid.rows; r++) {
        for (int c = 0; c < grid.cols; c++) {
          final cell = grid.get(r, c);
          expect(cell.row, equals(r));
          expect(cell.col, equals(c));
          expect(cell.isEmpty, isTrue);
        }
      }
    });

    test('set and get cell', () {
      final grid = GameGrid(rows: 5, cols: 5);
      const newCell = Cell(
        row: 2,
        col: 3,
        jellyType: JellyType.purple,
        specialType: SpecialType.bomb,
      );
      grid.set(2, 3, newCell);
      final retrieved = grid.get(2, 3);
      expect(retrieved.jellyType, equals(JellyType.purple));
      expect(retrieved.specialType, equals(SpecialType.bomb));
      expect(retrieved.row, equals(2));
      expect(retrieved.col, equals(3));
    });

    test('snapshot returns independent copy', () {
      final grid = GameGrid(rows: 3, cols: 3);
      final snap1 = grid.snapshot();
      // Modify the grid after snapshot
      grid.set(
        0,
        0,
        const Cell(row: 0, col: 0, jellyType: JellyType.yellow),
      );
      // The snapshot should not be affected
      expect(snap1[0][0].jellyType, isNull);
      // The live grid should reflect the change
      expect(grid.get(0, 0).jellyType, equals(JellyType.yellow));
    });

    test('version increments on bumpVersion', () {
      final grid = GameGrid(rows: 4, cols: 4);
      expect(grid.version, equals(0));
      grid.bumpVersion();
      expect(grid.version, equals(1));
      grid.bumpVersion();
      grid.bumpVersion();
      expect(grid.version, equals(3));
    });
  });
}
