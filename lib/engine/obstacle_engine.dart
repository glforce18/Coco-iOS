import 'dart:math';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';

/// Handles obstacle-specific mechanics: chocolate spread, chain damage,
/// box destruction, and chocolate damage from adjacent explosions.
class ObstacleEngine {
  ObstacleEngine._();

  static final _rng = Random();

  static const _dirs = [
    Position(-1, 0),
    Position(1, 0),
    Position(0, -1),
    Position(0, 1),
  ];

  // ──────────────────────────────────────────────
  // 1. spreadChocolate
  // ──────────────────────────────────────────────

  /// Finds all chocolate cells, picks one at random, and spreads to one
  /// random adjacent cell that has a jelly (converting it to chocolate).
  ///
  /// Returns true if a spread occurred.
  static bool spreadChocolate(GameGrid grid) {
    // Collect all chocolate positions
    final chocolates = <Position>[];
    for (int r = 0; r < grid.rows; r++) {
      for (int c = 0; c < grid.cols; c++) {
        if (grid.get(r, c).obstacle == ObstacleType.chocolate) {
          chocolates.add(Position(r, c));
        }
      }
    }

    if (chocolates.isEmpty) return false;

    // Shuffle and try each chocolate cell
    chocolates.shuffle(_rng);
    for (final chocPos in chocolates) {
      final neighbors = <Position>[];
      for (final dir in _dirs) {
        final np = chocPos + dir;
        if (!np.isValid(grid.rows, grid.cols)) continue;
        final neighbor = grid.get(np.row, np.col);
        if (neighbor.hasJelly &&
            neighbor.obstacle != ObstacleType.chocolate &&
            !neighbor.isIceWall) {
          neighbors.add(np);
        }
      }

      if (neighbors.isNotEmpty) {
        final target = neighbors[_rng.nextInt(neighbors.length)];
        final cell = grid.get(target.row, target.col);
        grid.set(
          target.row,
          target.col,
          cell.copyWith(clearJelly: true, obstacle: ObstacleType.chocolate),
        );
        grid.bumpVersion();
        return true;
      }
    }

    return false;
  }

  // ──────────────────────────────────────────────
  // 2. damageAdjacentChains
  // ──────────────────────────────────────────────

  /// For each explosion position, check 4 neighbors for chains.
  /// chain2 -> chain1, chain1 -> none.
  ///
  /// Returns true if any chain was damaged.
  static bool damageAdjacentChains(
    GameGrid grid,
    List<Position> explosionPositions,
  ) {
    bool changed = false;

    for (final pos in explosionPositions) {
      for (final dir in _dirs) {
        final np = pos + dir;
        if (!np.isValid(grid.rows, grid.cols)) continue;
        final cell = grid.get(np.row, np.col);

        if (cell.obstacle == ObstacleType.chain2) {
          grid.set(np.row, np.col, cell.copyWith(obstacle: ObstacleType.chain1));
          changed = true;
        } else if (cell.obstacle == ObstacleType.chain1) {
          grid.set(np.row, np.col, cell.copyWith(obstacle: ObstacleType.none));
          changed = true;
        }
      }
    }

    if (changed) grid.bumpVersion();
    return changed;
  }

  // ──────────────────────────────────────────────
  // 3. checkBoxes
  // ──────────────────────────────────────────────

  /// For each explosion position, check 4 neighbors for boxes.
  /// If a box is found, clear it.
  ///
  /// Returns true if any box was destroyed.
  static bool checkBoxes(
    GameGrid grid,
    List<Position> explosionPositions,
  ) {
    bool changed = false;

    for (final pos in explosionPositions) {
      for (final dir in _dirs) {
        final np = pos + dir;
        if (!np.isValid(grid.rows, grid.cols)) continue;
        final cell = grid.get(np.row, np.col);

        if (cell.obstacle == ObstacleType.box) {
          grid.set(
            np.row,
            np.col,
            cell.copyWith(clearJelly: true, obstacle: ObstacleType.none),
          );
          changed = true;
        }
      }
    }

    if (changed) grid.bumpVersion();
    return changed;
  }

  // ──────────────────────────────────────────────
  // 4. damageAdjacentChocolates
  // ──────────────────────────────────────────────

  /// For each explosion position, check 4 neighbors for chocolate.
  /// Clear any chocolate found.
  ///
  /// Returns true if any chocolate was destroyed.
  static bool damageAdjacentChocolates(
    GameGrid grid,
    List<Position> explosionPositions,
  ) {
    bool changed = false;

    for (final pos in explosionPositions) {
      for (final dir in _dirs) {
        final np = pos + dir;
        if (!np.isValid(grid.rows, grid.cols)) continue;
        final cell = grid.get(np.row, np.col);

        if (cell.obstacle == ObstacleType.chocolate) {
          grid.set(
            np.row,
            np.col,
            cell.copyWith(clearJelly: true, obstacle: ObstacleType.none),
          );
          changed = true;
        }
      }
    }

    if (changed) grid.bumpVersion();
    return changed;
  }
}
