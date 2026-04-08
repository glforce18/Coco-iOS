import 'package:patpat_game/engine/match_engine.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';

/// Provides hint and deadlock detection for the game grid.
class HintEngine {
  HintEngine._();

  // ──────────────────────────────────────────────
  // 1. findHint
  // ──────────────────────────────────────────────

  /// Iterates all positions, checks right and down neighbors.
  /// Returns the first valid swap pair, or null if no valid move exists.
  static (Position, Position)? findHint(GameGrid grid) {
    for (int r = 0; r < grid.rows; r++) {
      for (int c = 0; c < grid.cols; c++) {
        final pos = Position(r, c);

        // Check right neighbor
        if (c + 1 < grid.cols) {
          final right = Position(r, c + 1);
          if (MatchEngine.isValidSwap(grid, pos, right)) {
            return (pos, right);
          }
        }

        // Check down neighbor
        if (r + 1 < grid.rows) {
          final down = Position(r + 1, c);
          if (MatchEngine.isValidSwap(grid, pos, down)) {
            return (pos, down);
          }
        }
      }
    }

    return null;
  }

  // ──────────────────────────────────────────────
  // 2. hasValidMoves
  // ──────────────────────────────────────────────

  /// Returns true if at least one valid swap exists on the grid.
  static bool hasValidMoves(GameGrid grid) {
    return findHint(grid) != null;
  }
}
