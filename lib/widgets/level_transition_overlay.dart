import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

/// Animated transition between levels — appears AFTER LevelCompleteOverlay's
/// DEVAM is pressed, before navigating back to the map. Auto-finishes after
/// the animation completes.
class LevelTransitionOverlay extends StatefulWidget {
  final int nextLevel;
  final VoidCallback onFinished;

  const LevelTransitionOverlay({
    super.key,
    required this.nextLevel,
    required this.onFinished,
  });

  @override
  State<LevelTransitionOverlay> createState() => _LevelTransitionOverlayState();
}

class _LevelTransitionOverlayState extends State<LevelTransitionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward().then((_) {
        if (mounted) widget.onFinished();
      });
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = GameRegion.forLevel(widget.nextLevel);
    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        final t = _master.value;
        // Total 1800ms — short level→level snap.
        // Phase 0..0.25: BG fade in
        final bgOp = (t / 0.25).clamp(0.0, 1.0);
        // Phase 0.1..0.5: BÖLÜM number scale in
        final numT = ((t - 0.1) / 0.4).clamp(0.0, 1.0);
        final numEase = Curves.elasticOut.transform(numT);
        // Phase 0.4..0.7: mascot fly in from right
        final mascotT = ((t - 0.4) / 0.3).clamp(0.0, 1.0);
        final mascotEase = Curves.easeOutBack.transform(mascotT);
        // Phase 0.6..0.85: region pill slide up
        final pillT = ((t - 0.6) / 0.25).clamp(0.0, 1.0);
        // Phase 0.85..1.0: fade out
        final fadeOut = ((t - 0.85) / 0.15).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // BG — deep mystical gradient
            Container(
              color: Colors.black.withAlpha((bgOp * 240).toInt()),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: bgOp,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.4,
                          colors: [
                            const Color(0xFF1A4A35).withAlpha(180),
                            const Color(0xFF051810).withAlpha(220),
                            const Color(0xFF000000).withAlpha(255),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Sun rays rotating
                  Center(
                    child: AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _shimmerCtrl.value * math.pi * 2,
                        child: CustomPaint(
                          size: const Size(800, 800),
                          painter: _RaysPainter(opacity: bgOp),
                        ),
                      ),
                    ),
                  ),
                  // Ascending sparkle particles drifting upward.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _master,
                      builder: (_, __) => CustomPaint(
                        painter: _AscendSparkPainter(progress: _master.value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Outgoing fade (covers whole screen with black)
            if (fadeOut > 0)
              Container(color: Colors.black.withAlpha((fadeOut * 255).toInt())),
            // Centered content
            Opacity(
              opacity: 1 - fadeOut,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BÖLÜM label
                    Opacity(
                      opacity: numT,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: TT.coralButtonGradient,
                          border: Border.all(color: TT.goldShine, width: 2),
                          boxShadow: [
                            BoxShadow(color: TT.coral.withAlpha(180), blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          'BÖLÜM',
                          style: TT.titleMedium.copyWith(
                            color: TT.sandLight,
                            letterSpacing: 2,
                            fontSize: 14,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Big animated number with pulsating gold halo ring
                    SizedBox(
                      width: 260,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // pulsating ring behind number
                          AnimatedBuilder(
                            animation: _shimmerCtrl,
                            builder: (_, __) {
                              final ringT = _shimmerCtrl.value;
                              final ringScale = 0.85 + 0.18 * ringT;
                              final ringAlpha = ((1 - ringT) * 220).toInt().clamp(0, 220);
                              return Transform.scale(
                                scale: ringScale * (0.4 + numEase * 0.6),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: TT.goldShine.withAlpha(ringAlpha), width: 4),
                                    boxShadow: [
                                      BoxShadow(color: TT.gold.withAlpha((ringAlpha * 0.6).toInt()), blurRadius: 24, spreadRadius: 4),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Transform.scale(
                            scale: 0.3 + numEase * 0.7,
                            child: ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
                                stops: [0.0, 0.4, 0.8, 1.0],
                              ).createShader(rect),
                              child: Text(
                                '${widget.nextLevel}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 140,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  height: 1,
                                  shadows: [
                                    Shadow(color: Color(0xCC000000), blurRadius: 16, offset: Offset(0, 8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Subtitle line — appears with the number
                    Opacity(
                      opacity: numT,
                      child: Text(
                        'YENİ MACERA!',
                        style: TextStyle(
                          color: TT.goldShine,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.5,
                          shadows: [
                            Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                            Shadow(color: TT.gold.withAlpha(160), blurRadius: 12, offset: Offset.zero),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Region pill slide up
                    Opacity(
                      opacity: pillT,
                      child: Transform.translate(
                        offset: Offset(0, (1 - pillT) * 30),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [TT.goldShine, TT.gold, TT.goldDeep],
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: TT.driftPanelGradient,
                              border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    region.pillAsset,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.terrain, color: TT.goldShine, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  region.displayName,
                                  style: TT.titleMedium.copyWith(
                                    color: TT.sandLight,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Mascot fly in from right
                    Transform.translate(
                      offset: Offset((1 - mascotEase) * 200, 0),
                      child: Opacity(
                        opacity: mascotEase,
                        child: const MascotView(
                          pose: MascotPose.victory,
                          height: 120,
                          showHalo: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RaysPainter extends CustomPainter {
  final double opacity;
  _RaysPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.max(size.width, size.height);
    canvas.translate(c.dx, c.dy);
    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi * 2 / 12);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE89C).withAlpha((80 * opacity).toInt()),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, r * 1.2, 60));
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.04) * r, math.sin(angle - 0.04) * r)
        ..lineTo(math.cos(angle + 0.04) * r, math.sin(angle + 0.04) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.opacity != opacity;
}

/// Ascending sparkle particles — small gold dots drifting upward through
/// the transition overlay for a "magical reveal" feel.
class _AscendSparkPainter extends CustomPainter {
  final double progress;
  _AscendSparkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (int i = 0; i < 22; i++) {
      final lane = rng.nextDouble();
      final x = lane * size.width + math.sin(progress * math.pi * 2 + i) * 18;
      final yStart = size.height + 40 + rng.nextDouble() * 80;
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final y = yStart - progress * size.height * 1.4 * speed;
      if (y < -30 || y > size.height + 80) continue;
      final r = 1.5 + rng.nextDouble() * 2.4;
      final tw = (math.sin(progress * 12 + i) + 1) / 2;
      final alpha = (90 + 130 * tw).toInt().clamp(0, 220);
      // halo
      canvas.drawCircle(
        Offset(x, y),
        r * 3,
        Paint()
          ..color = const Color(0xFFFFE89C).withAlpha((alpha * 0.5).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // core
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color(0xFFFFFAD8).withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AscendSparkPainter old) => true;
}
