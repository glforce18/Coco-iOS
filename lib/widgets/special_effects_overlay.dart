import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/position.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SpecialEffectType — the kind of activation effect to render
// ─────────────────────────────────────────────────────────────────────────────

enum SpecialEffectType {
  rocketHorizontal,
  rocketVertical,
  bombBlast,
  rainbowWave,
  lightningStrike,
  rocketCross,   // rocket + rocket combo
  megaBomb,      // bomb + bomb combo
  multiBeam,     // rocket + bomb combo
  boardClear,    // rainbow + rainbow combo
}

// ─────────────────────────────────────────────────────────────────────────────
// SpecialEffect — describes a single activation effect in progress
// ─────────────────────────────────────────────────────────────────────────────

class SpecialEffect {
  final SpecialEffectType type;
  final Position origin;
  final List<Position> targets;
  final JellyType? targetColor;
  final DateTime startTime;
  final int durationMs;

  SpecialEffect({
    required this.type,
    required this.origin,
    required this.targets,
    this.targetColor,
    required this.durationMs,
  }) : startTime = DateTime.now();

  /// Raw 0.0 .. 1.0 progress based on elapsed time.
  double get progress {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / durationMs).clamp(0.0, 1.0);
  }

  bool get isComplete => progress >= 1.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// SpecialEffectsOverlay — renders effect animations via CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class SpecialEffectsOverlay extends StatelessWidget {
  final SpecialEffect activeEffect;
  final double cellSize;
  final double gap;
  final int gridRows;
  final int gridCols;

  const SpecialEffectsOverlay({
    super.key,
    required this.activeEffect,
    required this.cellSize,
    required this.gap,
    required this.gridRows,
    required this.gridCols,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: CustomPaint(
          painter: _SpecialEffectPainter(
            effect: activeEffect,
            cellSize: cellSize,
            gap: gap,
            gridRows: gridRows,
            gridCols: gridCols,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpecialEffectPainter — CustomPainter that renders all effect types
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialEffectPainter extends CustomPainter {
  final SpecialEffect effect;
  final double cellSize;
  final double gap;
  final int gridRows;
  final int gridCols;

  _SpecialEffectPainter({
    required this.effect,
    required this.cellSize,
    required this.gap,
    required this.gridRows,
    required this.gridCols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Compute board offset so effects align with cells
    final boardWidth = cellSize * gridCols + gap * (gridCols - 1);
    final boardHeight = cellSize * gridRows + gap * (gridRows - 1);
    final boardOffsetX = (size.width - boardWidth) / 2;
    final boardOffsetY = (size.height - boardHeight) / 2;

    canvas.save();
    canvas.translate(boardOffsetX, boardOffsetY);

    switch (effect.type) {
      case SpecialEffectType.rocketHorizontal:
        _paintRocketHorizontal(canvas, boardWidth, boardHeight);
      case SpecialEffectType.rocketVertical:
        _paintRocketVertical(canvas, boardWidth, boardHeight);
      case SpecialEffectType.bombBlast:
        _paintBomb(canvas, boardWidth, boardHeight, 3);
      case SpecialEffectType.rainbowWave:
        _paintRainbow(canvas, boardWidth, boardHeight);
      case SpecialEffectType.lightningStrike:
        _paintLightning(canvas, boardWidth, boardHeight);
      case SpecialEffectType.rocketCross:
        _paintRocketHorizontal(canvas, boardWidth, boardHeight);
        _paintRocketVertical(canvas, boardWidth, boardHeight);
      case SpecialEffectType.megaBomb:
        _paintBomb(canvas, boardWidth, boardHeight, 5);
      case SpecialEffectType.multiBeam:
        _paintMultiBeam(canvas, boardWidth, boardHeight);
      case SpecialEffectType.boardClear:
        _paintBoardClear(canvas, boardWidth, boardHeight);
    }

    canvas.restore();
  }

  // ─── Cell center helper ───────────────────────────────────────────

  Offset _cellCenter(Position pos) {
    return Offset(
      pos.col * (cellSize + gap) + cellSize / 2,
      pos.row * (cellSize + gap) + cellSize / 2,
    );
  }

  // ─── ROCKET HORIZONTAL ────────────────────────────────────────────

  void _paintRocketHorizontal(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);
    final beamY = origin.dy;

    // Beam extends from origin outward in both directions
    final maxExtent = bw;
    final extent = maxExtent * Curves.easeOutCubic.transform(progress);

    // Glow background
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((100 * (1 - progress * 0.6)).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRect(
      Rect.fromLTRB(origin.dx - extent, beamY - 12, origin.dx + extent, beamY + 12),
      glowPaint,
    );

    // Bright center beam
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(origin.dx - extent, beamY),
        Offset(origin.dx + extent, beamY),
        [
          Colors.transparent,
          const Color(0xFF00E5FF),
          Colors.white,
          const Color(0xFF00E5FF),
          Colors.transparent,
        ],
        [0.0, 0.15, 0.5, 0.85, 1.0],
      )
      ..strokeWidth = 5 * (1 - progress * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(origin.dx - extent, beamY),
      Offset(origin.dx + extent, beamY),
      beamPaint,
    );

    // Core white line
    final corePaint = Paint()
      ..color = Colors.white.withAlpha((220 * (1 - progress * 0.5)).toInt())
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(origin.dx - extent, beamY),
      Offset(origin.dx + extent, beamY),
      corePaint,
    );

    // Trail particles along beam
    _paintBeamParticles(canvas, origin, true, extent, progress);
  }

  // ─── ROCKET VERTICAL ──────────────────────────────────────────────

  void _paintRocketVertical(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);
    final beamX = origin.dx;

    final maxExtent = bh;
    final extent = maxExtent * Curves.easeOutCubic.transform(progress);

    // Glow background
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((100 * (1 - progress * 0.6)).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRect(
      Rect.fromLTRB(beamX - 12, origin.dy - extent, beamX + 12, origin.dy + extent),
      glowPaint,
    );

    // Bright center beam
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(beamX, origin.dy - extent),
        Offset(beamX, origin.dy + extent),
        [
          Colors.transparent,
          const Color(0xFF00E5FF),
          Colors.white,
          const Color(0xFF00E5FF),
          Colors.transparent,
        ],
        [0.0, 0.15, 0.5, 0.85, 1.0],
      )
      ..strokeWidth = 5 * (1 - progress * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(beamX, origin.dy - extent),
      Offset(beamX, origin.dy + extent),
      beamPaint,
    );

    // Core white line
    final corePaint = Paint()
      ..color = Colors.white.withAlpha((220 * (1 - progress * 0.5)).toInt())
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(beamX, origin.dy - extent),
      Offset(beamX, origin.dy + extent),
      corePaint,
    );

    // Trail particles along beam
    _paintBeamParticles(canvas, origin, false, extent, progress);
  }

  /// Draw sparkle particles along a beam path.
  void _paintBeamParticles(
    Canvas canvas,
    Offset origin,
    bool horizontal,
    double extent,
    double progress,
  ) {
    // Use seeded random from origin so particles don't jitter on repaint
    final seed = effect.origin.row * 100 + effect.origin.col;
    final rng = Random(seed);

    final particleCount = 20;
    for (int i = 0; i < particleCount; i++) {
      final t = rng.nextDouble();
      if (t > progress * 1.2) continue; // Only show particles within beam reach

      final perpOffset = (rng.nextDouble() - 0.5) * 18;
      final particleAlpha = ((1.0 - (t - progress + 0.3).abs().clamp(0.0, 0.3) / 0.3) * 200).toInt().clamp(0, 200);
      final particleSize = 2.0 + rng.nextDouble() * 3;

      Offset pos;
      if (horizontal) {
        final dx = (t - 0.5) * 2 * extent;
        pos = Offset(origin.dx + dx, origin.dy + perpOffset);
      } else {
        final dy = (t - 0.5) * 2 * extent;
        pos = Offset(origin.dx + perpOffset, origin.dy + dy);
      }

      canvas.drawCircle(
        pos,
        particleSize,
        Paint()
          ..color = Colors.white.withAlpha(particleAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ─── BOMB BLAST ───────────────────────────────────────────────────

  void _paintBomb(Canvas canvas, double bw, double bh, int radius) {
    final progress = effect.progress;
    final center = _cellCenter(effect.origin);

    final maxRadius = cellSize * (radius / 2 + 0.5);
    final currentRadius = maxRadius * Curves.easeOutCubic.transform(progress);

    // Expanding shockwave ring (orange/red)
    final ringAlpha = (200 * (1 - progress)).toInt().clamp(0, 255);
    final ringWidth = 8.0 * (1 - progress * 0.7);
    final ringPaint = Paint()
      ..color = Color.fromARGB(ringAlpha, 255, 120, 30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, currentRadius, ringPaint);

    // Second inner ring (brighter)
    if (progress < 0.6) {
      final innerRingPaint = Paint()
        ..color = Color.fromARGB(
          (180 * (1 - progress / 0.6)).toInt().clamp(0, 255),
          255, 200, 80,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - progress / 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center, currentRadius * 0.7, innerRingPaint);
    }

    // Central flash (white)
    if (progress < 0.3) {
      final flashAlpha = (255 * (1 - progress / 0.3)).toInt().clamp(0, 255);
      final flashPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          currentRadius * 0.6,
          [
            Colors.white.withAlpha(flashAlpha),
            const Color(0xFFFF8C00).withAlpha((flashAlpha * 0.6).toInt()),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(center, currentRadius * 0.6, flashPaint);
    }

    // Spark particles flying outward
    final seed = effect.origin.row * 100 + effect.origin.col + 42;
    final rng = Random(seed);
    final sparkCount = radius == 5 ? 18 : 12;
    for (int i = 0; i < sparkCount; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final sparkSpeed = 0.8 + rng.nextDouble() * 0.4;
      final sparkDist = currentRadius * sparkSpeed;
      final sparkPos = Offset(
        center.dx + cos(angle) * sparkDist,
        center.dy + sin(angle) * sparkDist,
      );
      final sparkAlpha = (220 * (1 - progress)).toInt().clamp(0, 255);
      final sparkSize = (3.0 + rng.nextDouble() * 2) * (1 - progress * 0.5);

      // Spark with glow
      canvas.drawCircle(
        sparkPos,
        sparkSize * 2,
        Paint()
          ..color = const Color(0xFFFF6D00).withAlpha((sparkAlpha * 0.3).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        sparkPos,
        sparkSize,
        Paint()..color = Color.fromARGB(sparkAlpha, 255, 230, 100),
      );
    }

    // Screen shake feel: subtle radial lines
    if (progress < 0.4) {
      final lineAlpha = (80 * (1 - progress / 0.4)).toInt().clamp(0, 255);
      final linePaint = Paint()
        ..color = Colors.white.withAlpha(lineAlpha)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4 + progress * 0.5;
        final innerR = currentRadius * 0.3;
        final outerR = currentRadius * 1.1;
        canvas.drawLine(
          Offset(center.dx + cos(angle) * innerR, center.dy + sin(angle) * innerR),
          Offset(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR),
          linePaint,
        );
      }
    }
  }

  // ─── RAINBOW WAVE ─────────────────────────────────────────────────

  void _paintRainbow(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);

    // Draw colorful trails to each target
    final targets = effect.targets;
    for (int i = 0; i < targets.length; i++) {
      final target = _cellCenter(targets[i]);

      // Stagger trails: each one starts slightly after the previous
      final staggerDelay = i * 0.008; // small stagger per target
      final trailProgress = ((progress * 1.3 - staggerDelay)).clamp(0.0, 1.0);
      if (trailProgress <= 0) continue;

      // Color based on index cycling through jelly colors
      final colors = [
        const Color(0xFFFF4D80), // pink
        const Color(0xFFFF801A), // orange
        const Color(0xFFFFD91A), // yellow
        const Color(0xFF33D973), // green
        const Color(0xFF338CFF), // blue
        const Color(0xFF8B24DB), // purple
      ];
      final color = colors[i % colors.length];

      // Current trail head position
      final currentPos = Offset.lerp(origin, target, Curves.easeOutQuad.transform(trailProgress))!;

      // Trail line (fades as trail progresses)
      final trailAlpha = (180 * (1 - trailProgress * 0.4)).toInt().clamp(0, 255);
      final trailPaint = Paint()
        ..color = color.withAlpha(trailAlpha)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(origin, currentPos, trailPaint);

      // Glow along trail
      final glowPaint = Paint()
        ..color = color.withAlpha((trailAlpha * 0.3).toInt())
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(origin, currentPos, glowPaint);

      // Bright trail head (shooting star)
      final headSize = 5.0 * (1 - trailProgress * 0.3);
      canvas.drawCircle(
        currentPos,
        headSize + 4,
        Paint()
          ..color = color.withAlpha(80)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        currentPos,
        headSize,
        Paint()..color = Colors.white.withAlpha((220 * (1 - trailProgress * 0.3)).toInt()),
      );

      // Flash on target when trail arrives
      if (trailProgress > 0.85) {
        final flashT = (trailProgress - 0.85) / 0.15;
        final flashRadius = cellSize * 0.5 * Curves.easeOutCubic.transform(flashT);
        final flashAlpha = (160 * (1 - flashT)).toInt().clamp(0, 255);
        canvas.drawCircle(
          target,
          flashRadius,
          Paint()
            ..color = color.withAlpha(flashAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          target,
          flashRadius * 0.5,
          Paint()
            ..color = Colors.white.withAlpha((flashAlpha * 0.8).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // Origin burst glow
    if (progress < 0.3) {
      final burstAlpha = (180 * (1 - progress / 0.3)).toInt().clamp(0, 255);
      canvas.drawCircle(
        origin,
        cellSize * 0.6 * progress / 0.3,
        Paint()
          ..color = Colors.white.withAlpha(burstAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  // ─── LIGHTNING STRIKE ─────────────────────────────────────────────

  void _paintLightning(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);

    // Origin electric glow
    if (progress < 0.4) {
      final glowAlpha = (200 * (1 - progress / 0.4)).toInt().clamp(0, 255);
      canvas.drawCircle(
        origin,
        cellSize * 0.5,
        Paint()
          ..color = const Color(0xFFFFD700).withAlpha((glowAlpha * 0.4).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        origin,
        cellSize * 0.3,
        Paint()
          ..color = Colors.white.withAlpha((glowAlpha * 0.6).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Draw zigzag bolts to each target
    // Use seeded random so bolt paths are stable across repaints
    final seed = effect.origin.row * 1000 + effect.origin.col * 10 + 777;

    for (int i = 0; i < effect.targets.length; i++) {
      final target = _cellCenter(effect.targets[i]);

      // Stagger bolt appearance slightly
      final boltDelay = i * 0.03;
      final boltProgress = ((progress * 1.5 - boltDelay)).clamp(0.0, 1.0);
      if (boltProgress <= 0) continue;

      // Generate stable zigzag path
      final boltRng = Random(seed + i * 137);
      final path = Path()..moveTo(origin.dx, origin.dy);
      const steps = 6;
      for (int j = 1; j <= steps; j++) {
        final t = j / steps * boltProgress;
        final basePos = Offset.lerp(origin, target, t)!;
        if (j < steps) {
          final perpAngle = atan2(target.dy - origin.dy, target.dx - origin.dx) + pi / 2;
          final jitter = (boltRng.nextDouble() - 0.5) * 20;
          path.lineTo(
            basePos.dx + cos(perpAngle) * jitter,
            basePos.dy + sin(perpAngle) * jitter,
          );
        } else {
          path.lineTo(basePos.dx, basePos.dy);
        }
      }

      // Outer glow
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFD700).withAlpha((60 * (1 - progress * 0.5)).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Blue-white electric glow
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF80D8FF).withAlpha((100 * (1 - progress * 0.4)).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Bright bolt core
      final boltAlpha = (255 * (1 - progress * 0.5)).toInt().clamp(0, 255);
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.fromARGB(boltAlpha, 255, 255, 100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Impact flash at target
      if (boltProgress > 0.7) {
        final impactT = (boltProgress - 0.7) / 0.3;
        final impactAlpha = (220 * (1 - impactT)).toInt().clamp(0, 255);
        final impactRadius = cellSize * 0.35 * Curves.easeOutCubic.transform(impactT);
        canvas.drawCircle(
          target,
          impactRadius + 4,
          Paint()
            ..color = const Color(0xFFFFD700).withAlpha((impactAlpha * 0.4).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          target,
          impactRadius,
          Paint()..color = Colors.white.withAlpha(impactAlpha),
        );
      }
    }
  }

  // ─── MULTI BEAM (rocket + bomb combo) ─────────────────────────────

  void _paintMultiBeam(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);

    // 3 horizontal beams
    for (int dr = -1; dr <= 1; dr++) {
      final row = effect.origin.row + dr;
      if (row < 0 || row >= gridRows) continue;
      final beamY = row * (cellSize + gap) + cellSize / 2;
      final extent = bw * Curves.easeOutCubic.transform(progress);

      final alpha = (140 * (1 - progress * 0.5)).toInt().clamp(0, 255);
      // Glow
      canvas.drawRect(
        Rect.fromLTRB(origin.dx - extent, beamY - 8, origin.dx + extent, beamY + 8),
        Paint()
          ..color = const Color(0xFF00E5FF).withAlpha((alpha * 0.5).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Beam
      canvas.drawLine(
        Offset(origin.dx - extent, beamY),
        Offset(origin.dx + extent, beamY),
        Paint()
          ..color = Color.fromARGB(alpha, 0, 229, 255)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      // Core
      canvas.drawLine(
        Offset(origin.dx - extent, beamY),
        Offset(origin.dx + extent, beamY),
        Paint()
          ..color = Colors.white.withAlpha((alpha * 0.8).toInt())
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3 vertical beams
    for (int dc = -1; dc <= 1; dc++) {
      final col = effect.origin.col + dc;
      if (col < 0 || col >= gridCols) continue;
      final beamX = col * (cellSize + gap) + cellSize / 2;
      final extent = bh * Curves.easeOutCubic.transform(progress);

      final alpha = (140 * (1 - progress * 0.5)).toInt().clamp(0, 255);
      // Glow
      canvas.drawRect(
        Rect.fromLTRB(beamX - 8, origin.dy - extent, beamX + 8, origin.dy + extent),
        Paint()
          ..color = const Color(0xFF00E5FF).withAlpha((alpha * 0.5).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Beam
      canvas.drawLine(
        Offset(beamX, origin.dy - extent),
        Offset(beamX, origin.dy + extent),
        Paint()
          ..color = Color.fromARGB(alpha, 0, 229, 255)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      // Core
      canvas.drawLine(
        Offset(beamX, origin.dy - extent),
        Offset(beamX, origin.dy + extent),
        Paint()
          ..color = Colors.white.withAlpha((alpha * 0.8).toInt())
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Central burst
    if (progress < 0.3) {
      final burstAlpha = (200 * (1 - progress / 0.3)).toInt().clamp(0, 255);
      canvas.drawCircle(
        origin,
        cellSize * 0.8 * progress / 0.3,
        Paint()
          ..color = Colors.white.withAlpha(burstAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  // ─── BOARD CLEAR (rainbow + rainbow combo) ────────────────────────

  void _paintBoardClear(Canvas canvas, double bw, double bh) {
    final progress = effect.progress;
    final origin = _cellCenter(effect.origin);

    // Expanding rainbow gradient wave from center
    final maxRadius = sqrt(bw * bw + bh * bh) / 2 + cellSize;
    final radius = maxRadius * Curves.easeOutCubic.transform(progress);

    // Rainbow ring
    const rainbowColors = [
      Color(0xFFFF4D80),
      Color(0xFFFF801A),
      Color(0xFFFFD91A),
      Color(0xFF33D973),
      Color(0xFF338CFF),
      Color(0xFF8B24DB),
      Color(0xFFFF4D80),
    ];

    final ringWidth = 20.0 * (1 - progress * 0.5);
    final ringAlpha = (200 * (1 - progress * 0.7)).toInt().clamp(0, 255);

    // Outer rainbow ring
    for (int i = 0; i < rainbowColors.length - 1; i++) {
      final startAngle = i * (2 * pi / 6);
      final sweepAngle = 2 * pi / 6;
      final arcPaint = Paint()
        ..color = rainbowColors[i].withAlpha(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        startAngle + progress * 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // Inner white flash
    if (progress < 0.4) {
      final flashAlpha = (200 * (1 - progress / 0.4)).toInt().clamp(0, 255);
      canvas.drawCircle(
        origin,
        radius * 0.6,
        Paint()
          ..shader = ui.Gradient.radial(
            origin,
            radius * 0.6,
            [
              Colors.white.withAlpha(flashAlpha),
              Colors.white.withAlpha((flashAlpha * 0.3).toInt()),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // Sparkle particles scattered across the board
    final seed = 9999;
    final rng = Random(seed);
    for (int i = 0; i < 30; i++) {
      final px = rng.nextDouble() * bw;
      final py = rng.nextDouble() * bh;
      final distFromCenter = Offset(px - origin.dx, py - origin.dy).distance;

      // Only show particles that the wave has reached
      if (distFromCenter > radius) continue;

      final sparkle = ((radius - distFromCenter) / (cellSize * 2)).clamp(0.0, 1.0);
      final fadeOut = progress > 0.6 ? (1 - (progress - 0.6) / 0.4) : 1.0;
      final alpha = (180 * sparkle * fadeOut).toInt().clamp(0, 255);
      final color = rainbowColors[i % 6];
      final size = 2.0 + rng.nextDouble() * 3;

      canvas.drawCircle(
        Offset(px, py),
        size,
        Paint()
          ..color = color.withAlpha(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpecialEffectPainter old) => true;
}
