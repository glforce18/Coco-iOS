import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/engine/hint_engine.dart';

/// Helper to build a grid from a 2D list of [JellyType?].
GameGrid _gridFrom(List<List<JellyType?>> data) {
  final rows = data.length;
  final cols = data[0].length;
  final cells = List.generate(
    rows,
    (r) => List.generate(
      cols,
      (c) => Cell(row: r, col: c, jellyType: data[r][c]),
    ),
  );
  return GameGrid.fromData(cells);
}

void main() {
  const p = JellyType.purple;
  const y = JellyType.yellow;
  const b = JellyType.blue;
  const g = JellyType.green;

  // ────────────────────────────────────────────
  // findHint
  // ────────────────────────────────────────────

  group('findHint', () {
    test('finds valid hint when swap exists', () {
      //  y p p
      //  p b g
      // Swapping (0,0)<->(1,0) puts purple at (0,0) -> p p p
      final grid = _gridFrom([
        [y, p, p],
        [p, b, g],
      ]);

      final hint = HintEngine.findHint(grid);
      expect(hint, isNotNull);

      final (pos1, pos2) = hint!;
      // The hint should be a valid swap that produces a match
      // (0,0) down to (1,0) or some other valid pair
      expect(pos1.isAdjacentTo(pos2), isTrue);
    });

    test('returns null for board with no valid moves', () {
      // 2x2 grid with 4 different colors — no 3-match possible
      final grid = _gridFrom([
        [p, y],
        [b, g],
      ]);

      final hint = HintEngine.findHint(grid);
      expect(hint, isNull);
    });

    test('finds hint checking right neighbor', () {
      //  p b p p
      // Swapping (0,0)<->(0,1) gives b p p p — match at positions 1-3
      // Actually checking: swap (0,1)<->(0,0) → p p p ... at col 0-2 nope
      // Better: p y p p → swap(0,0)<->(0,1) gives y p p p → match at 1-3?
      // No, let's use a clear example:
      //  b p p
      //  y g b
      // swap (0,0) right with (0,1) → p b p no match
      // Better:
      //  p b p
      //  p y g
      // swap(0,1) down with (1,1) → p y p / p b g → no
      // Let's just test a simple case:
      //  y p p
      //  b g b
      // swap (0,0) right → p y p no.
      // swap (0,0) down → b p p / y g b → no match
      // A clear example: right swap creates match
      //  p p y p
      // swap (0,2) right with (0,3) → p p p y → match at 0,1,2
      final grid = _gridFrom([
        [p, p, y, p],
        [b, g, b, y],
      ]);

      final hint = HintEngine.findHint(grid);
      expect(hint, isNotNull);
      final (pos1, pos2) = hint!;
      // Should find swap at (0,2) and (0,3)
      expect(pos1, const Position(0, 2));
      expect(pos2, const Position(0, 3));
    });
  });

  // ────────────────────────────────────────────
  // hasValidMoves
  // ────────────────────────────────────────────

  group('hasValidMoves', () {
    test('returns true when valid move exists', () {
      final grid = _gridFrom([
        [y, p, p],
        [p, b, g],
      ]);

      expect(HintEngine.hasValidMoves(grid), isTrue);
    });

    test('returns false for dead board (2x2 with 4 different colors)', () {
      final grid = _gridFrom([
        [p, y],
        [b, g],
      ]);

      expect(HintEngine.hasValidMoves(grid), isFalse);
    });
  });
}
