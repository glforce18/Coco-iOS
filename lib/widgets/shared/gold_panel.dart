import 'dart:math';
import 'package:flutter/material.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Royal Match-style modal/popup container.
///
/// Layered structure (outer → inner):
/// 1. Drop shadow + gold glow (BoxShadow)
/// 2. Gold metallic frame (5-stop gradient simulating metal sheen)
/// 3. Inner dark line (subtle separation)
/// 4. Purple panel gradient (top light → bottom dark)
/// 5. Optional starry sparkle background
/// 6. Child content with padding
///
/// Used by [LevelStartPopup], [LevelCompleteOverlay], [NoLivesPopup], etc.
class GoldPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool showSparkles;
  final double frameWidth;

  const GoldPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.showSparkles = true,
    this.frameWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Layer 1: outer shadow + gold glow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + frameWidth),
        boxShadow: [
          // Drop shadow (depth)
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          // Gold ambient glow
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(100),
            blurRadius: 32,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        // Layer 2: gold metallic frame
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius + frameWidth),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameColors.goldFrameBright,
              GameColors.goldHighlight,
              GameColors.goldFrameMid,
              GameColors.goldFrameDeep,
              GameColors.goldFrameMid,
              GameColors.goldHighlight,
              GameColors.goldFrameBright,
            ],
            stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
          ),
        ),
        padding: EdgeInsets.all(frameWidth),
        child: Container(
          // Layer 3: inner dark separator line (1px)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius + 1),
            color: GameColors.panelPurpleDark,
          ),
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: DecoratedBox(
              // Layer 4: purple panel gradient
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GameColors.panelPurpleLight,
                    GameColors.panelPurple,
                    GameColors.panelPurpleDark,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Layer 5: starry sparkles (decorative)
                  if (showSparkles)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _StarryBgPainter(),
                        ),
                      ),
                    ),
                  // Layer 6: child content
                  Padding(
                    padding: padding,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static (non-animated) starry background for [GoldPanel].
///
/// Deterministic seeded RNG so the same panel renders identically every frame
/// (no perf cost, no jitter). Draws ~40 small stars + 8 brighter sparkles.
class _StarryBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);

    // Layer 1: dim background stars (90, very subtle white)
    final dimPaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.4;
      canvas.drawCircle(Offset(x, y), r, dimPaint);
    }

    // Layer 2: medium stars (30, soft gold)
    final medPaint = Paint()
      ..color = GameColors.goldHighlight.withAlpha(110)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.0 + rng.nextDouble() * 1.4;
      canvas.drawCircle(Offset(x, y), r, medPaint);
    }

    // Layer 3: bright cross-star sparkles (16, bright gold with rays)
    final sparkPaint = Paint()
      ..color = GameColors.goldHighlight.withAlpha(220)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    final sparkCorePaint = Paint()..color = Colors.white.withAlpha(220);
    for (int i = 0; i < 16; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.6 + rng.nextDouble() * 1.8;
      // Halo
      canvas.drawCircle(Offset(x, y), r * 1.6, sparkPaint);
      // Bright core
      canvas.drawCircle(Offset(x, y), r * 0.6, sparkCorePaint);

      // 4-point cross star (sharper rays)
      final rayPaint = Paint()
        ..color = GameColors.goldHighlight.withAlpha(160)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(x - r * 3, y), Offset(x + r * 3, y), rayPaint);
      canvas.drawLine(
          Offset(x, y - r * 3), Offset(x, y + r * 3), rayPaint);
      // Diagonal rays (shorter)
      final diagPaint = Paint()
        ..color = GameColors.goldHighlight.withAlpha(100)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - r * 1.6, y - r * 1.6),
          Offset(x + r * 1.6, y + r * 1.6), diagPaint);
      canvas.drawLine(Offset(x - r * 1.6, y + r * 1.6),
          Offset(x + r * 1.6, y - r * 1.6), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
