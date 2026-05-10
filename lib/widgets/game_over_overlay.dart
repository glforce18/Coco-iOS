import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/coco_banner_ad.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

class GameOverOverlay extends StatefulWidget {
  final int score;
  final VoidCallback onRetry;
  final VoidCallback onQuit;
  final VoidCallback? onWatchAd;
  final bool showAdButton;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRetry,
    required this.onQuit,
    this.onWatchAd,
    this.showAdButton = false,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _leavesCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _scoreCtrl;

  @override
  void initState() {
    super.initState();
    _leavesCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() {
    _leavesCtrl.dispose();
    _pulseCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Falling leaves particles — melancholy mood.
          AnimatedBuilder(
            animation: _leavesCtrl,
            builder: (_, __) => CustomPaint(painter: _FallingLeavesPainter(t: _leavesCtrl.value)),
          ),
          // Soft red vignette pulsing slowly.
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final t = _pulseCtrl.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      TT.coralDark.withAlpha((40 + 30 * t).toInt()),
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: IslandPanel(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MascotView(pose: MascotPose.sad, height: 100, bobbing: false),
                        const SizedBox(height: 6),
                        // OYUN BİTTİ with subtle red glow shimmer
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [TT.coralLight, TT.coral, TT.coralDark],
                          ).createShader(rect),
                          child: Text(
                            'OYUN BİTTİ',
                            style: TT.titleLarge.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 3)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pes etme — bir denesem!',
                          style: TT.bodySmall.copyWith(
                            color: TT.driftWoodDark,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Animated score count-up
                        AnimatedBuilder(
                          animation: _scoreCtrl,
                          builder: (_, __) {
                            final t = Curves.easeOutCubic.transform(_scoreCtrl.value);
                            final shown = (widget.score * t).round();
                            return Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [TT.goldShine, TT.gold, TT.goldDeep],
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 8, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFFE6B0), Color(0xFFC79A52)],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: TT.coralDark, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$shown',
                                      style: TT.titleLarge.copyWith(
                                        color: TT.driftWoodDark,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(color: Colors.white.withAlpha(160), blurRadius: 1, offset: const Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'puan',
                                      style: TT.bodySmall.copyWith(
                                        color: TT.driftWoodDark.withAlpha(220),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        // Pulsating retry button (primary action)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) {
                            final t = _pulseCtrl.value;
                            return Transform.scale(scale: 0.98 + 0.04 * t, child: child);
                          },
                          child: IslandButton(
                            text: 'Tekrar Dene',
                            icon: Icons.refresh_rounded,
                            color: IslandButtonColor.palm,
                            size: IslandButtonSize.large,
                            fullWidth: true,
                            onPressed: widget.onRetry,
                          ),
                        ),
                        if (widget.showAdButton) ...[
                          const SizedBox(height: 8),
                          IslandButton(
                            text: 'Reklam İzle +3 Hamle',
                            icon: Icons.play_circle_filled_rounded,
                            color: IslandButtonColor.lagoon,
                            size: IslandButtonSize.medium,
                            fullWidth: true,
                            onPressed: widget.onWatchAd,
                          ),
                        ],
                        const SizedBox(height: 8),
                        IslandButton(
                          text: 'Çık',
                          icon: Icons.close_rounded,
                          color: IslandButtonColor.coral,
                          size: IslandButtonSize.medium,
                          fullWidth: true,
                          onPressed: widget.onQuit,
                        ),
                        const SizedBox(height: 12),
                        // Banner ad — rendered as a small chip at the
                        // bottom of the panel. Auto-hides when ads are
                        // disabled / unavailable.
                        const Center(child: CocoBannerAd()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tropical leaves drifting downward — autumn-mood particles.
class _FallingLeavesPainter extends CustomPainter {
  final double t;
  _FallingLeavesPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(91);
    for (int i = 0; i < 14; i++) {
      final lane = rng.nextDouble();
      final x = lane * size.width + math.sin((t * 2 * math.pi) + i) * 30;
      final yStart = -40 - rng.nextDouble() * 60;
      final speed = 0.3 + rng.nextDouble() * 0.6;
      final y = (yStart + (t * size.height * 1.2 * speed) + i * 25) % (size.height + 100);
      final rot = t * math.pi * 2 + i;
      final scale = 0.8 + rng.nextDouble() * 0.6;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.scale(scale);
      // simple leaf path: ovaloid with notch
      final paint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF7A4A2E) : const Color(0xFF9B6940)).withAlpha(140);
      final path = Path()
        ..moveTo(0, -10)
        ..quadraticBezierTo(8, -2, 0, 10)
        ..quadraticBezierTo(-8, -2, 0, -10)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter old) => true;
}
