import 'dart:math';

import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/utils/extensions.dart';

/// Interactive game board rendered via [CustomPainter].
///
/// Handles tap and swipe gestures, then delegates rendering of cells,
/// jellies, specials, obstacles, selection highlight, and hint highlight
/// to [_BoardPainter].
class GameBoard extends StatefulWidget {
  final GameGrid grid;
  final Position? selectedCell;
  final (Position, Position)? hintPositions;
  final ActiveBoosterMode boosterMode;
  final Function(Position) onCellTapped;
  final Function(Position, SwapDirection) onSwipe;

  const GameBoard({
    super.key,
    required this.grid,
    this.selectedCell,
    this.hintPositions,
    this.boosterMode = ActiveBoosterMode.none,
    required this.onCellTapped,
    required this.onSwipe,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  Offset? _panStart;
  Position? _panStartCell;
  bool _swipeHandled = false;

  static const double _gap = 2.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Compute cell size to fit the grid in the given [constraints].
  double _cellSize(BoxConstraints constraints) {
    final maxW =
        (constraints.maxWidth - _gap * (widget.grid.cols - 1)) /
        widget.grid.cols;
    final maxH =
        (constraints.maxHeight - _gap * (widget.grid.rows - 1)) /
        widget.grid.rows;
    return min(maxW, maxH).clamp(30.0, 52.0);
  }

  /// Board total width/height.
  double _boardWidth(double cellSize) =>
      cellSize * widget.grid.cols + _gap * (widget.grid.cols - 1);

  double _boardHeight(double cellSize) =>
      cellSize * widget.grid.rows + _gap * (widget.grid.rows - 1);

  /// Hit-test: find the cell under [local] coordinates given [cellSize]
  /// and the board offset.
  Position? _hitTest(Offset local, double cellSize, Offset boardOffset) {
    final dx = local.dx - boardOffset.dx;
    final dy = local.dy - boardOffset.dy;
    if (dx < 0 || dy < 0) return null;

    final col = (dx / (cellSize + _gap)).floor();
    final row = (dy / (cellSize + _gap)).floor();
    if (col < 0 ||
        col >= widget.grid.cols ||
        row < 0 ||
        row >= widget.grid.rows) {
      return null;
    }
    return Position(row, col);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = _cellSize(constraints);
        final bw = _boardWidth(cellSize);
        final bh = _boardHeight(cellSize);
        final boardOffset = Offset(
          (constraints.maxWidth - bw) / 2,
          (constraints.maxHeight - bh) / 2,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _panStart = details.localPosition;
            _panStartCell = _hitTest(
              details.localPosition,
              cellSize,
              boardOffset,
            );
            _swipeHandled = false;
          },
          onPanUpdate: (details) {
            if (_swipeHandled || _panStart == null || _panStartCell == null) {
              return;
            }
            final delta = details.localPosition - _panStart!;
            final threshold = cellSize * 0.3;
            if (delta.distance < threshold) return;

            SwapDirection dir;
            if (delta.dx.abs() > delta.dy.abs()) {
              dir = delta.dx > 0 ? SwapDirection.right : SwapDirection.left;
            } else {
              dir = delta.dy > 0 ? SwapDirection.down : SwapDirection.up;
            }

            _swipeHandled = true;
            widget.onSwipe(_panStartCell!, dir);
          },
          onPanEnd: (_) {
            if (!_swipeHandled && _panStartCell != null) {
              widget.onCellTapped(_panStartCell!);
            }
            _panStart = null;
            _panStartCell = null;
          },
          child: ListenableBuilder(
            listenable: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _BoardPainter(
                  grid: widget.grid,
                  cellSize: cellSize,
                  gap: _gap,
                  boardOffset: boardOffset,
                  selectedCell: widget.selectedCell,
                  hintPositions: widget.hintPositions,
                  boosterMode: widget.boosterMode,
                  pulseValue: _pulseController.value,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BoardPainter
// ─────────────────────────────────────────────────────────────────────────────

class _BoardPainter extends CustomPainter {
  final GameGrid grid;
  final double cellSize;
  final double gap;
  final Offset boardOffset;
  final Position? selectedCell;
  final (Position, Position)? hintPositions;
  final ActiveBoosterMode boosterMode;
  final double pulseValue; // 0..1

  _BoardPainter({
    required this.grid,
    required this.cellSize,
    required this.gap,
    required this.boardOffset,
    this.selectedCell,
    this.hintPositions,
    this.boosterMode = ActiveBoosterMode.none,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < grid.rows; r++) {
      for (int c = 0; c < grid.cols; c++) {
        final cell = grid.get(r, c);
        final rect = _cellRect(r, c);

        // 1. Background
        _drawBackground(canvas, rect);

        // 2. Obstacle overlay (drawn behind jelly for ice-style overlays)
        if (cell.obstacle != ObstacleType.none) {
          _drawObstacle(canvas, rect, cell.obstacle);
        }

        // 3. Jelly
        if (cell.hasJelly) {
          _drawJelly(canvas, rect, cell.jellyType!);
        }

        // 4. Special indicator
        if (cell.specialType != SpecialType.none) {
          _drawSpecial(canvas, rect, cell.specialType);
        }

        // 5. Selection highlight
        if (selectedCell != null &&
            selectedCell!.row == r &&
            selectedCell!.col == c) {
          _drawSelection(canvas, rect);
        }

        // 6. Hint highlight
        if (hintPositions != null) {
          final (h1, h2) = hintPositions!;
          if ((h1.row == r && h1.col == c) ||
              (h2.row == r && h2.col == c)) {
            _drawHint(canvas, rect);
          }
        }
      }
    }
  }

  Rect _cellRect(int row, int col) {
    final x = boardOffset.dx + col * (cellSize + gap);
    final y = boardOffset.dy + row * (cellSize + gap);
    return Rect.fromLTWH(x, y, cellSize, cellSize);
  }

  // ── Background ──────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF1A0550)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
  }

  // ── Jelly ───────────────────────────────────────────────────────────────

  void _drawJelly(Canvas canvas, Rect rect, JellyType type) {
    final inset = rect.deflate(cellSize * 0.08);
    final radius = inset.width / 2;
    final center = inset.center;

    // Radial gradient body
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.35),
      radius: 0.9,
      colors: [type.lightColor, type.color, type.darkColor],
      stops: const [0.0, 0.55, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(inset)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(radius * 0.55)),
      paint,
    );

    // Shine highlight
    final shinePaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.2, center.dy - radius * 0.25),
        width: radius * 0.55,
        height: radius * 0.35,
      ),
      shinePaint,
    );

    // Border stroke
    final borderPaint = Paint()
      ..color = type.darkColor.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(radius * 0.55)),
      borderPaint,
    );
  }

  // ── Special indicators ──────────────────────────────────────────────────

  void _drawSpecial(Canvas canvas, Rect rect, SpecialType special) {
    final center = rect.center;
    final s = cellSize * 0.18;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (special) {
      case SpecialType.rocketHorizontal:
        // Left arrow
        canvas.drawLine(
          Offset(center.dx - s * 1.5, center.dy),
          Offset(center.dx - s * 0.5, center.dy - s * 0.6),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - s * 1.5, center.dy),
          Offset(center.dx - s * 0.5, center.dy + s * 0.6),
          strokePaint,
        );
        // Right arrow
        canvas.drawLine(
          Offset(center.dx + s * 1.5, center.dy),
          Offset(center.dx + s * 0.5, center.dy - s * 0.6),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + s * 1.5, center.dy),
          Offset(center.dx + s * 0.5, center.dy + s * 0.6),
          strokePaint,
        );
      case SpecialType.rocketVertical:
        // Up arrow
        canvas.drawLine(
          Offset(center.dx, center.dy - s * 1.5),
          Offset(center.dx - s * 0.6, center.dy - s * 0.5),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - s * 1.5),
          Offset(center.dx + s * 0.6, center.dy - s * 0.5),
          strokePaint,
        );
        // Down arrow
        canvas.drawLine(
          Offset(center.dx, center.dy + s * 1.5),
          Offset(center.dx - s * 0.6, center.dy + s * 0.5),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy + s * 1.5),
          Offset(center.dx + s * 0.6, center.dy + s * 0.5),
          strokePaint,
        );
      case SpecialType.bomb:
        canvas.drawCircle(center, s * 1.1, strokePaint..strokeWidth = 2.5);
      case SpecialType.rainbow:
        // Four colored dots in a diamond
        const dotColors = [
          Color(0xFFFF4080),
          Color(0xFF33D973),
          Color(0xFF338CFF),
          Color(0xFFFFD91A),
        ];
        final offsets = [
          Offset(center.dx, center.dy - s),
          Offset(center.dx + s, center.dy),
          Offset(center.dx, center.dy + s),
          Offset(center.dx - s, center.dy),
        ];
        for (int i = 0; i < 4; i++) {
          canvas.drawCircle(
            offsets[i],
            s * 0.32,
            Paint()..color = dotColors[i],
          );
        }
      case SpecialType.lightning:
        final path = Path()
          ..moveTo(center.dx - s * 0.3, center.dy - s * 1.3)
          ..lineTo(center.dx + s * 0.4, center.dy - s * 0.2)
          ..lineTo(center.dx - s * 0.1, center.dy - s * 0.1)
          ..lineTo(center.dx + s * 0.3, center.dy + s * 1.3)
          ..lineTo(center.dx - s * 0.4, center.dy + s * 0.2)
          ..lineTo(center.dx + s * 0.1, center.dy + s * 0.1)
          ..close();
        canvas.drawPath(
          path,
          paint..color = GameColors.goldFrame,
        );
      case SpecialType.none:
        break;
    }
  }

  // ── Obstacles ───────────────────────────────────────────────────────────

  void _drawObstacle(Canvas canvas, Rect rect, ObstacleType obstacle) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    switch (obstacle) {
      case ObstacleType.ice1:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0x4000E5FF), // cyan overlay
        );
      case ObstacleType.ice2:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0x6600E5FF),
        );
      case ObstacleType.box:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0xFF8B6914),
        );
        // Cross lines
        final crossPaint = Paint()
          ..color = const Color(0xFFA07820)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(rect.topLeft, rect.bottomRight, crossPaint);
        canvas.drawLine(rect.topRight, rect.bottomLeft, crossPaint);
      case ObstacleType.fog:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0x88888888),
        );
      case ObstacleType.chain1:
        _drawChainX(canvas, rect, 1);
      case ObstacleType.chain2:
        _drawChainX(canvas, rect, 2);
      case ObstacleType.chocolate:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0xFF5C3317),
        );
      case ObstacleType.honey:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0x66FFB300),
        );
      case ObstacleType.portal:
        canvas.drawCircle(
          rect.center,
          cellSize * 0.35,
          Paint()
            ..color = const Color(0x889040E0)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          rect.center,
          cellSize * 0.35,
          Paint()
            ..color = GameColors.neonPurple
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case ObstacleType.iceWall:
        canvas.drawRRect(
          rr,
          Paint()..color = const Color(0xAAB0E0FF),
        );
      case ObstacleType.bubble:
        canvas.drawCircle(
          rect.center,
          cellSize * 0.38,
          Paint()
            ..color = Colors.white.withAlpha(40)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          rect.center,
          cellSize * 0.38,
          Paint()
            ..color = Colors.white.withAlpha(120)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case ObstacleType.none:
        break;
    }
  }

  void _drawChainX(Canvas canvas, Rect rect, int level) {
    final paint = Paint()
      ..color = const Color(0xFFA0A0A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = level == 2 ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;
    final m = cellSize * 0.15;
    canvas.drawLine(
      Offset(rect.left + m, rect.top + m),
      Offset(rect.right - m, rect.bottom - m),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - m, rect.top + m),
      Offset(rect.left + m, rect.bottom - m),
      paint,
    );
  }

  // ── Selection ───────────────────────────────────────────────────────────

  void _drawSelection(Canvas canvas, Rect rect) {
    final alpha = (150 + (105 * pulseValue)).toInt();
    final paint = Paint()
      ..color = GameColors.goldFrame.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + pulseValue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(-1.0),
        const Radius.circular(7),
      ),
      paint,
    );
  }

  // ── Hint ────────────────────────────────────────────────────────────────

  void _drawHint(Canvas canvas, Rect rect) {
    final alpha = (80 + (120 * pulseValue)).toInt();
    final paint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + pulseValue * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(-0.5),
        const Radius.circular(7),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
