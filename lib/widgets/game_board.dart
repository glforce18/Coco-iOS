import 'dart:math';

import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Sprite asset path for a [JellyType].
String _jellySpritePath(JellyType type) {
  switch (type) {
    case JellyType.purple:
      return 'assets/sprites/jelly_purple.png';
    case JellyType.yellow:
      return 'assets/sprites/jelly_yellow.png';
    case JellyType.blue:
      return 'assets/sprites/jelly_blue.png';
    case JellyType.green:
      return 'assets/sprites/jelly_green.png';
    case JellyType.pink:
      return 'assets/sprites/jelly_pink.png';
    case JellyType.orange:
      return 'assets/sprites/jelly_orange.png';
  }
}

/// Interactive game board rendered as a grid of sprite-based widgets.
///
/// Handles tap and swipe gestures. Each cell renders jelly sprites from
/// `assets/sprites/`, with overlays for specials, obstacles, selection,
/// and hints.
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

  static const double _gap = 3.0;

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

  /// Hit-test: find the cell under [local] coordinates.
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
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final pulseValue = _pulseController.value;
              return Stack(
                children: [
                  // Position each cell individually for precise layout
                  for (int r = 0; r < widget.grid.rows; r++)
                    for (int c = 0; c < widget.grid.cols; c++)
                      Positioned(
                        left: boardOffset.dx + c * (cellSize + _gap),
                        top: boardOffset.dy + r * (cellSize + _gap),
                        width: cellSize,
                        height: cellSize,
                        child: _JellyCell(
                          cell: widget.grid.get(r, c),
                          cellSize: cellSize,
                          isSelected: widget.selectedCell != null &&
                              widget.selectedCell!.row == r &&
                              widget.selectedCell!.col == c,
                          isHint: widget.hintPositions != null &&
                              ((widget.hintPositions!.$1.row == r &&
                                      widget.hintPositions!.$1.col == c) ||
                                  (widget.hintPositions!.$2.row == r &&
                                      widget.hintPositions!.$2.col == c)),
                          pulseValue: pulseValue,
                        ),
                      ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JellyCell — individual cell widget with sprite rendering
// ─────────────────────────────────────────────────────────────────────────────

class _JellyCell extends StatelessWidget {
  final dynamic cell; // Cell type
  final double cellSize;
  final bool isSelected;
  final bool isHint;
  final double pulseValue;

  const _JellyCell({
    required this.cell,
    required this.cellSize,
    required this.isSelected,
    required this.isHint,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final obstacleType = cell.obstacle as ObstacleType;
    final jellyType = cell.jellyType as JellyType?;
    final specialType = cell.specialType as SpecialType;
    final hasJelly = cell.hasJelly as bool;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Cell background tile
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A0550),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2A1570).withAlpha(120),
                width: 0.5,
              ),
            ),
          ),
        ),

        // 2. Obstacle overlay (behind jelly for ice-style overlays)
        if (obstacleType != ObstacleType.none)
          Positioned.fill(
            child: _ObstacleOverlay(
              obstacle: obstacleType,
              cellSize: cellSize,
            ),
          ),

        // 3. Jelly sprite
        if (hasJelly && jellyType != null)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(cellSize * 0.06),
              child: _buildJellySprite(jellyType, specialType),
            ),
          ),

        // 4. Special indicator overlay on top of sprite
        if (specialType != SpecialType.none)
          Positioned.fill(
            child: _SpecialOverlay(
              special: specialType,
              cellSize: cellSize,
            ),
          ),

        // 5. Selection highlight
        if (isSelected)
          Positioned.fill(
            child: _SelectionHighlight(
              pulseValue: pulseValue,
              cellSize: cellSize,
            ),
          ),

        // 6. Hint highlight
        if (isHint)
          Positioned.fill(
            child: _HintHighlight(
              pulseValue: pulseValue,
            ),
          ),
      ],
    );
  }

  Widget _buildJellySprite(JellyType type, SpecialType special) {
    // Rainbow special uses dedicated rainbow sprite
    if (special == SpecialType.rainbow) {
      return Image.asset(
        'assets/sprites/jelly_rainbow.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _FallbackJelly(type: type),
      );
    }

    return Image.asset(
      _jellySpritePath(type),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _FallbackJelly(type: type),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FallbackJelly — colored circle fallback if sprite fails to load
// ─────────────────────────────────────────────────────────────────────────────

class _FallbackJelly extends StatelessWidget {
  final JellyType type;
  const _FallbackJelly({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.9,
          colors: [
            Color.lerp(type.color, Colors.white, 0.3)!,
            type.color,
            Color.lerp(type.color, Colors.black, 0.3)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: type.color.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialOverlay — icon indicator for special types
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialOverlay extends StatelessWidget {
  final SpecialType special;
  final double cellSize;

  const _SpecialOverlay({
    required this.special,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (special) {
      case SpecialType.rocketHorizontal:
        return _buildCornerBadge(
          icon: Icons.arrow_right_alt,
          color: Colors.white,
          bgColor: const Color(0xCC2196F3),
        );
      case SpecialType.rocketVertical:
        return _buildCornerBadge(
          icon: Icons.arrow_upward,
          color: Colors.white,
          bgColor: const Color(0xCC2196F3),
        );
      case SpecialType.bomb:
        return _buildCornerBadge(
          icon: Icons.blur_circular,
          color: Colors.white,
          bgColor: const Color(0xCCFF5722),
        );
      case SpecialType.rainbow:
        // Rainbow is shown via sprite — no corner badge needed
        return const SizedBox.shrink();
      case SpecialType.lightning:
        return _buildCornerBadge(
          icon: Icons.flash_on,
          color: GameColors.goldFrame,
          bgColor: const Color(0xCC6A1B9A),
        );
      case SpecialType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCornerBadge({
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final badgeSize = cellSize * 0.38;
    return Positioned(
      right: -1,
      bottom: -1,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(badgeSize * 0.3),
          border: Border.all(color: Colors.white.withAlpha(180), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: badgeSize * 0.7),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ObstacleOverlay — visual overlay for obstacles
// ─────────────────────────────────────────────────────────────────────────────

class _ObstacleOverlay extends StatelessWidget {
  final ObstacleType obstacle;
  final double cellSize;

  const _ObstacleOverlay({
    required this.obstacle,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (obstacle) {
      case ObstacleType.ice1:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0x4000E5FF),
            border: Border.all(
              color: const Color(0x6600E5FF),
              width: 1,
            ),
          ),
        );
      case ObstacleType.ice2:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0x6600E5FF),
            border: Border.all(
              color: const Color(0x9900E5FF),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.ac_unit,
              size: cellSize * 0.3,
              color: Colors.white.withAlpha(80),
            ),
          ),
        );
      case ObstacleType.box:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9B7520), Color(0xFF8B6914), Color(0xFF6B4E10)],
            ),
            border: Border.all(color: const Color(0xFFA07820), width: 1.5),
          ),
          child: CustomPaint(
            painter: _CrossPainter(),
          ),
        );
      case ObstacleType.fog:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0x88888888),
          ),
          child: Center(
            child: Icon(
              Icons.cloud,
              size: cellSize * 0.4,
              color: Colors.white.withAlpha(60),
            ),
          ),
        );
      case ObstacleType.chain1:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _ChainPainter(level: 1),
          ),
        );
      case ObstacleType.chain2:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _ChainPainter(level: 2),
          ),
        );
      case ObstacleType.chocolate:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B4320), Color(0xFF5C3317), Color(0xFF3D200E)],
            ),
          ),
        );
      case ObstacleType.honey:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0x66FFB300),
            border: Border.all(
              color: const Color(0x88FFB300),
              width: 1,
            ),
          ),
        );
      case ObstacleType.portal:
        return Center(
          child: Container(
            width: cellSize * 0.7,
            height: cellSize * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x889040E0),
              border: Border.all(
                color: GameColors.neonPurple,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.neonPurple.withAlpha(60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      case ObstacleType.iceWall:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xAAB0E0FF),
            border: Border.all(
              color: const Color(0xBBB0E0FF),
              width: 1.5,
            ),
          ),
        );
      case ObstacleType.bubble:
        return Center(
          child: Container(
            width: cellSize * 0.76,
            height: cellSize * 0.76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(30),
              border: Border.all(
                color: Colors.white.withAlpha(120),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(20),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      case ObstacleType.none:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SelectionHighlight — golden glow pulsing border
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionHighlight extends StatelessWidget {
  final double pulseValue;
  final double cellSize;

  const _SelectionHighlight({
    required this.pulseValue,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = (150 + (105 * pulseValue)).toInt();
    final borderWidth = 2.5 + pulseValue;
    final scale = 1.0 + pulseValue * 0.06;

    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: GameColors.goldFrame.withAlpha(alpha),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldFrame.withAlpha((60 + 40 * pulseValue).toInt()),
              blurRadius: 8 + pulseValue * 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HintHighlight — pulsing white glow border
// ─────────────────────────────────────────────────────────────────────────────

class _HintHighlight extends StatelessWidget {
  final double pulseValue;

  const _HintHighlight({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    final alpha = (80 + (120 * pulseValue)).toInt();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(alpha),
          width: 2.0 + pulseValue * 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha((30 + 40 * pulseValue).toInt()),
            blurRadius: 6 + pulseValue * 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainters for obstacles (kept lightweight)
// ─────────────────────────────────────────────────────────────────────────────

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA07820)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final m = size.width * 0.15;
    canvas.drawLine(Offset(m, m), Offset(size.width - m, size.height - m), paint);
    canvas.drawLine(Offset(size.width - m, m), Offset(m, size.height - m), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChainPainter extends CustomPainter {
  final int level;
  _ChainPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA0A0A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = level == 2 ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;
    final m = size.width * 0.15;
    canvas.drawLine(Offset(m, m), Offset(size.width - m, size.height - m), paint);
    canvas.drawLine(Offset(size.width - m, m), Offset(m, size.height - m), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
