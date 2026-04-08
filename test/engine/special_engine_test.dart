import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/engine/special_engine.dart';

void main() {

  // ────────────────────────────────────────────
  // activateSpecial
  // ────────────────────────────────────────────

  group('activateSpecial', () {
    test('rocketHorizontal clears entire row', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            specialType: SpecialType.rocketHorizontal,
          ),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
          const Cell(row: 0, col: 3, jellyType: JellyType.green),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.green),
          const Cell(row: 1, col: 1, jellyType: JellyType.blue),
          const Cell(row: 1, col: 2, jellyType: JellyType.purple),
          const Cell(row: 1, col: 3, jellyType: JellyType.yellow),
        ],
      ]);

      final effects = SpecialEngine.activateSpecial(
        grid,
        const Position(0, 1),
        null,
      );

      // All 4 cells in row 0 should be cleared
      for (int c = 0; c < 4; c++) {
        expect(grid.get(0, c).hasJelly, isFalse,
            reason: 'Cell (0,$c) should be cleared');
      }
      // Row 1 should be untouched
      for (int c = 0; c < 4; c++) {
        expect(grid.get(1, c).hasJelly, isTrue,
            reason: 'Cell (1,$c) should still have jelly');
      }
      expect(effects, hasLength(4));
    });

    test('rocketVertical clears entire column', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            specialType: SpecialType.rocketVertical,
          ),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.green),
          const Cell(row: 1, col: 1, jellyType: JellyType.blue),
        ],
        [
          const Cell(row: 2, col: 0, jellyType: JellyType.blue),
          const Cell(row: 2, col: 1, jellyType: JellyType.purple),
        ],
      ]);

      final effects = SpecialEngine.activateSpecial(
        grid,
        const Position(0, 1),
        null,
      );

      // All cells in column 1 should be cleared
      for (int r = 0; r < 3; r++) {
        expect(grid.get(r, 1).hasJelly, isFalse,
            reason: 'Cell ($r,1) should be cleared');
      }
      // Column 0 should be untouched
      for (int r = 0; r < 3; r++) {
        expect(grid.get(r, 0).hasJelly, isTrue,
            reason: 'Cell ($r,0) should still have jelly');
      }
      expect(effects, hasLength(3));
    });

    test('bomb clears 3x3 area', () {
      // 5x5 grid, bomb at center (2,2)
      final grid = GameGrid.fromData(
        List.generate(
          5,
          (r) => List.generate(
            5,
            (c) => Cell(
              row: r,
              col: c,
              jellyType: JellyType.values[c % 6],
              specialType:
                  (r == 2 && c == 2) ? SpecialType.bomb : SpecialType.none,
            ),
          ),
        ),
      );

      final effects = SpecialEngine.activateSpecial(
        grid,
        const Position(2, 2),
        null,
      );

      // 3x3 area around (2,2) should be cleared: rows 1-3, cols 1-3
      for (int r = 1; r <= 3; r++) {
        for (int c = 1; c <= 3; c++) {
          expect(grid.get(r, c).hasJelly, isFalse,
              reason: 'Cell ($r,$c) should be cleared by bomb');
        }
      }
      // Corners should be untouched
      expect(grid.get(0, 0).hasJelly, isTrue);
      expect(grid.get(0, 4).hasJelly, isTrue);
      expect(grid.get(4, 0).hasJelly, isTrue);
      expect(grid.get(4, 4).hasJelly, isTrue);

      expect(effects, hasLength(9));
    });

    test('rainbow clears all of target color', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rainbow,
          ),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.yellow),
          const Cell(row: 1, col: 1, jellyType: JellyType.green),
          const Cell(row: 1, col: 2, jellyType: JellyType.yellow),
        ],
      ]);

      final effects = SpecialEngine.activateSpecial(
        grid,
        const Position(0, 0),
        JellyType.yellow, // target yellow
      );

      // Rainbow cell itself should be cleared
      expect(grid.get(0, 0).hasJelly, isFalse);
      // All yellow cells should be cleared
      expect(grid.get(0, 1).hasJelly, isFalse);
      expect(grid.get(1, 0).hasJelly, isFalse);
      expect(grid.get(1, 2).hasJelly, isFalse);
      // Non-yellow cells should remain
      expect(grid.get(0, 2).hasJelly, isTrue); // blue
      expect(grid.get(1, 1).hasJelly, isTrue); // green

      // 1 rainbow + 3 yellows = 4
      expect(effects, hasLength(4));
    });

    test('iceWall is never cleared by special', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rocketHorizontal,
          ),
          const Cell(row: 0, col: 1, obstacle: ObstacleType.iceWall),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
      ]);

      SpecialEngine.activateSpecial(grid, const Position(0, 0), null);

      // iceWall should remain
      expect(grid.get(0, 1).isIceWall, isTrue);
      // Others should be cleared
      expect(grid.get(0, 0).hasJelly, isFalse);
      expect(grid.get(0, 2).hasJelly, isFalse);
    });

    test('ice2 degrades to ice1', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rocketHorizontal,
          ),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            obstacle: ObstacleType.ice2,
          ),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
      ]);

      SpecialEngine.activateSpecial(grid, const Position(0, 0), null);

      // ice2 should degrade to ice1, jelly stays
      expect(grid.get(0, 1).obstacle, ObstacleType.ice1);
      expect(grid.get(0, 1).hasJelly, isTrue);
    });

    test('portal obstacle is preserved when cleared', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rocketHorizontal,
          ),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            obstacle: ObstacleType.portal,
          ),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
      ]);

      SpecialEngine.activateSpecial(grid, const Position(0, 0), null);

      // Portal should remain, but jelly cleared
      expect(grid.get(0, 1).isPortal, isTrue);
      expect(grid.get(0, 1).hasJelly, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // activateSpecialCombo
  // ────────────────────────────────────────────

  group('activateSpecialCombo', () {
    test('rainbow + rainbow clears entire board', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rainbow,
          ),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            specialType: SpecialType.rainbow,
          ),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.green),
          const Cell(row: 1, col: 1, jellyType: JellyType.purple),
          const Cell(row: 1, col: 2, jellyType: JellyType.yellow),
        ],
      ]);

      final effects = SpecialEngine.activateSpecialCombo(
        grid,
        const Position(0, 0),
        const Position(0, 1),
      );

      // Every cell should be cleared
      for (int r = 0; r < 2; r++) {
        for (int c = 0; c < 3; c++) {
          expect(grid.get(r, c).hasJelly, isFalse,
              reason: 'Cell ($r,$c) should be cleared');
        }
      }
      expect(effects, hasLength(6));
    });

    test('bomb + bomb clears 5x5 area', () {
      // 7x7 grid, bombs at (3,3) and (3,4)
      final grid = GameGrid.fromData(
        List.generate(
          7,
          (r) => List.generate(
            7,
            (c) => Cell(
              row: r,
              col: c,
              jellyType: JellyType.values[c % 6],
              specialType: (r == 3 && c == 3) || (r == 3 && c == 4)
                  ? SpecialType.bomb
                  : SpecialType.none,
            ),
          ),
        ),
      );

      final effects = SpecialEngine.activateSpecialCombo(
        grid,
        const Position(3, 3),
        const Position(3, 4),
      );

      // 5x5 area around (3,3): rows 1-5, cols 1-5
      for (int r = 1; r <= 5; r++) {
        for (int c = 1; c <= 5; c++) {
          expect(grid.get(r, c).hasJelly, isFalse,
              reason: 'Cell ($r,$c) should be cleared by 5x5 bomb');
        }
      }

      // Corner cells should be untouched
      expect(grid.get(0, 0).hasJelly, isTrue);
      expect(grid.get(0, 6).hasJelly, isTrue);
      expect(grid.get(6, 0).hasJelly, isTrue);
      expect(grid.get(6, 6).hasJelly, isTrue);

      expect(effects, hasLength(25));
    });

    test('rocket + rocket creates cross (full row + full col)', () {
      // 5x5 grid, rockets at (2,2) and (2,3)
      final grid = GameGrid.fromData(
        List.generate(
          5,
          (r) => List.generate(
            5,
            (c) => Cell(
              row: r,
              col: c,
              jellyType: JellyType.values[c % 6],
              specialType: (r == 2 && c == 2)
                  ? SpecialType.rocketHorizontal
                  : (r == 2 && c == 3)
                      ? SpecialType.rocketVertical
                      : SpecialType.none,
            ),
          ),
        ),
      );

      SpecialEngine.activateSpecialCombo(
        grid,
        const Position(2, 2),
        const Position(2, 3),
      );

      // Entire row 2 should be cleared
      for (int c = 0; c < 5; c++) {
        expect(grid.get(2, c).hasJelly, isFalse,
            reason: 'Cell (2,$c) should be cleared');
      }
      // Entire column 2 should be cleared
      for (int r = 0; r < 5; r++) {
        expect(grid.get(r, 2).hasJelly, isFalse,
            reason: 'Cell ($r,2) should be cleared');
      }

      // Cells not on row 2 or col 2 should remain
      expect(grid.get(0, 0).hasJelly, isTrue);
      expect(grid.get(1, 1).hasJelly, isTrue);
      expect(grid.get(4, 4).hasJelly, isTrue);
    });

    test('rainbow + non-rainbow clears all of that color', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.rainbow,
          ),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.yellow),
          const Cell(row: 1, col: 1, jellyType: JellyType.green),
          const Cell(row: 1, col: 2, jellyType: JellyType.yellow),
        ],
      ]);

      SpecialEngine.activateSpecialCombo(
        grid,
        const Position(0, 0), // rainbow
        const Position(0, 1), // yellow
      );

      // Rainbow cell cleared
      expect(grid.get(0, 0).hasJelly, isFalse);
      // Non-rainbow cell (yellow at 0,1) cleared first
      expect(grid.get(0, 1).hasJelly, isFalse);
      // All yellow cells cleared
      expect(grid.get(1, 0).hasJelly, isFalse);
      expect(grid.get(1, 2).hasJelly, isFalse);
      // Non-yellow cells remain
      expect(grid.get(0, 2).hasJelly, isTrue); // blue
      expect(grid.get(1, 1).hasJelly, isTrue); // green
    });
  });
}
