import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/engine/match_engine.dart';

/// Helper to build a grid from a 2D list of [JellyType?].
/// `null` means empty cell.
GameGrid _gridFrom(List<List<JellyType?>> data) {
  final rows = data.length;
  final cols = data[0].length;
  final cells = List.generate(
    rows,
    (r) => List.generate(
      cols,
      (c) => Cell(
        row: r,
        col: c,
        jellyType: data[r][c],
      ),
    ),
  );
  return GameGrid.fromData(cells);
}

/// Helper to build a grid with obstacle support.
GameGrid _gridWithObstacles(
  List<List<JellyType?>> data,
  Map<Position, ObstacleType> obstacles,
) {
  final grid = _gridFrom(data);
  for (final entry in obstacles.entries) {
    final pos = entry.key;
    final cell = grid.get(pos.row, pos.col);
    grid.set(pos.row, pos.col, cell.copyWith(obstacle: entry.value));
  }
  return grid;
}

void main() {
  const p = JellyType.purple;
  const y = JellyType.yellow;
  const b = JellyType.blue;
  const g = JellyType.green;
  const k = JellyType.pink;
  const o = JellyType.orange;

  // ────────────────────────────────────────────
  // findMatches
  // ────────────────────────────────────────────

  group('findMatches', () {
    test('finds horizontal 3-match', () {
      final grid = _gridFrom([
        [p, p, p, y, b],
        [y, b, g, k, o],
        [b, g, k, o, y],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, hasLength(1));
      expect(matches[0].jellyType, p);
      expect(matches[0].direction, MatchDirection.horizontal);
      expect(matches[0].shape, MatchShape.line3);
      expect(matches[0].positions, hasLength(3));
    });

    test('finds vertical 3-match', () {
      final grid = _gridFrom([
        [p, y, b],
        [p, b, g],
        [p, g, k],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, hasLength(1));
      expect(matches[0].jellyType, p);
      expect(matches[0].direction, MatchDirection.vertical);
      expect(matches[0].shape, MatchShape.line3);
      expect(matches[0].positions, hasLength(3));
    });

    test('finds 4-match (line4 shape)', () {
      final grid = _gridFrom([
        [p, p, p, p, b],
        [y, b, g, k, o],
        [b, g, k, o, y],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, hasLength(1));
      expect(matches[0].shape, MatchShape.line4);
      expect(matches[0].positions, hasLength(4));
    });

    test('finds 5-match (line5 shape)', () {
      final grid = _gridFrom([
        [p, p, p, p, p],
        [y, b, g, k, o],
        [b, g, k, o, y],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, hasLength(1));
      expect(matches[0].shape, MatchShape.line5);
      expect(matches[0].positions, hasLength(5));
    });

    test('chained cells do not match', () {
      final grid = _gridWithObstacles(
        [
          [p, p, p],
          [y, b, g],
          [b, g, k],
        ],
        {const Position(0, 1): ObstacleType.chain1},
      );

      final matches = MatchEngine.findMatches(grid.snapshot());
      // The chain at (0,1) breaks the horizontal run
      expect(matches, isEmpty);
    });

    test('no match with only 2 in a row', () {
      final grid = _gridFrom([
        [p, p, y, b, g],
        [y, b, g, k, o],
        [b, g, k, o, y],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, isEmpty);
    });

    test('finds multiple matches simultaneously', () {
      final grid = _gridFrom([
        [p, p, p, y, y],
        [b, b, g, k, o],
        [b, b, b, o, y],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      // Row 0: purple horizontal 3-match
      // Row 2: blue horizontal 3-match
      expect(matches, hasLength(2));
    });

    test('detects T-shape when H and V intersect', () {
      //   p p p
      //   y p y
      //   b p b
      final grid = _gridFrom([
        [p, p, p],
        [y, p, y],
        [b, p, b],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      // Should merge into one T/L shape
      expect(matches, hasLength(1));
      expect(
        matches[0].shape,
        anyOf(MatchShape.tShape, MatchShape.lShape),
      );
      expect(matches[0].positions, hasLength(5));
    });

    test('detects L-shape (6+ cells)', () {
      //   p p p p
      //   y p y b
      //   b p b g
      final grid = _gridFrom([
        [p, p, p, p],
        [y, p, y, b],
        [b, p, b, g],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, hasLength(1));
      expect(matches[0].shape, MatchShape.lShape);
      // 4 horizontal + 3 vertical - 1 shared = 6
      expect(matches[0].positions, hasLength(6));
    });
  });

  // ────────────────────────────────────────────
  // determineSpecialType
  // ────────────────────────────────────────────

  group('determineSpecialType', () {
    test('line3 → none', () {
      final match = Match(
        positions: [
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        ],
        jellyType: p,
        direction: MatchDirection.horizontal,
        shape: MatchShape.line3,
      );
      expect(MatchEngine.determineSpecialType(match), SpecialType.none);
    });

    test('horizontal line4 → rocketVertical', () {
      final match = Match(
        positions: List.generate(4, (i) => Position(0, i)),
        jellyType: p,
        direction: MatchDirection.horizontal,
        shape: MatchShape.line4,
      );
      expect(
        MatchEngine.determineSpecialType(match),
        SpecialType.rocketVertical,
      );
    });

    test('vertical line4 → rocketHorizontal', () {
      final match = Match(
        positions: List.generate(4, (i) => Position(i, 0)),
        jellyType: p,
        direction: MatchDirection.vertical,
        shape: MatchShape.line4,
      );
      expect(
        MatchEngine.determineSpecialType(match),
        SpecialType.rocketHorizontal,
      );
    });

    test('line5 → rainbow', () {
      final match = Match(
        positions: List.generate(5, (i) => Position(0, i)),
        jellyType: p,
        direction: MatchDirection.horizontal,
        shape: MatchShape.line5,
      );
      expect(MatchEngine.determineSpecialType(match), SpecialType.rainbow);
    });

    test('tShape with <6 pieces → bomb', () {
      final match = Match(
        positions: List.generate(5, (i) => Position(0, i)),
        jellyType: p,
        direction: MatchDirection.horizontal,
        shape: MatchShape.tShape,
      );
      expect(MatchEngine.determineSpecialType(match), SpecialType.bomb);
    });

    test('lShape with >=6 pieces → lightning', () {
      final match = Match(
        positions: List.generate(6, (i) => Position(0, i)),
        jellyType: p,
        direction: MatchDirection.horizontal,
        shape: MatchShape.lShape,
      );
      expect(MatchEngine.determineSpecialType(match), SpecialType.lightning);
    });
  });

  // ────────────────────────────────────────────
  // applyGravity
  // ────────────────────────────────────────────

  group('applyGravity', () {
    test('jelly falls to empty cell below', () {
      // Row 0: purple, Row 1: empty, Row 2: empty
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
        ],
        [
          const Cell(row: 1, col: 0),
        ],
        [
          const Cell(row: 2, col: 0),
        ],
      ]);

      final moves = MatchEngine.applyGravity(grid);
      expect(moves, hasLength(1));
      expect(moves[0].from, const Position(0, 0));
      expect(moves[0].to, const Position(2, 0));

      // Cell at (2,0) should now have purple
      expect(grid.get(2, 0).jellyType, JellyType.purple);
      // Cell at (0,0) should be empty
      expect(grid.get(0, 0).hasJelly, isFalse);
    });

    test('iceWall blocks gravity', () {
      // Row 0: purple, Row 1: iceWall, Row 2: empty
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
        ],
        [
          const Cell(row: 1, col: 0, obstacle: ObstacleType.iceWall),
        ],
        [
          const Cell(row: 2, col: 0),
        ],
      ]);

      final moves = MatchEngine.applyGravity(grid);
      // Purple is in segment [0,0] (above iceWall) — no empty below
      // within its segment, so it doesn't move.
      expect(moves, isEmpty);
      expect(grid.get(0, 0).jellyType, JellyType.purple);
    });

    test('multiple jellies fall in sequence', () {
      final grid = GameGrid.fromData([
        [const Cell(row: 0, col: 0, jellyType: JellyType.purple)],
        [const Cell(row: 1, col: 0, jellyType: JellyType.yellow)],
        [const Cell(row: 2, col: 0)],
        [const Cell(row: 3, col: 0)],
      ]);

      final moves = MatchEngine.applyGravity(grid);
      expect(moves, hasLength(2));
      // Yellow should be at row 3, purple at row 2
      expect(grid.get(3, 0).jellyType, JellyType.yellow);
      expect(grid.get(2, 0).jellyType, JellyType.purple);
      expect(grid.get(0, 0).hasJelly, isFalse);
      expect(grid.get(1, 0).hasJelly, isFalse);
    });

    test('chained cells do not move', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            obstacle: ObstacleType.chain1,
          ),
        ],
        [const Cell(row: 1, col: 0)],
        [const Cell(row: 2, col: 0)],
      ]);

      final moves = MatchEngine.applyGravity(grid);
      expect(moves, isEmpty);
      expect(grid.get(0, 0).jellyType, JellyType.purple);
    });
  });

  // ────────────────────────────────────────────
  // fillEmpty
  // ────────────────────────────────────────────

  group('fillEmpty', () {
    test('fills empty cells with random jellies', () {
      final grid = GameGrid(rows: 3, cols: 3); // all empty
      final available = JellyType.values.toList();

      final filled = MatchEngine.fillEmpty(grid, available);
      expect(filled, hasLength(9));

      // Every cell should now have a jelly
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(grid.get(r, c).hasJelly, isTrue);
        }
      }
    });

    test('does not fill cells that already have jellies', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, jellyType: JellyType.purple),
          const Cell(row: 0, col: 1),
        ],
      ]);
      final available = JellyType.values.toList();

      final filled = MatchEngine.fillEmpty(grid, available);
      expect(filled, hasLength(1));
      expect(filled[0], const Position(0, 1));
      expect(grid.get(0, 0).jellyType, JellyType.purple); // unchanged
    });

    test('does not fill cells with obstacles', () {
      final grid = GameGrid.fromData([
        [
          const Cell(row: 0, col: 0, obstacle: ObstacleType.iceWall),
          const Cell(row: 0, col: 1),
        ],
      ]);
      final available = JellyType.values.toList();

      final filled = MatchEngine.fillEmpty(grid, available);
      // (0,0) has obstacle → not empty → not filled
      expect(filled, hasLength(1));
      expect(filled[0], const Position(0, 1));
    });
  });

  // ────────────────────────────────────────────
  // swap
  // ────────────────────────────────────────────

  group('swap', () {
    test('swaps jelly types between two cells', () {
      final grid = _gridFrom([
        [p, y],
      ]);

      MatchEngine.swap(grid, const Position(0, 0), const Position(0, 1));

      expect(grid.get(0, 0).jellyType, y);
      expect(grid.get(0, 1).jellyType, p);
    });

    test('swaps special types along with jelly types', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            specialType: SpecialType.bomb,
          ),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      MatchEngine.swap(grid, const Position(0, 0), const Position(0, 1));

      expect(grid.get(0, 0).jellyType, JellyType.yellow);
      expect(grid.get(0, 0).specialType, SpecialType.none);
      expect(grid.get(0, 1).jellyType, JellyType.purple);
      expect(grid.get(0, 1).specialType, SpecialType.bomb);
    });

    test('obstacles stay at their positions after swap', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            obstacle: ObstacleType.ice1,
          ),
          const Cell(row: 0, col: 1, jellyType: JellyType.yellow),
        ],
      ]);

      MatchEngine.swap(grid, const Position(0, 0), const Position(0, 1));

      // Obstacle stays on cell (0,0)
      expect(grid.get(0, 0).obstacle, ObstacleType.ice1);
      expect(grid.get(0, 1).obstacle, ObstacleType.none);
    });
  });

  // ────────────────────────────────────────────
  // isValidSwap
  // ────────────────────────────────────────────

  group('isValidSwap', () {
    test('valid swap creates match', () {
      //  y p p
      //  p b g
      // Swapping (0,0) with (1,0) puts purple at (0,0) → p p p
      final grid = _gridFrom([
        [y, p, p],
        [p, b, g],
      ]);

      final valid = MatchEngine.isValidSwap(
        grid,
        const Position(0, 0),
        const Position(1, 0),
      );
      expect(valid, isTrue);

      // Grid should be restored to original
      expect(grid.get(0, 0).jellyType, y);
      expect(grid.get(1, 0).jellyType, p);
    });

    test('invalid swap creates no match', () {
      final grid = _gridFrom([
        [p, y, b],
        [g, k, o],
      ]);

      final valid = MatchEngine.isValidSwap(
        grid,
        const Position(0, 0),
        const Position(0, 1),
      );
      expect(valid, isFalse);
    });

    test('rejects swap when cell is chained', () {
      final grid = _gridWithObstacles(
        [
          [p, p, y],
          [p, b, g],
        ],
        {const Position(0, 0): ObstacleType.chain1},
      );

      final valid = MatchEngine.isValidSwap(
        grid,
        const Position(0, 0),
        const Position(1, 0),
      );
      expect(valid, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // removeMatches
  // ────────────────────────────────────────────

  group('removeMatches', () {
    test('clears matched cells', () {
      final grid = _gridFrom([
        [p, p, p],
        [y, b, g],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      MatchEngine.removeMatches(grid, matches);

      // Top row should be cleared
      expect(grid.get(0, 0).hasJelly, isFalse);
      expect(grid.get(0, 1).hasJelly, isFalse);
      expect(grid.get(0, 2).hasJelly, isFalse);
      // Bottom row untouched
      expect(grid.get(1, 0).jellyType, y);
    });

    test('line4 match spawns special at first position', () {
      final grid = _gridFrom([
        [p, p, p, p, y],
        [y, b, g, k, o],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      MatchEngine.removeMatches(grid, matches);

      // First position should have special
      expect(grid.get(0, 0).hasJelly, isTrue);
      expect(grid.get(0, 0).specialType, SpecialType.rocketVertical);
      // Others should be cleared
      expect(grid.get(0, 1).hasJelly, isFalse);
    });

    test('spawns special at swapPosition when provided', () {
      final grid = _gridFrom([
        [p, p, p, p, y],
        [y, b, g, k, o],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      final swapPos = const Position(0, 2);
      MatchEngine.removeMatches(grid, matches, swapPos);

      // swapPosition (0,2) should have the special
      expect(grid.get(0, 2).hasJelly, isTrue);
      expect(grid.get(0, 2).specialType, SpecialType.rocketVertical);
      // Others cleared
      expect(grid.get(0, 0).hasJelly, isFalse);
      expect(grid.get(0, 1).hasJelly, isFalse);
      expect(grid.get(0, 3).hasJelly, isFalse);
    });

    test('ice2 downgrades to ice1, jelly stays', () {
      final grid = GameGrid.fromData([
        [
          const Cell(
            row: 0,
            col: 0,
            jellyType: JellyType.purple,
            obstacle: ObstacleType.ice2,
          ),
          const Cell(row: 0, col: 1, jellyType: JellyType.purple),
          const Cell(row: 0, col: 2, jellyType: JellyType.purple),
        ],
      ]);

      final matches = MatchEngine.findMatches(grid.snapshot());
      MatchEngine.removeMatches(grid, matches);

      // (0,0): ice2 → ice1, jelly stays
      expect(grid.get(0, 0).obstacle, ObstacleType.ice1);
      expect(grid.get(0, 0).hasJelly, isTrue);
    });
  });

  // ────────────────────────────────────────────
  // ensureNoInitialMatches
  // ────────────────────────────────────────────

  group('ensureNoInitialMatches', () {
    test('removes all matches from grid', () {
      final grid = _gridFrom([
        [p, p, p],
        [y, y, y],
        [b, b, b],
      ]);

      MatchEngine.ensureNoInitialMatches(grid, JellyType.values.toList());

      final matches = MatchEngine.findMatches(grid.snapshot());
      expect(matches, isEmpty);
    });

    test('preserves non-matching cells', () {
      final grid = _gridFrom([
        [p, y, b],
        [g, k, o],
        [p, y, b],
      ]);

      MatchEngine.ensureNoInitialMatches(grid, JellyType.values.toList());

      // Grid had no matches, so it should be unchanged
      expect(grid.get(0, 0).jellyType, p);
      expect(grid.get(1, 1).jellyType, k);
    });
  });
}
