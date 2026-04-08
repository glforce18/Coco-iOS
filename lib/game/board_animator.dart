import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'package:patpat_game/engine/match_engine.dart';
import 'package:patpat_game/models/position.dart';

/// Type of cell animation currently active.
enum AnimType {
  /// Cell is moving from one position to another (swap, fall).
  move,

  /// Cell is being destroyed (scale-to-zero + fade).
  destroy,

  /// New cell appearing from above the board.
  appear,
}

/// Describes an active animation on a single cell.
class CellAnimation {
  final AnimType type;
  final Offset offsetStart;
  final Offset offsetEnd;
  final int durationMs;
  final Curve curve;
  final DateTime startTime;

  CellAnimation({
    required this.type,
    this.offsetStart = Offset.zero,
    this.offsetEnd = Offset.zero,
    this.durationMs = 250,
    this.curve = Curves.easeOutCubic,
  }) : startTime = DateTime.now();

  /// Returns raw progress 0.0 .. 1.0 based on elapsed time.
  double get progress {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / durationMs).clamp(0.0, 1.0);
  }

  /// Returns curve-transformed progress.
  double get curvedProgress => curve.transform(progress);

  /// Current pixel offset for move/appear animations.
  Offset get currentOffset {
    if (type == AnimType.destroy) return Offset.zero;
    final t = curvedProgress;
    return Offset.lerp(offsetStart, offsetEnd, t)!;
  }

  /// Current scale for the cell (1.0 = normal, 0.0 = gone).
  double get currentScale {
    if (type == AnimType.destroy) {
      // Pop effect: scale up slightly then shrink to zero
      final t = curvedProgress;
      if (t < 0.15) {
        // Brief scale-up "pop"
        return 1.0 + (t / 0.15) * 0.15;
      }
      // Then shrink to zero
      final shrinkT = (t - 0.15) / 0.85;
      return (1.15 * (1.0 - shrinkT)).clamp(0.0, 1.15);
    }
    if (type == AnimType.appear) {
      // Scale from 0 to 1 during first 40% of animation
      final t = curvedProgress;
      if (t < 0.4) return (t / 0.4).clamp(0.0, 1.0);
      return 1.0;
    }
    return 1.0;
  }

  /// Current opacity for the cell.
  double get currentOpacity {
    if (type == AnimType.destroy) {
      final t = curvedProgress;
      // Fade out in the last 60% of the animation
      if (t < 0.4) return 1.0;
      return (1.0 - ((t - 0.4) / 0.6)).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  /// Whether this animation has completed.
  bool get isComplete => progress >= 1.0;
}

/// Manages per-cell animation state for the game board.
///
/// The [GameController] calls methods here to trigger animations
/// (swap, destroy, fall, appear). Each method returns a [Future] that
/// completes when the animation duration has elapsed.
///
/// The [GameBoard] reads animation state via [getAnimation] and uses
/// a [Ticker] to repaint at 60fps while animations are active.
class BoardAnimator extends ChangeNotifier {
  /// Active animations keyed by "row,col".
  final Map<String, CellAnimation> _animations = {};

  /// Whether any animations are currently running.
  bool get hasActiveAnimations => _animations.isNotEmpty;

  /// Get the current animation for a cell, or null if none.
  CellAnimation? getAnimation(int row, int col) => _animations['$row,$col'];

  // ──────────────────────────────────────────────────────────────────
  // Swap animation
  // ──────────────────────────────────────────────────────────────────

  /// Animate two cells swapping positions.
  ///
  /// Each cell gets an offset from its position toward the other cell.
  /// The animation runs for [durationMs] then clears.
  Future<void> animateSwap(
    Position from,
    Position to,
    double cellSize,
    double gap, {
    int durationMs = 200,
  }) async {
    final dx = (to.col - from.col) * (cellSize + gap);
    final dy = (to.row - from.row) * (cellSize + gap);

    _animations['${from.row},${from.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset.zero,
      offsetEnd: Offset(dx.toDouble(), dy.toDouble()),
      durationMs: durationMs,
      curve: Curves.easeInOutCubic,
    );
    _animations['${to.row},${to.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset.zero,
      offsetEnd: Offset(-dx.toDouble(), -dy.toDouble()),
      durationMs: durationMs,
      curve: Curves.easeInOutCubic,
    );
    notifyListeners();

    await Future<void>.delayed(Duration(milliseconds: durationMs));
    _animations.remove('${from.row},${from.col}');
    _animations.remove('${to.row},${to.col}');
    notifyListeners();
  }

  /// Animate an invalid swap: move to target, then bounce back.
  ///
  /// Total duration is roughly 2x [halfDurationMs].
  Future<void> animateInvalidSwap(
    Position from,
    Position to,
    double cellSize,
    double gap, {
    int halfDurationMs = 180,
  }) async {
    final dx = (to.col - from.col) * (cellSize + gap);
    final dy = (to.row - from.row) * (cellSize + gap);

    // Phase 1: slide toward target
    _animations['${from.row},${from.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset.zero,
      offsetEnd: Offset(dx.toDouble(), dy.toDouble()),
      durationMs: halfDurationMs,
      curve: Curves.easeOutCubic,
    );
    _animations['${to.row},${to.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset.zero,
      offsetEnd: Offset(-dx.toDouble(), -dy.toDouble()),
      durationMs: halfDurationMs,
      curve: Curves.easeOutCubic,
    );
    notifyListeners();
    await Future<void>.delayed(Duration(milliseconds: halfDurationMs));

    // Phase 2: slide back
    _animations['${from.row},${from.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset(dx.toDouble(), dy.toDouble()),
      offsetEnd: Offset.zero,
      durationMs: halfDurationMs,
      curve: Curves.easeInOutCubic,
    );
    _animations['${to.row},${to.col}'] = CellAnimation(
      type: AnimType.move,
      offsetStart: Offset(-dx.toDouble(), -dy.toDouble()),
      offsetEnd: Offset.zero,
      durationMs: halfDurationMs,
      curve: Curves.easeInOutCubic,
    );
    notifyListeners();
    await Future<void>.delayed(Duration(milliseconds: halfDurationMs));

    _animations.remove('${from.row},${from.col}');
    _animations.remove('${to.row},${to.col}');
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────
  // Destroy animation
  // ──────────────────────────────────────────────────────────────────

  /// Animate matched cells being destroyed (pop + fade out).
  Future<void> animateDestroy(List<Position> positions,
      {int durationMs = 200}) async {
    for (final p in positions) {
      _animations['${p.row},${p.col}'] = CellAnimation(
        type: AnimType.destroy,
        durationMs: durationMs,
        curve: Curves.easeInBack,
      );
    }
    notifyListeners();
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    for (final p in positions) {
      _animations.remove('${p.row},${p.col}');
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────
  // Fall animation
  // ──────────────────────────────────────────────────────────────────

  /// Animate jellies falling down to fill gaps.
  ///
  /// Each jelly starts at its old position (offset above the target)
  /// and animates down to its new position.
  Future<void> animateFall(
    List<FallMove> moves,
    double cellSize,
    double gap, {
    int durationMs = 250,
  }) async {
    if (moves.isEmpty) return;

    for (final move in moves) {
      // The jelly has already been moved in the grid to move.to.
      // We start it visually at move.from and animate to move.to.
      final dy = (move.from.row - move.to.row) * (cellSize + gap);
      final dx = (move.from.col - move.to.col) * (cellSize + gap);
      _animations['${move.to.row},${move.to.col}'] = CellAnimation(
        type: AnimType.move,
        offsetStart: Offset(dx.toDouble(), dy.toDouble()),
        offsetEnd: Offset.zero,
        durationMs: durationMs,
        curve: Curves.easeOutBack,
      );
    }
    notifyListeners();
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    for (final move in moves) {
      _animations.remove('${move.to.row},${move.to.col}');
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────
  // Appear / fill animation
  // ──────────────────────────────────────────────────────────────────

  /// Animate new jellies sliding in from above the board.
  Future<void> animateAppear(
    List<Position> positions,
    double cellSize,
    double gap, {
    int durationMs = 250,
  }) async {
    if (positions.isEmpty) return;

    for (final p in positions) {
      // Slide in from above: start offset = -(row+1) cells above
      final startDy = -(p.row + 1) * (cellSize + gap);
      _animations['${p.row},${p.col}'] = CellAnimation(
        type: AnimType.appear,
        offsetStart: Offset(0, startDy.toDouble()),
        offsetEnd: Offset.zero,
        durationMs: durationMs,
        curve: Curves.easeOutBack,
      );
    }
    notifyListeners();
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    for (final p in positions) {
      _animations.remove('${p.row},${p.col}');
    }
    notifyListeners();
  }

  /// Clear all active animations immediately.
  void clearAll() {
    _animations.clear();
    notifyListeners();
  }
}
