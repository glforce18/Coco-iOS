import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:patpat_game/game/board_animator.dart';
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

        // 2b. Special glow background (behind jelly)
        if (specialType != SpecialType.none && hasJelly)
          Positioned.fill(
            child: _SpecialGlowBackground(
              special: specialType,
              jellyType: jellyType,
              cellSize: cellSize,
              pulseValue: pulseValue,
            ),
          ),

        // 3. Jelly sprite (with pulsing scale for specials)
        if (hasJelly && jellyType != null)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(cellSize * 0.06),
              child: specialType == SpecialType.bomb
                  ? Transform.scale(
                      scale: 1.0 + pulseValue * 0.08,
                      child: _buildJellySprite(jellyType, specialType),
                    )
                  : _buildJellySprite(jellyType, specialType),
            ),
          ),

        // 4. Special effect overlay on top of sprite
        if (specialType != SpecialType.none && hasJelly)
          Positioned.fill(
            child: _SpecialOverlay(
              special: specialType,
              jellyType: jellyType,
              cellSize: cellSize,
              pulseValue: pulseValue,
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

    // Bomb special uses dedicated bomb sprite
    if (special == SpecialType.bomb) {
      return Image.asset(
        'assets/sprites/jelly_bomb.png',
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
// _SpecialGlowBackground — glowing background effect behind special jellies
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialGlowBackground extends StatelessWidget {
  final SpecialType special;
  final JellyType? jellyType;
  final double cellSize;
  final double pulseValue;

  const _SpecialGlowBackground({
    required this.special,
    required this.jellyType,
    required this.cellSize,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final Color glowColor;
    final double glowBlur;
    final double glowAlphaBase;

    switch (special) {
      case SpecialType.rocketHorizontal:
      case SpecialType.rocketVertical:
        glowColor = const Color(0xFF2196F3);
        glowBlur = 10 + pulseValue * 6;
        glowAlphaBase = 0.25;
      case SpecialType.bomb:
        glowColor = const Color(0xFFFF5722);
        glowBlur = 12 + pulseValue * 8;
        glowAlphaBase = 0.3;
      case SpecialType.rainbow:
        // Rainbow gets a shifting hue glow
        final hue = pulseValue * 360;
        glowColor = HSLColor.fromAHSL(1, hue, 0.9, 0.6).toColor();
        glowBlur = 14 + pulseValue * 6;
        glowAlphaBase = 0.35;
      case SpecialType.lightning:
        glowColor = const Color(0xFFFFD700);
        glowBlur = 10 + pulseValue * 10;
        glowAlphaBase = 0.3;
      case SpecialType.none:
        return const SizedBox.shrink();
    }

    final alpha = ((glowAlphaBase + pulseValue * 0.15) * 255).toInt().clamp(0, 255);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha(alpha),
            blurRadius: glowBlur,
            spreadRadius: 1 + pulseValue * 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialOverlay — impressive visual effects for special types
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialOverlay extends StatelessWidget {
  final SpecialType special;
  final JellyType? jellyType;
  final double cellSize;
  final double pulseValue;

  const _SpecialOverlay({
    required this.special,
    required this.jellyType,
    required this.cellSize,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    switch (special) {
      case SpecialType.rocketHorizontal:
        return _buildRocketOverlay(horizontal: true);
      case SpecialType.rocketVertical:
        return _buildRocketOverlay(horizontal: false);
      case SpecialType.bomb:
        return _buildBombOverlay();
      case SpecialType.rainbow:
        return _buildRainbowOverlay();
      case SpecialType.lightning:
        return _buildLightningOverlay();
      case SpecialType.none:
        return const SizedBox.shrink();
    }
  }

  /// Rocket: glowing directional arrow + pulsing trail lines
  Widget _buildRocketOverlay({required bool horizontal}) {
    final arrowAngle = horizontal ? 0.0 : -pi / 2;
    final trailAlpha = (120 + pulseValue * 100).toInt().clamp(0, 255);
    final glowAlpha = (60 + pulseValue * 80).toInt().clamp(0, 255);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Directional glow streaks
        Positioned.fill(
          child: CustomPaint(
            painter: _RocketStreakPainter(
              horizontal: horizontal,
              pulseValue: pulseValue,
              color: const Color(0xFF64B5F6),
            ),
          ),
        ),
        // Arrow icon centered
        Center(
          child: Transform.rotate(
            angle: arrowAngle,
            child: Icon(
              Icons.double_arrow_rounded,
              size: cellSize * 0.45,
              color: Colors.white.withAlpha(trailAlpha),
              shadows: [
                Shadow(
                  color: const Color(0xFF2196F3).withAlpha(glowAlpha),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bomb: rotating glow ring + pulsing scale
  Widget _buildBombOverlay() {
    final ringAlpha = (100 + pulseValue * 80).toInt().clamp(0, 255);
    final rotationAngle = pulseValue * 2 * pi;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Rotating glow ring
        Positioned.fill(
          child: Transform.rotate(
            angle: rotationAngle,
            child: Container(
              margin: EdgeInsets.all(cellSize * 0.04),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF5722).withAlpha(ringAlpha),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withAlpha((ringAlpha * 0.5).toInt()),
                    blurRadius: 6 + pulseValue * 4,
                    spreadRadius: pulseValue * 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pulsing spark dots at cardinal positions
        ...List.generate(4, (i) {
          final angle = rotationAngle + i * pi / 2;
          final radius = cellSize * 0.42;
          final cx = cellSize / 2 + cos(angle) * radius;
          final cy = cellSize / 2 + sin(angle) * radius;
          final sparkAlpha = (180 + pulseValue * 75).toInt().clamp(0, 255);
          return Positioned(
            left: cx - 2.5,
            top: cy - 2.5,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFAB40).withAlpha(sparkAlpha),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withAlpha((sparkAlpha * 0.6).toInt()),
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

  /// Rainbow: orbiting colored dots + shimmer effect
  Widget _buildRainbowOverlay() {
    final orbitAngle = pulseValue * 2 * pi;
    final radius = cellSize * 0.40;
    final center = cellSize / 2;
    final rainbowColors = [
      const Color(0xFFFF4D80), // pink
      const Color(0xFFFF801A), // orange
      const Color(0xFFFFD91A), // yellow
      const Color(0xFF33D973), // green
      const Color(0xFF338CFF), // blue
      const Color(0xFF8B24DB), // purple
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Orbiting colored dots
        ...List.generate(6, (i) {
          final angle = orbitAngle + i * (pi / 3);
          final dx = center + cos(angle) * radius;
          final dy = center + sin(angle) * radius;
          final dotAlpha = (200 + pulseValue * 55).toInt().clamp(0, 255);
          return Positioned(
            left: dx - 3,
            top: dy - 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rainbowColors[i].withAlpha(dotAlpha),
                boxShadow: [
                  BoxShadow(
                    color: rainbowColors[i].withAlpha((dotAlpha * 0.5).toInt()),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        }),
        // Shimmer flash (traveling highlight)
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

  /// Lightning: electric crackling glow + spark particles
  Widget _buildLightningOverlay() {
    final boltAlpha = (160 + pulseValue * 95).toInt().clamp(0, 255);
    final sparkAlpha = (100 + pulseValue * 100).toInt().clamp(0, 255);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Electric crackling edge glow
        Positioned.fill(
          child: Container(
            margin: EdgeInsets.all(cellSize * 0.06),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFFFD700).withAlpha((sparkAlpha * 0.5).toInt()),
                width: 1 + pulseValue * 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha((sparkAlpha * 0.4).toInt()),
                  blurRadius: 4 + pulseValue * 4,
                ),
              ],
            ),
          ),
        ),
        // Lightning bolt icon
        Center(
          child: Icon(
            Icons.flash_on,
            size: cellSize * 0.4,
            color: GameColors.goldFrame.withAlpha(boltAlpha),
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withAlpha(boltAlpha),
                blurRadius: 10,
              ),
              Shadow(
                color: Colors.white.withAlpha((boltAlpha * 0.5).toInt()),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        // Random spark dots
        ...List.generate(3, (i) {
          // Pseudo-random positions based on pulseValue and index
          final seed = (pulseValue * 5 + i * 1.7) % 1.0;
          final sx = cellSize * (0.15 + seed * 0.7);
          final sy = cellSize * (0.15 + ((seed * 3.7) % 1.0) * 0.7);
          final dotAlpha = (sparkAlpha * (0.5 + seed * 0.5)).toInt().clamp(0, 255);
          return Positioned(
            left: sx - 1.5,
            top: sy - 1.5,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(dotAlpha),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withAlpha(dotAlpha),
                    blurRadius: 3,
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
