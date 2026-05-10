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
  hammerSmash,   // booster: hammer falls onto a cell + impact burst
  colorSweep,    // booster: color blast sweep across all cells of one color
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
      case SpecialEffectType.hammerSmash:
        _paintHammerSmash(canvas);
      case SpecialEffectType.colorSweep:
        _paintColorSweep(canvas, boardWidth, boardHeight);
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

  /// Draw sparkle particles along a beam path + bright rocket "heads" at
  /// both tips so the beam reads as two rockets ripping outward, not just
  /// a glowing line.
  void _paintBeamParticles(
    Canvas canvas,
    Offset origin,
    bool horizontal,
    double extent,
    double progress,
  ) {
    // Use seeded random from origin so particles don't jitter on repaint.
    final seed = effect.origin.row * 100 + effect.origin.col;
    final rng = Random(seed);

    // Doubled density (was 20) → thicker exhaust trail.
    const particleCount = 40;
    for (int i = 0; i < particleCount; i++) {
      final t = rng.nextDouble();
      if (t > progress * 1.2) continue; // Only show particles within beam reach.

      final perpOffset = (rng.nextDouble() - 0.5) * 22;
      final particleAlpha = ((1.0 - (t - progress + 0.3).abs().clamp(0.0, 0.3) / 0.3) * 220).toInt().clamp(0, 220);
      final particleSize = 1.8 + rng.nextDouble() * 3.2;

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

    // Bright rocket "heads" at each tip — fades quickly past the leading edge.
    final headAlpha = ((1 - progress) * 230).toInt().clamp(0, 230);
    final headPaint = Paint()
      ..color = const Color(0xFFFFFAD8).withAlpha(headAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final headCorePaint = Paint()
      ..color = Colors.white.withAlpha(headAlpha);
    final tipL = horizontal
        ? Offset(origin.dx - extent, origin.dy)
        : Offset(origin.dx, origin.dy - extent);
    final tipR = horizontal
        ? Offset(origin.dx + extent, origin.dy)
        : Offset(origin.dx, origin.dy + extent);
    canvas.drawCircle(tipL, 14, headPaint);
    canvas.drawCircle(tipR, 14, headPaint);
    canvas.drawCircle(tipL, 5, headCorePaint);
    canvas.drawCircle(tipR, 5, headCorePaint);
  }

  // ─── BOMB BLAST (boosted intensity) ───────────────────────────────

  void _paintBomb(Canvas canvas, double bw, double bh, int radius) {
    final progress = effect.progress;
    final center = _cellCenter(effect.origin);

    final maxRadius = cellSize * (radius / 2 + 0.5);
    final currentRadius = maxRadius * Curves.easeOutCubic.transform(progress);

    // Full-screen white flash on impact (first 12% of animation).
    if (progress < 0.12) {
      final flashOp = (1 - progress / 0.12);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, bw, bh),
        Paint()..color = Colors.white.withAlpha((180 * flashOp).toInt().clamp(0, 220)),
      );
    }

    // FOUR layered shockwave rings (was 2) — staggered timing for "boom-boom" feel.
    for (int i = 0; i < 4; i++) {
      final stagger = i * 0.08;
      final ringT = ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
      if (ringT <= 0) continue;
      final r = maxRadius * Curves.easeOutCubic.transform(ringT) * (0.6 + i * 0.18);
      final alpha = ((1 - ringT) * (200 - i * 30)).toInt().clamp(0, 220);
      final w = (10.0 - i * 2) * (1 - ringT * 0.6);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Color.fromARGB(
            alpha,
            255,
            120 + i * 25,
            30 + i * 30,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = w.clamp(1.0, 12.0)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 - i.toDouble()),
      );
    }

    // Second inner bright ring (white-yellow) for extra punch.
    if (progress < 0.6) {
      final innerRingPaint = Paint()
        ..color = Color.fromARGB(
          (220 * (1 - progress / 0.6)).toInt().clamp(0, 255),
          255, 230, 120,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - progress / 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
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

    // Spark particles flying outward — more particles + colored variations.
    final seed = effect.origin.row * 100 + effect.origin.col + 42;
    final rng = Random(seed);
    final sparkCount = radius == 5 ? 36 : 24;  // was 18/12
    for (int i = 0; i < sparkCount; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final sparkSpeed = 0.6 + rng.nextDouble() * 0.7;
      final sparkDist = currentRadius * sparkSpeed * (1 + progress * 0.5);
      final sparkPos = Offset(
        center.dx + cos(angle) * sparkDist,
        center.dy + sin(angle) * sparkDist,
      );
      final sparkAlpha = (240 * (1 - progress)).toInt().clamp(0, 255);
      final sparkSize = (3.5 + rng.nextDouble() * 2.5) * (1 - progress * 0.4);

      // Vary colors: yellow, orange, red mix
      final colorPick = i % 3;
      final coreColor = colorPick == 0
          ? const Color(0xFFFFEE99)
          : colorPick == 1
              ? const Color(0xFFFF8C20)
              : const Color(0xFFFF4520);

      // Outer glow
      canvas.drawCircle(
        sparkPos,
        sparkSize * 2.6,
        Paint()
          ..color = coreColor.withAlpha((sparkAlpha * 0.35).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Mid glow
      canvas.drawCircle(
        sparkPos,
        sparkSize * 1.4,
        Paint()
          ..color = coreColor.withAlpha((sparkAlpha * 0.7).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // White-hot core
      canvas.drawCircle(
        sparkPos,
        sparkSize * 0.6,
        Paint()..color = Colors.white.withAlpha(sparkAlpha),
      );
    }

    // Smoke debris (grey particles, slower, fade slowly)
    if (progress > 0.15) {
      final smokeT = (progress - 0.15) / 0.85;
      for (int i = 0; i < 8; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = currentRadius * (0.3 + rng.nextDouble() * 0.5) * (1 + smokeT);
        final smokePos = Offset(
          center.dx + cos(angle) * dist,
          center.dy + sin(angle) * dist - smokeT * cellSize,  // rises up
        );
        final smokeAlpha = ((1 - smokeT) * 100).toInt().clamp(0, 100);
        canvas.drawCircle(
          smokePos,
          cellSize * 0.18 * (1 + smokeT * 0.5),
          Paint()
            ..color = const Color(0xFF666666).withAlpha(smokeAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
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

  // ─── HAMMER SMASH (booster) ────────────────────────────────────────
  // 0.0 → 0.6: hammer rotates in from top-left, lands on origin cell
  // 0.6 → 1.0: impact ring + crack burst + cell flash
  void _paintHammerSmash(Canvas canvas) {
    final t = effect.progress;
    final c = _cellCenter(effect.origin);
    // Phase split
    final approach = (t / 0.6).clamp(0.0, 1.0).toDouble();
    final impact = ((t - 0.6) / 0.4).clamp(0.0, 1.0).toDouble();

    if (impact < 1.0) {
      // ── Approach phase: hammer drops in from top-left of cell ──
      final ease = Curves.easeIn.transform(approach);
      // Start offset 80px up-left, end at cell centre
      final hx = c.dx - 80 + 80 * ease;
      final hy = c.dy - 90 + 90 * ease;
      // Rotation: -1.2 rad → 0 (swing down)
      final rot = -1.2 + 1.2 * ease;

      canvas.save();
      canvas.translate(hx, hy);
      canvas.rotate(rot);
      _drawHammerIcon(canvas, cellSize * 0.7);
      canvas.restore();

      // Motion trail (small radial dots behind hammer)
      final trailPaint = Paint()
        ..color = const Color(0xFFFFD56F).withValues(alpha: 0.5 * (1 - approach))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(hx - 20, hy - 20), 14, trailPaint);
    }

    if (impact > 0) {
      // ── Impact phase: glow flash + radial crack ─────────────────────
      final ringR = cellSize * (0.6 + impact * 0.9);
      final ringAlpha = ((1 - impact) * 220).toInt();
      // White flash
      final flashPaint = Paint()
        ..color = Colors.white.withAlpha(ringAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(c, ringR * 0.65, flashPaint);

      // Gold ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + impact * 4
        ..color = const Color(0xFFFFD56F).withAlpha(ringAlpha);
      canvas.drawCircle(c, ringR, ringPaint);

      // 8 radial spikes (crack burst)
      final spikePaint = Paint()
        ..color = const Color(0xFFFFE89C).withAlpha(((1 - impact) * 255).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * pi * 2;
        final r1 = cellSize * 0.45;
        final r2 = cellSize * (0.8 + impact * 0.5);
        canvas.drawLine(
          Offset(c.dx + cos(angle) * r1, c.dy + sin(angle) * r1),
          Offset(c.dx + cos(angle) * r2, c.dy + sin(angle) * r2),
          spikePaint,
        );
      }

      // Settled hammer on cell (fading)
      if (impact < 0.55) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(impact * 0.4); // slight rebound rotate
        _drawHammerIcon(canvas, cellSize * 0.7 * (1 - impact * 0.3));
        canvas.restore();
      }
    }
  }

  void _drawHammerIcon(Canvas canvas, double size) {
    // Wooden handle
    final handlePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-size * 0.5, 0),
        Offset(size * 0.5, 0),
        const [Color(0xFF8B5A2B), Color(0xFF5C3A1A), Color(0xFF8B5A2B)],
      );
    final handleRect = Rect.fromCenter(
      center: const Offset(0, 0),
      width: size * 0.85,
      height: size * 0.18,
    );
    final handleRRect = RRect.fromRectAndRadius(handleRect, Radius.circular(size * 0.05));
    canvas.drawRRect(handleRRect, handlePaint);
    canvas.drawRRect(
      handleRRect,
      Paint()
        ..color = const Color(0xFF2A1810).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Metal head — block with gradient
    final headPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-size * 0.18, -size * 0.3),
        Offset(size * 0.18, size * 0.3),
        const [Color(0xFFE0E0E0), Color(0xFF6B6B6B), Color(0xFF3A3A3A)],
      );
    final headRect = Rect.fromCenter(
      center: Offset(-size * 0.32, 0),
      width: size * 0.36,
      height: size * 0.48,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(size * 0.06));
    canvas.drawRRect(headRRect, headPaint);
    canvas.drawRRect(
      headRRect,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Specular highlight on hammer head
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(-size * 0.38, -size * 0.12),
        width: size * 0.06,
        height: size * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  // ─── COLOR SWEEP (booster) ─────────────────────────────────────────
  // Radial color wave radiating from origin cell across the whole board,
  // tinted with the target color. All cells in the wave-front flash.
  void _paintColorSweep(Canvas canvas, double bw, double bh) {
    final t = effect.progress;
    final origin = _cellCenter(effect.origin);
    final maxR = sqrt(bw * bw + bh * bh) * 0.55;
    final r = maxR * Curves.easeOutCubic.transform(t.clamp(0.0, 1.0).toDouble());

    final color = _colorFor(effect.targetColor);

    // Outer ring
    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.55 * (1 - t * 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 + 4 * (1 - t),
    );
    // Inner glow gradient
    canvas.drawCircle(
      origin,
      r * 0.95,
      Paint()
        ..shader = ui.Gradient.radial(
          origin,
          r,
          [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.45 * (1 - t)),
            color.withValues(alpha: 0),
          ],
          [0.0, 0.7, 1.0],
        ),
    );
    // Sparkle dots on the ring
    final sparkPaint = Paint()..color = Colors.white.withValues(alpha: 0.9 * (1 - t));
    for (int i = 0; i < 18; i++) {
      final angle = (i / 18) * pi * 2 + t * 1.2;
      final sx = origin.dx + cos(angle) * r;
      final sy = origin.dy + sin(angle) * r;
      canvas.drawCircle(Offset(sx, sy), 3 + 2 * (1 - t), sparkPaint);
    }

    // Tint targeted cells with color burst at their positions
    for (final pos in effect.targets) {
      final cc = _cellCenter(pos);
      final dist = (cc - origin).distance;
      final reached = (r >= dist) ? 1.0 : 0.0;
      if (reached > 0) {
        // Phase since wave passed
        final since = ((r - dist) / maxR).clamp(0.0, 1.0).toDouble();
        final alpha = (0.65 * (1 - since)).clamp(0.0, 1.0);
        canvas.drawCircle(
          cc,
          cellSize * 0.55 * (1 + since * 0.4),
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  Color _colorFor(JellyType? t) {
    switch (t) {
      case JellyType.blue:   return const Color(0xFF4A8FE7);
      case JellyType.green:  return const Color(0xFF3CA84F);
      case JellyType.orange: return const Color(0xFFFF8E2E);
      case JellyType.pink:   return const Color(0xFFFF6FA5);
      case JellyType.purple: return const Color(0xFFA060E7);
      case JellyType.yellow: return const Color(0xFFFFCB3D);
      default:               return const Color(0xFFE85A5A);
    }
  }

  @override
  bool shouldRepaint(covariant _SpecialEffectPainter old) => true;
}
