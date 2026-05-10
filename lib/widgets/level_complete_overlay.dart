import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';
import 'package:patpat_game/widgets/tropical/shell_strip.dart';
import 'package:patpat_game/widgets/tropical/tropical_frame.dart';
import 'package:patpat_game/widgets/tropical/red_ribbon_banner.dart';

/// Cinematic level-complete sequence — choreographed across ~5.5s on a
/// single master timeline, with continuous confetti + sun-ray loops in
/// the background. Phases land on stable musical beats so each piece of
/// the panel reveals itself with its own moment.
///
/// Phase budget (master t=0..1):
///   0.00–0.10  background dim
///   0.05–0.18  "TEBRİKLER!" title falls in + bounces
///   0.10–0.25  3 firework bursts at corners
///   0.20–0.35  Coco mascot slides in + halo bloom
///   0.30–0.50  3 stars descend, each with sparkle burst
///   0.45–0.60  Score count-up tween (0 → final)
///   0.55–0.70  Coin shower from both sides, settles to coin counter
///   0.65–0.80  Stat rows cascade in (Puan, Altın, Maks Kombo)
///   0.80–0.95  DEVAM button bounces in + pulses
///   0.95–1.00  Settle / hold
class LevelCompleteOverlay extends StatefulWidget {
  final int score;
  final int stars;
  final int coinsEarned;
  final int maxCombo;
  final VoidCallback onContinue;

  const LevelCompleteOverlay({
    super.key,
    required this.score,
    required this.stars,
    required this.coinsEarned,
    required this.maxCombo,
    required this.onContinue,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _haloCtrl;
  late final AnimationController _master;
  late final AnimationController _devamPulse;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5500))
      ..forward();
    _haloCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _master = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5500))
      ..forward();
    _devamPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    // Start the DEVAM pulse loop once it appears (~80% through master).
    _master.addListener(_maybeStartDevamPulse);
  }

  void _maybeStartDevamPulse() {
    if (_master.value >= 0.85 && !_devamPulse.isAnimating) {
      _devamPulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _master.removeListener(_maybeStartDevamPulse);
    _confettiCtrl.dispose();
    _haloCtrl.dispose();
    _master.dispose();
    _devamPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _master.value;
        // Phase windows.
        final dimT = (t / 0.10).clamp(0.0, 1.0);
        final titleT = ((t - 0.05) / 0.13).clamp(0.0, 1.0);
        final fireworkT = ((t - 0.10) / 0.15).clamp(0.0, 1.0);
        final mascotT = ((t - 0.20) / 0.15).clamp(0.0, 1.0);
        final starsT = ((t - 0.30) / 0.20).clamp(0.0, 1.0);
        final scoreT = ((t - 0.45) / 0.15).clamp(0.0, 1.0);
        final coinsT = ((t - 0.55) / 0.15).clamp(0.0, 1.0);
        final statsT = ((t - 0.65) / 0.15).clamp(0.0, 1.0);
        final buttonT = ((t - 0.80) / 0.15).clamp(0.0, 1.0);

        return Container(
          color: Colors.black.withAlpha((dimT * 200).toInt()),
          child: Stack(
            children: [
              // Continuous sun rays behind everything.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _haloCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _SunRaysPainter(
                      rotation: _haloCtrl.value * math.pi * 2,
                      opacity: dimT,
                    ),
                  ),
                ),
              ),
              // Animated tropical jungle frame (palm leaves sway + lights)
              Positioned.fill(
                child: Opacity(opacity: dimT, child: const TropicalFrame()),
              ),
              // Continuous confetti rain.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(progress: _confettiCtrl.value),
                  ),
                ),
              ),
              // 3 firework bursts at random corners (timed off master).
              if (fireworkT > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FireworksPainter(progress: fireworkT),
                    ),
                  ),
                ),
              // Coin shower — from both sides toward the coin row.
              if (coinsT > 0 && coinsT < 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CoinShowerPainter(progress: coinsT),
                    ),
                  ),
                ),
              // Big "TEBRİKLER!" banner at top of screen — flies in,
              // bounces, holds. Independent of the panel below.
              Positioned(
                top: MediaQuery.of(context).size.height * 0.07,
                left: 0,
                right: 0,
                child: _TitleBanner(progress: titleT),
              ),
              // Mockup-aligned layout: stars ABOVE mascot, big mascot
              // CENTER, stat panel BELOW with 3 rows + DEVAM button. The
              // panel container holds only the bottom block; mascot+stars
              // float above it for the "hero pose" feel.
              Padding(
                padding: const EdgeInsets.only(top: 175, bottom: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3 stars in an arc above mascot.
                    Opacity(
                      opacity: starsT > 0 ? 1.0 : 0.0,
                      child: SizedBox(
                        height: 90,
                        child: _StarsArea(stars: widget.stars, trigger: starsT > 0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Big Coco mascot center — slides in with halo bloom.
                    _MascotSlide(progress: mascotT),
                    const SizedBox(height: 12),
                    // Stat panel + DEVAM button. Panel scales in with master.
                    Transform.scale(
                      scale: 0.6 + 0.4 * Curves.elasticOut.transform(dimT),
                      child: Opacity(
                        opacity: dimT,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: IslandPanel(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StatRow(
                                    icon: Icons.bar_chart_rounded,
                                    label: 'Puan',
                                    value: ((widget.score *
                                                Curves.easeOutCubic
                                                    .transform(scoreT))
                                            .round())
                                        .toString(),
                                    color: TT.coral,
                                    appear: scoreT,
                                  ),
                                  const SizedBox(height: 6),
                                  _StatRow(
                                    icon: Icons.monetization_on_rounded,
                                    label: 'Altın',
                                    value: ((widget.coinsEarned *
                                                Curves.easeOutCubic
                                                    .transform(coinsT))
                                            .round())
                                        .toString(),
                                    color: TT.gold,
                                    appear: statsT.clamp(0.0, 1.0),
                                  ),
                                  const SizedBox(height: 6),
                                  _StatRow(
                                    icon: Icons.local_fire_department_rounded,
                                    label: 'Maks Kombo',
                                    value: 'x${widget.maxCombo}',
                                    color: TT.coralDark,
                                    appear: ((statsT - 0.3) / 0.7)
                                        .clamp(0.0, 1.0),
                                  ),
                                  const SizedBox(height: 16),
                                  _DevamButton(
                                    appear: buttonT,
                                    pulse: _devamPulse,
                                    onPressed: widget.onContinue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Big "TEBRİKLER!" banner ───────────────────────────────────────────────

class _TitleBanner extends StatelessWidget {
  final double progress;
  const _TitleBanner({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final dyT = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final dy = (1 - dyT) * -120; // slides down from above
    final scale = 0.4 + Curves.elasticOut.transform(t.clamp(0.0, 1.0)) * 0.6;
    final opacity = t.clamp(0, 1).toDouble();

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TEBRİKLER! red ribbon banner
                    const RedRibbonBanner(
                      text: 'TEBRİKLER!',
                      height: 70,
                      fontSize: 36,
                    ),
                    const SizedBox(height: 6),
                    // Subtitle "Harika! Bölümü başarıyla tamamladın!"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFCB3D).withValues(alpha: 0.6),
                          width: 1.4,
                        ),
                      ),
                      child: const Text(
                        'Harika! Bölümü başarıyla tamamladın!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFF1D9),
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Color(0xCC000000),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mascot slides in from right ──────────────────────────────────────────

class _MascotSlide extends StatelessWidget {
  final double progress;
  const _MascotSlide({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    final dx = (1 - eased) * 180;
    return Opacity(
      opacity: t.clamp(0.0, 1.0).toDouble(),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: const MascotView(
          pose: MascotPose.vip,
          height: 180,
          showHalo: true,
        ),
      ),
    );
  }
}

// ─── Star strip area with one-shot burst flash ─────────────────────────────

class _StarsArea extends StatelessWidget {
  final int stars;
  final bool trigger;
  const _StarsArea({required this.stars, required this.trigger});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Burst flash painter — only renders during trigger phase.
          if (trigger)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 850),
                builder: (_, v, __) => CustomPaint(
                  painter: _StarBurstPainter(progress: v),
                ),
              ),
            ),
          // ShellStrip handles its own per-star stagger via animate flag.
          ShellStrip(filled: stars, size: 50, animate: trigger),
        ],
      ),
    );
  }
}

// ─── Stat row with appear-from-left animation ──────────────────────────────

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double appear; // 0..1 visibility / slide-in factor

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.appear,
  });

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(appear.clamp(0.0, 1.0));
    return Transform.translate(
      offset: Offset((1 - eased) * -36, 0),
      child: Opacity(
        opacity: appear.clamp(0.0, 1.0).toDouble(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: TT.sandLight.withAlpha(220),
            border: Border.all(color: TT.bamboo, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color.lerp(color, Colors.white, 0.2)!, color],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: 6, spreadRadius: -1)],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: TT.bodyMedium.copyWith(color: TT.driftWoodDark, fontWeight: FontWeight.w800)),
              ),
              Text(value, style: TT.titleMedium.copyWith(color: TT.goldDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DEVAM button — slides up + pulses once visible ────────────────────────

class _DevamButton extends StatelessWidget {
  final double appear;
  final AnimationController pulse;
  final VoidCallback onPressed;

  const _DevamButton({
    required this.appear,
    required this.pulse,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final eased = Curves.elasticOut.transform(appear.clamp(0.0, 1.0));
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final pulseScale = 1.0 + 0.04 * pulse.value;
        return Transform.translate(
          offset: Offset(0, (1 - eased) * 40),
          child: Opacity(
            opacity: appear.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 0.7 + 0.3 * eased.clamp(0.0, 1.0) * pulseScale,
              child: IslandButton(
                text: 'DEVAM',
                icon: Icons.arrow_forward_rounded,
                color: IslandButtonColor.palm,
                size: IslandButtonSize.large,
                fullWidth: true,
                onPressed: appear > 0.5 ? onPressed : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Painters ──────────────────────────────────────────────────────────────

/// Confetti rain — colorful particles falling for the full 5.5s window.
/// Phase doubled vs the original 3s pass to spread the population.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFFFFD91A),
    Color(0xFF338CFF),
    Color(0xFF33D973),
    Color(0xFFFF4D80),
    Color(0xFFFF801A),
    Color(0xFFE63946),
    Color(0xFFFFE89C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final yStart = -30 - rng.nextDouble() * 200;
      final speed = 0.6 + rng.nextDouble() * 0.6;
      // Slow the fall so confetti spans 5.5s nicely.
      final y = yStart + progress * size.height * 1.4 * speed;
      if (y < -30 || y > size.height + 50) continue;
      final color = _colors[i % _colors.length];
      final s = 4.0 + rng.nextDouble() * 5;
      final rot = rng.nextDouble() * math.pi * 2 + progress * math.pi * 4;
      final swayX = math.sin(progress * math.pi * 3 + i.toDouble()) * 14;
      canvas.save();
      canvas.translate(x + swayX, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 1.4),
        Paint()..color = color.withAlpha(220),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

/// Rotating gold sun rays behind the panel — fades in with the dim phase.
class _SunRaysPainter extends CustomPainter {
  final double rotation;
  final double opacity;
  _SunRaysPainter({required this.rotation, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.max(size.width, size.height);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi * 2 / 12);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE89C).withAlpha((90 * opacity).toInt()),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, maxR * 1.2, 60));
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.05) * maxR, math.sin(angle - 0.05) * maxR)
        ..lineTo(math.cos(angle + 0.05) * maxR, math.sin(angle + 0.05) * maxR)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}

/// 3 staggered fireworks at corner positions — burst, expand, fade.
class _FireworksPainter extends CustomPainter {
  final double progress;
  _FireworksPainter({required this.progress});

  static const _colors = [
    Color(0xFFFFD91A),
    Color(0xFF338CFF),
    Color(0xFF33D973),
    Color(0xFFFF4D80),
    Color(0xFFFFE89C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Three fireworks, staggered 0.0/0.30/0.55 of the firework window.
    final positions = [
      Offset(size.width * 0.18, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.40),
      Offset(size.width * 0.32, size.height * 0.62),
    ];
    final delays = [0.0, 0.30, 0.55];
    for (int idx = 0; idx < 3; idx++) {
      final localT = ((progress - delays[idx]) / 0.4).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      _drawFirework(canvas, positions[idx], localT, idx);
    }
  }

  void _drawFirework(Canvas canvas, Offset center, double t, int seed) {
    final rng = math.Random(seed * 91);
    final maxR = 90.0;
    final r = maxR * Curves.easeOutCubic.transform(t);
    final color = _colors[seed % _colors.length];
    final particleAlpha = ((1 - t) * 240).toInt().clamp(0, 240);

    // 16 radial spark particles.
    const n = 16;
    for (int i = 0; i < n; i++) {
      final angle = i * (math.pi * 2 / n) + rng.nextDouble() * 0.2;
      final dist = r * (0.7 + rng.nextDouble() * 0.4);
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist + t * 25; // slight gravity
      // Trail.
      canvas.drawCircle(
        Offset(px, py),
        3.0 - t * 1.5,
        Paint()
          ..color = color.withAlpha(particleAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // Bright core.
      canvas.drawCircle(
        Offset(px, py),
        1.5 - t * 0.7,
        Paint()..color = Colors.white.withAlpha(particleAlpha),
      );
    }
    // Initial flash.
    if (t < 0.25) {
      final flashAlpha = ((1 - t / 0.25) * 200).toInt().clamp(0, 200);
      canvas.drawCircle(
        center,
        12,
        Paint()
          ..color = Colors.white.withAlpha(flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress;
}

/// Coin shower — rains gold coin disks from both sides toward the panel,
/// settling in by the end of the phase.
class _CoinShowerPainter extends CustomPainter {
  final double progress;
  _CoinShowerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final cx = size.width / 2;
    final cy = size.height / 2;
    const n = 18;
    for (int i = 0; i < n; i++) {
      final fromLeft = i.isEven;
      final delay = (i / n) * 0.5;
      final localT = ((progress - delay) / 0.5).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final eased = Curves.easeInCubic.transform(localT);
      final startX = fromLeft ? -30.0 : size.width + 30;
      final startY = cy + (rng.nextDouble() - 0.5) * size.height * 0.4;
      final endX = cx + (rng.nextDouble() - 0.5) * 80;
      final endY = cy + 60 + (rng.nextDouble() - 0.5) * 40;
      // Curved path: start → mid (above target) → end.
      final t = eased;
      final midX = (startX + endX) / 2;
      final midY = startY - 100 - rng.nextDouble() * 80;
      final px = (1 - t) * (1 - t) * startX +
          2 * (1 - t) * t * midX +
          t * t * endX;
      final py = (1 - t) * (1 - t) * startY +
          2 * (1 - t) * t * midY +
          t * t * endY;
      // Coin.
      final spin = localT * math.pi * 6;
      final scale = 0.6 + 0.4 * math.sin(spin);
      canvas.save();
      canvas.translate(px, py);
      canvas.scale(scale.abs(), 1.0);
      // Outer gold ring.
      canvas.drawCircle(
        Offset.zero,
        9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE89C),
              const Color(0xFFE8A317),
            ],
          ).createShader(const Rect.fromLTWH(-9, -9, 18, 18)),
      );
      // Inner shine.
      canvas.drawCircle(
        const Offset(-2, -3),
        2.5,
        Paint()..color = Colors.white.withAlpha(200),
      );
      // Black "$" shape (simplified to a vertical line + curl).
      canvas.drawLine(
        const Offset(0, -4),
        const Offset(0, 4),
        Paint()
          ..color = const Color(0xFF7A4F12)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoinShowerPainter old) =>
      old.progress != progress;
}

/// One-shot radial gold burst behind the star strip.
class _StarBurstPainter extends CustomPainter {
  final double progress;
  _StarBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final t = progress.clamp(0.0, 1.0);
    final alpha = ((1 - t) * 220).toInt().clamp(0, 220);
    canvas.drawCircle(
      c,
      30 + 40 * t,
      Paint()
        ..color = const Color(0xFFFFE89C).withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final rayPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..color = const Color(0xFFFFE89C).withAlpha(alpha);
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi * 2 / 8);
      final inner = 30 + 25 * t;
      final outer = inner + 35 + 50 * t;
      final p1 = Offset(c.dx + math.cos(angle) * inner, c.dy + math.sin(angle) * inner);
      final p2 = Offset(c.dx + math.cos(angle) * outer, c.dy + math.sin(angle) * outer);
      canvas.drawLine(p1, p2, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter old) => old.progress != progress;
}
