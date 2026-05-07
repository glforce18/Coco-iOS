import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:patpat_game/game/board_animator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/special_effects_overlay.dart';

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
/// and hints. Supports smooth Candy Crush-style animations via
/// [BoardAnimator] for swaps, destroys, gravity, and fills.
class GameBoard extends StatefulWidget {
  final GameGrid grid;
  final Position? selectedCell;
  final (Position, Position)? hintPositions;
  final ActiveBoosterMode boosterMode;
  final Function(Position) onCellTapped;
  final Function(Position, SwapDirection) onSwipe;
  final BoardAnimator animator;
  final Function(double cellSize, double gap)? onCellMetrics;

  const GameBoard({
    super.key,
    required this.grid,
    this.selectedCell,
    this.hintPositions,
    this.boosterMode = ActiveBoosterMode.none,
    required this.onCellTapped,
    required this.onSwipe,
    required this.animator,
    this.onCellMetrics,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Ticker _animTicker;
  bool _tickerActive = false;

  Offset? _panStart;
  Position? _panStartCell;
  bool _swipeHandled = false;
  double _lastCellSize = 0;

  static const double _gap = 3.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Ticker for smooth 60fps animation rendering
    _animTicker = createTicker(_onAnimTick);
    widget.animator.addListener(_onAnimatorChanged);
  }

  void _onAnimatorChanged() {
    if (widget.animator.hasActiveAnimations && !_tickerActive) {
      _tickerActive = true;
      _animTicker.start();
    } else if (!widget.animator.hasActiveAnimations && _tickerActive) {
      _tickerActive = false;
      _animTicker.stop();
      if (mounted) setState(() {});
    }
  }

  void _onAnimTick(Duration elapsed) {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animator != widget.animator) {
      oldWidget.animator.removeListener(_onAnimatorChanged);
      widget.animator.addListener(_onAnimatorChanged);
    }
  }

  @override
  void dispose() {
    widget.animator.removeListener(_onAnimatorChanged);
    if (_tickerActive) _animTicker.stop();
    _animTicker.dispose();
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

        // Report cell metrics to controller for animation calculations
        if (cellSize != _lastCellSize) {
          _lastCellSize = cellSize;
          widget.onCellMetrics?.call(cellSize, _gap);
        }

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
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulseValue = _pulseController.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Position each cell individually for precise layout
                    for (int r = 0; r < widget.grid.rows; r++)
                      for (int c = 0; c < widget.grid.cols; c++)
                        _buildAnimatedCell(
                          r, c, cellSize, boardOffset, pulseValue,
                        ),
                    // Special activation effects overlay (laser, shockwave, etc.)
                    if (widget.animator.activeSpecialEffect != null)
                      Positioned.fill(
                        child: SpecialEffectsOverlay(
                          activeEffect: widget.animator.activeSpecialEffect!,
                          cellSize: cellSize,
                          gap: _gap,
                          gridRows: widget.grid.rows,
                          gridCols: widget.grid.cols,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Build a single cell with animation offsets, scale, and opacity applied.
  Widget _buildAnimatedCell(
    int r,
    int c,
    double cellSize,
    Offset boardOffset,
    double pulseValue,
  ) {
    final anim = widget.animator.getAnimation(r, c);
    final baseLeft = boardOffset.dx + c * (cellSize + _gap);
    final baseTop = boardOffset.dy + r * (cellSize + _gap);

    final offset = anim?.currentOffset ?? Offset.zero;
    final scale = anim?.currentScale ?? 1.0;
    final opacity = anim?.currentOpacity ?? 1.0;

    Widget cell = _JellyCell(
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
    );

    // Apply scale and opacity only when animating (avoid unnecessary wrapping)
    if (anim != null) {
      if (scale != 1.0 || opacity != 1.0) {
        cell = Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.5),
            child: cell,
          ),
        );
      }
    }

    return Positioned(
      left: baseLeft + offset.dx,
      top: baseTop + offset.dy,
      width: cellSize,
      height: cellSize,
      child: cell,
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

        // 3. Jelly content — specials get entirely unique widgets
        if (hasJelly && jellyType != null)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(cellSize * 0.04),
              child: _buildJellyContent(
                  jellyType, specialType, cellSize, pulseValue),
            ),
          ),

        // 4. Selection highlight
        if (isSelected)
          Positioned.fill(
            child: _SelectionHighlight(
              pulseValue: pulseValue,
              cellSize: cellSize,
            ),
          ),

        // 5. Hint highlight
        if (isHint)
          Positioned.fill(
            child: _HintHighlight(
              pulseValue: pulseValue,
            ),
          ),
      ],
    );
  }

  /// Route to the correct visual widget based on special type.
  static Widget _buildJellyContent(
    JellyType type,
    SpecialType special,
    double cellSize,
    double pulseValue,
  ) {
    switch (special) {
      case SpecialType.none:
        return Image.asset(
          _jellySpritePath(type),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _FallbackJelly(type: type),
        );
      case SpecialType.rocketHorizontal:
        return _RocketJelly(
            type: type, horizontal: true, pulseValue: pulseValue);
      case SpecialType.rocketVertical:
        return _RocketJelly(
            type: type, horizontal: false, pulseValue: pulseValue);
      case SpecialType.bomb:
        return _BombJelly(pulseValue: pulseValue, cellSize: cellSize);
      case SpecialType.rainbow:
        return _RainbowJelly(pulseValue: pulseValue, cellSize: cellSize);
      case SpecialType.lightning:
        return _LightningJelly(
            type: type, pulseValue: pulseValue, cellSize: cellSize);
    }
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
// _RocketJelly — unique visual for horizontal/vertical rocket specials
// ─────────────────────────────────────────────────────────────────────────────

class _RocketJelly extends StatelessWidget {
  final JellyType type;
  final bool horizontal;
  final double pulseValue;

  const _RocketJelly({
    required this.type,
    required this.horizontal,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Pulsing glow background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3)
                      .withAlpha((60 + pulseValue * 60).toInt()),
                  blurRadius: 10 + pulseValue * 6,
                  spreadRadius: 1 + pulseValue * 2,
                ),
              ],
            ),
          ),
        ),
        // 2. Dimmed base jelly sprite
        Positioned.fill(
          child: Opacity(
            opacity: 0.55,
            child: Image.asset(
              _jellySpritePath(type),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _FallbackJelly(type: type),
            ),
          ),
        ),
        // 3. CustomPainter: glowing arrow lines through center
        Positioned.fill(
          child: CustomPaint(
            painter: _RocketArrowPainter(
              horizontal: horizontal,
              pulseValue: pulseValue,
              color: type.color,
            ),
          ),
        ),
        // 4. Directional streak lines
        Positioned.fill(
          child: CustomPaint(
            painter: _RocketStreakPainter(
              horizontal: horizontal,
              pulseValue: pulseValue,
              color: const Color(0xFF64B5F6),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BombJelly — unique visual for bomb specials
// ─────────────────────────────────────────────────────────────────────────────

class _BombJelly extends StatelessWidget {
  final double pulseValue;
  final double cellSize;

  const _BombJelly({
    required this.pulseValue,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final rotationAngle = pulseValue * 2 * pi;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Pulsing orange glow background
        Positioned.fill(
          child: Transform.scale(
            scale: 1.0 + pulseValue * 0.1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722)
                        .withAlpha((70 + pulseValue * 70).toInt()),
                    blurRadius: 12 + pulseValue * 8,
                    spreadRadius: 1 + pulseValue * 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 2. Bomb sprite
        Positioned.fill(
          child: Transform.scale(
            scale: 1.0 + pulseValue * 0.08,
            child: Image.asset(
              'assets/sprites/jelly_bomb.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) =>
                  const _FallbackJelly(type: JellyType.orange),
            ),
          ),
        ),
        // 3. Rotating ring of 4 spark dots
        ...List.generate(4, (i) {
          final angle = rotationAngle + i * pi / 2;
          final radius = cellSize * 0.38;
          final cx = cellSize / 2 + cos(angle) * radius;
          final cy = cellSize / 2 + sin(angle) * radius;
          final sparkAlpha = (180 + pulseValue * 75).toInt().clamp(0, 255);
          return Positioned(
            left: cx - 3,
            top: cy - 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFAB40).withAlpha(sparkAlpha),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00)
                        .withAlpha((sparkAlpha * 0.7).toInt()),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RainbowJelly — unique visual for rainbow specials
// ─────────────────────────────────────────────────────────────────────────────

class _RainbowJelly extends StatelessWidget {
  final double pulseValue;
  final double cellSize;

  const _RainbowJelly({
    required this.pulseValue,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final orbitAngle = pulseValue * 2 * pi;
    final radius = cellSize * 0.36;
    final center = cellSize / 2;
    const rainbowColors = [
      Color(0xFFFF4D80), // pink
      Color(0xFFFF801A), // orange
      Color(0xFFFFD91A), // yellow
      Color(0xFF33D973), // green
      Color(0xFF338CFF), // blue
      Color(0xFF8B24DB), // purple
    ];

    // Hue-shifting glow
    final hue = pulseValue * 360;
    final glowColor = HSLColor.fromAHSL(1, hue, 0.9, 0.6).toColor();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Cycling color glow background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withAlpha((80 + pulseValue * 50).toInt()),
                  blurRadius: 14 + pulseValue * 6,
                  spreadRadius: 1 + pulseValue * 2,
                ),
              ],
            ),
          ),
        ),
        // 2. Rainbow sprite
        Positioned.fill(
          child: Image.asset(
            'assets/sprites/jelly_rainbow.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) =>
                const _FallbackJelly(type: JellyType.purple),
          ),
        ),
        // 3. 6 orbiting colored dots
        ...List.generate(6, (i) {
          final angle = orbitAngle + i * (pi / 3);
          final dx = center + cos(angle) * radius;
          final dy = center + sin(angle) * radius;
          final dotAlpha = (200 + pulseValue * 55).toInt().clamp(0, 255);
          return Positioned(
            left: dx - 3.5,
            top: dy - 3.5,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rainbowColors[i].withAlpha(dotAlpha),
                boxShadow: [
                  BoxShadow(
                    color:
                        rainbowColors[i].withAlpha((dotAlpha * 0.6).toInt()),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          );
        }),
        // 4. Shimmer overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _ShimmerPainter(pulseValue: pulseValue),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LightningJelly — unique visual for lightning specials
// ─────────────────────────────────────────────────────────────────────────────

class _LightningJelly extends StatelessWidget {
  final JellyType type;
  final double pulseValue;
  final double cellSize;

  const _LightningJelly({
    required this.type,
    required this.pulseValue,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final boltAlpha = (160 + pulseValue * 95).toInt().clamp(0, 255);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Electric yellow glow background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700)
                      .withAlpha((70 + pulseValue * 80).toInt()),
                  blurRadius: 10 + pulseValue * 10,
                  spreadRadius: 1 + pulseValue * 2,
                ),
              ],
            ),
          ),
        ),
        // 2. Dark sphere base with lightning bolts (CustomPainter)
        Positioned.fill(
          child: CustomPaint(
            painter: _LightningBoltPainter(
              pulseValue: pulseValue,
              baseColor: type.color,
            ),
          ),
        ),
        // 3. Central lightning bolt icon
        Center(
          child: Icon(
            Icons.flash_on,
            size: cellSize * 0.45,
            color: GameColors.goldFrameMid.withAlpha(boltAlpha),
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withAlpha(boltAlpha),
                blurRadius: 12,
              ),
              Shadow(
                color: Colors.white.withAlpha((boltAlpha * 0.6).toInt()),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        // 4. Spark particles at pseudo-random positions
        ...List.generate(5, (i) {
          final seed = (pulseValue * 5 + i * 1.3) % 1.0;
          final sx = cellSize * (0.1 + seed * 0.8);
          final sy = cellSize * (0.1 + ((seed * 3.7) % 1.0) * 0.8);
          final dotAlpha =
              ((100 + pulseValue * 100) * (0.5 + seed * 0.5))
                  .toInt()
                  .clamp(0, 255);
          return Positioned(
            left: sx - 2,
            top: sy - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(dotAlpha),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withAlpha(dotAlpha),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RocketArrowPainter — glowing arrow lines through center for rocket specials
// ─────────────────────────────────────────────────────────────────────────────

class _RocketArrowPainter extends CustomPainter {
  final bool horizontal;
  final double pulseValue;
  final Color color;

  _RocketArrowPainter({
    required this.horizontal,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glowAlpha = (120 + pulseValue * 120).toInt().clamp(0, 255);

    // Arrow head paint
    final arrowPaint = Paint()
      ..color = Colors.white.withAlpha(glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + pulseValue * 0.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Core line paint (brighter)
    final linePaint = Paint()
      ..color = color.withAlpha(glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + pulseValue
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    if (horizontal) {
      // Horizontal line through center
      final lineY = center.dy;
      canvas.drawLine(
        Offset(size.width * 0.08, lineY),
        Offset(size.width * 0.92, lineY),
        linePaint,
      );
      // Left arrow head <
      final leftTip = Offset(size.width * 0.08, lineY);
      canvas.drawLine(leftTip, Offset(size.width * 0.22, lineY - size.height * 0.15), arrowPaint);
      canvas.drawLine(leftTip, Offset(size.width * 0.22, lineY + size.height * 0.15), arrowPaint);
      // Right arrow head >
      final rightTip = Offset(size.width * 0.92, lineY);
      canvas.drawLine(rightTip, Offset(size.width * 0.78, lineY - size.height * 0.15), arrowPaint);
      canvas.drawLine(rightTip, Offset(size.width * 0.78, lineY + size.height * 0.15), arrowPaint);
    } else {
      // Vertical line through center
      final lineX = center.dx;
      canvas.drawLine(
        Offset(lineX, size.height * 0.08),
        Offset(lineX, size.height * 0.92),
        linePaint,
      );
      // Top arrow head ^
      final topTip = Offset(lineX, size.height * 0.08);
      canvas.drawLine(topTip, Offset(lineX - size.width * 0.15, size.height * 0.22), arrowPaint);
      canvas.drawLine(topTip, Offset(lineX + size.width * 0.15, size.height * 0.22), arrowPaint);
      // Bottom arrow head v
      final bottomTip = Offset(lineX, size.height * 0.92);
      canvas.drawLine(bottomTip, Offset(lineX - size.width * 0.15, size.height * 0.78), arrowPaint);
      canvas.drawLine(bottomTip, Offset(lineX + size.width * 0.15, size.height * 0.78), arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RocketArrowPainter old) =>
      old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// _LightningBoltPainter — dark sphere with radiating electric bolts
// ─────────────────────────────────────────────────────────────────────────────

class _LightningBoltPainter extends CustomPainter {
  final double pulseValue;
  final Color baseColor;

  _LightningBoltPainter({
    required this.pulseValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Dark sphere base
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          Color.lerp(baseColor, Colors.black, 0.5)!,
          Color.lerp(baseColor, Colors.black, 0.8)!,
          Colors.black,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // Radiating lightning bolts (4 directions)
    final boltPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(
          (140 + pulseValue * 100).toInt().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (int i = 0; i < 4; i++) {
      final baseAngle = i * pi / 2 + pulseValue * 0.3;
      final boltStart = Offset(
        center.dx + cos(baseAngle) * radius * 0.5,
        center.dy + sin(baseAngle) * radius * 0.5,
      );
      // Zig-zag bolt
      final mid1 = Offset(
        center.dx + cos(baseAngle + 0.3) * radius * 0.8,
        center.dy + sin(baseAngle + 0.3) * radius * 0.8,
      );
      final mid2 = Offset(
        center.dx + cos(baseAngle - 0.2) * radius * 1.1,
        center.dy + sin(baseAngle - 0.2) * radius * 1.1,
      );
      final boltEnd = Offset(
        center.dx + cos(baseAngle + 0.1) * radius * 1.4,
        center.dy + sin(baseAngle + 0.1) * radius * 1.4,
      );

      final path = Path()
        ..moveTo(boltStart.dx, boltStart.dy)
        ..lineTo(mid1.dx, mid1.dy)
        ..lineTo(mid2.dx, mid2.dy)
        ..lineTo(boltEnd.dx, boltEnd.dy);
      canvas.drawPath(path, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LightningBoltPainter old) =>
      old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// _RocketStreakPainter — directional glow streaks for rocket specials
// ─────────────────────────────────────────────────────────────────────────────

class _RocketStreakPainter extends CustomPainter {
  final bool horizontal;
  final double pulseValue;
  final Color color;

  _RocketStreakPainter({
    required this.horizontal,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (60 + pulseValue * 80).toInt().clamp(0, 255);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final center = Offset(size.width / 2, size.height / 2);
    final lineLength = (horizontal ? size.width : size.height) * 0.42;
    final lineWidth = 2.0 + pulseValue;

    if (horizontal) {
      // Left streak
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - lineLength * 0.3, center.dy),
            width: lineLength,
            height: lineWidth,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      // Right streak
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + lineLength * 0.3, center.dy),
            width: lineLength,
            height: lineWidth,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    } else {
      // Top streak
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - lineLength * 0.3),
            width: lineWidth,
            height: lineLength,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      // Bottom streak
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + lineLength * 0.3),
            width: lineWidth,
            height: lineLength,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RocketStreakPainter old) =>
      old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerPainter — traveling highlight shimmer for rainbow specials
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double pulseValue;
  _ShimmerPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerX = -size.width * 0.3 + pulseValue * size.width * 1.6;
    final shimmerWidth = size.width * 0.3;
    final rect = Rect.fromLTWH(shimmerX, 0, shimmerWidth, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withAlpha(0),
          Colors.white.withAlpha(40),
          Colors.white.withAlpha(0),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.pulseValue != pulseValue;
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
                color: GameColors.buttonPurple,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.buttonPurple.withAlpha(60),
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
            color: GameColors.goldFrameMid.withAlpha(alpha),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldFrameMid.withAlpha((60 + 40 * pulseValue).toInt()),
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
