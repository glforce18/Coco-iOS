import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/engine/obstacle_engine.dart';

void main() {
  // ────────────────────────────────────────────
  // spreadChocolate
  // ────────────────────────────────────────────

  group('spreadChocolate', () {
    test('chocolate spreads to adjacent cell with jelly', () {
      // Chocolate at (1,1), jelly neighbors around it
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
          const Cell(row: 0, col: 2, jellyType: JellyType.blue),
        ],
        [
          const Cell(row: 1, col: 0, jellyType: JellyType.green),
          const Cell(row: 1, col: 1, obstacle: ObstacleType.chocolate),
          const Cell(row: 1, col: 2, jellyType: JellyType.pink),
        ],
        [
          const Cell(row: 2, col: 0, jellyType: JellyType.orange),
          const Cell(row: 2, col: 1, jellyType: JellyType.purple),
          const Cell(row: 2, col: 2, jellyType: JellyType.yellow),
        ],
      ]);

      final spread = ObstacleEngine.spreadChocolate(grid);
      expect(spread, isTrue);

      // Count chocolate cells — should be 2 now
      int chocolateCount = 0;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          if (grid.get(r, c).obstacle == ObstacleType.chocolate) {
            chocolateCount++;
          }
        }
      }
      expect(chocolateCount, 2);
    });

    test('no spread if no adjacent jellies', () {
      // Chocolate surrounded by empty cells
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0),
          const Cell(row: 0, col: 1),
          const Cell(row: 0, col: 2),
        ],
        [
          const Cell(row: 1, col: 0),
          const Cell(row: 1, col: 1, obstacle: ObstacleType.chocolate),
          const Cell(row: 1, col: 2),
        ],
        [
          const Cell(row: 2, col: 0),
          const Cell(row: 2, col: 1),
          const Cell(row: 2, col: 2),
        ],
      ]);

      final spread = ObstacleEngine.spreadChocolate(grid);
      expect(spread, isFalse);
    });

    test('no spread if no chocolate cells', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      final spread = ObstacleEngine.spreadChocolate(grid);
      expect(spread, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // damageAdjacentChains
  // ────────────────────────────────────────────

  group('damageAdjacentChains', () {
    test('chain2 degrades to chain1', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            obstacle: ObstacleType.chain2,
          ),
        ],
      ]);

      final damaged = ObstacleEngine.damageAdjacentChains(
        grid,
        [const Position(0, 0)],
      );

      expect(damaged, isTrue);
      expect(grid.get(0, 1).obstacle, ObstacleType.chain1);
      expect(grid.get(0, 1).hasJelly, isTrue); // jelly stays
    });

    test('chain1 degrades to none', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(
            row: 0,
            col: 1,
            jellyType: JellyType.yellow,
            obstacle: ObstacleType.chain1,
          ),
        ],
      ]);

      final damaged = ObstacleEngine.damageAdjacentChains(
        grid,
        [const Position(0, 0)],
      );

      expect(damaged, isTrue);
      expect(grid.get(0, 1).obstacle, ObstacleType.none);
      expect(grid.get(0, 1).hasJelly, isTrue); // jelly stays
    });

    test('returns false when no chains adjacent', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      final damaged = ObstacleEngine.damageAdjacentChains(
        grid,
        [const Position(0, 0)],
      );

      expect(damaged, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // checkBoxes
  // ────────────────────────────────────────────

  group('checkBoxes', () {
    test('box destroyed by adjacent explosion', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, obstacle: ObstacleType.box),
        ],
      ]);

      final destroyed = ObstacleEngine.checkBoxes(
        grid,
        [const Position(0, 0)],
      );

      expect(destroyed, isTrue);
      expect(grid.get(0, 1).obstacle, ObstacleType.none);
      expect(grid.get(0, 1).hasJelly, isFalse);
    });

    test('returns false when no boxes adjacent', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      final destroyed = ObstacleEngine.checkBoxes(
        grid,
        [const Position(0, 0)],
      );

      expect(destroyed, isFalse);
    });

    test('multiple boxes destroyed at once', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0),
          const Cell(row: 0, col: 1, obstacle: ObstacleType.box),
          const Cell(row: 0, col: 2),
        ],
        [
          const Cell(row: 1, col: 0, obstacle: ObstacleType.box),
          const Cell(row: 1, col: 1, jellyType: JellyType.purple),
          const Cell(row: 1, col: 2, obstacle: ObstacleType.box),
        ],
        [
          const Cell(row: 2, col: 0),
          const Cell(row: 2, col: 1, obstacle: ObstacleType.box),
          const Cell(row: 2, col: 2),
        ],
      ]);

      final destroyed = ObstacleEngine.checkBoxes(
        grid,
        [const Position(1, 1)],
      );

      expect(destroyed, isTrue);
      expect(grid.get(0, 1).obstacle, ObstacleType.none);
      expect(grid.get(1, 0).obstacle, ObstacleType.none);
      expect(grid.get(1, 2).obstacle, ObstacleType.none);
      expect(grid.get(2, 1).obstacle, ObstacleType.none);
    });
  });

  // ────────────────────────────────────────────
  // damageAdjacentChocolates
  // ────────────────────────────────────────────

  group('damageAdjacentChocolates', () {
    test('chocolate cleared by adjacent explosion', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, obstacle: ObstacleType.chocolate),
        ],
      ]);

      final damaged = ObstacleEngine.damageAdjacentChocolates(
        grid,
        [const Position(0, 0)],
      );

      expect(damaged, isTrue);
      expect(grid.get(0, 1).obstacle, ObstacleType.none);
    });

    test('returns false when no chocolate adjacent', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      final damaged = ObstacleEngine.damageAdjacentChocolates(
        grid,
        [const Position(0, 0)],
      );

      expect(damaged, isFalse);
    });
  });
}
