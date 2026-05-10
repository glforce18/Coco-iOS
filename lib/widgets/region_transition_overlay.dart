import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

/// 5.5-second cinematic shown when the player crosses into a NEW REGION
/// (every 20 levels — 21, 41, 61, …, 221, 241). The previous level's
/// finish flow runs first, THEN this overlay replaces the level transition
/// for the very first level of the new region.
///
/// Each region uses its own full-bleed background image, so the cinematic
/// is visually unique across all 12 islands.
///
/// Phase budget (master t=0..1):
///   0.00–0.10  fade IN: dark veil + radial pinhole opens
///   0.05–0.25  region BG fades in + parallax zoom
///   0.10–0.30  golden ribbon scrolls across screen ("YENİ ADA")
///   0.20–0.45  region name plaque slides up + scale-bounce
///   0.30–0.55  Coco mascot flies in from right + waves
///   0.40–0.70  3 sequential firework bursts at sea/sky
///   0.55–0.80  "BÖLÜM 21" big number elastic in, with halo ring
///   0.75–0.90  bottom CTA chip "Maceraya başla!" appears
///   0.90–1.00  full-screen white flash, fade out
class RegionTransitionOverlay extends StatefulWidget {
  final GameRegion region;
  final int startingLevel;
  final VoidCallback onFinished;

  const RegionTransitionOverlay({
    super.key,
    required this.region,
    required this.startingLevel,
    required this.onFinished,
  });

  @override
  State<RegionTransitionOverlay> createState() =>
      _RegionTransitionOverlayState();
}

class _RegionTransitionOverlayState extends State<RegionTransitionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..forward().then((_) {
        if (mounted) widget.onFinished();
      });
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _shimmer]),
      builder: (_, __) {
        final t = _master.value;
        // Phase windows.
        final veilT = (t / 0.10).clamp(0.0, 1.0);
        final bgT = ((t - 0.05) / 0.20).clamp(0.0, 1.0);
        final ribbonT = ((t - 0.10) / 0.20).clamp(0.0, 1.0);
        final nameT = ((t - 0.20) / 0.25).clamp(0.0, 1.0);
        final mascotT = ((t - 0.30) / 0.25).clamp(0.0, 1.0);
        final fireworkT = ((t - 0.40) / 0.30).clamp(0.0, 1.0);
        final numberT = ((t - 0.55) / 0.25).clamp(0.0, 1.0);
        final ctaT = ((t - 0.75) / 0.15).clamp(0.0, 1.0);
        final fadeOutT = ((t - 0.90) / 0.10).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ─── Layer 1: Region background image with subtle zoom-in. ───
            Opacity(
              opacity: bgT,
              child: Transform.scale(
                scale: 1.0 + (1 - Curves.easeOutCubic.transform(bgT)) * 0.12,
                child: Image.asset(
                  widget.region.backgroundAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: TT.oceanDeep),
                ),
              ),
            ),
            // Dark vignette over BG so foreground reads.
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha((180 * bgT).toInt()),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            // ─── Layer 2: Initial dark veil with radial pinhole. ───
            if (veilT < 1)
              Container(
                color: Colors.black.withAlpha(
                    ((1 - Curves.easeOutCubic.transform(veilT)) * 240).toInt()),
              ),
            // ─── Layer 3: Sweeping golden ribbon across upper third. ───
            if (ribbonT > 0 && ribbonT < 1)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.10,
                left: 0,
                right: 0,
                child: _GoldenRibbon(progress: ribbonT, label: 'YENİ ADA'),
              ),
            // ─── Layer 4: Region name plaque (center-top). ───
            Positioned(
              top: MediaQuery.of(context).size.height * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: _RegionNamePlaque(
                  region: widget.region,
                  progress: nameT,
                  shimmer: _shimmer.value,
                ),
              ),
            ),
            // ─── Layer 5: Coco mascot flies in. ───
            Positioned(
              top: MediaQuery.of(context).size.height * 0.40,
              right: 0,
              left: 0,
              child: _MascotFlyIn(progress: mascotT),
            ),
            // ─── Layer 6: 3 sequential fireworks. ───
            if (fireworkT > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FireworksPainter(progress: fireworkT),
                  ),
                ),
              ),
            // ─── Layer 7: Big "BÖLÜM N" number. ───
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.20,
              left: 0,
              right: 0,
              child: _BigLevelNumber(
                level: widget.startingLevel,
                progress: numberT,
                shimmer: _shimmer.value,
              ),
            ),
            // ─── Layer 8: Bottom CTA chip. ───
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.10,
              left: 0,
              right: 0,
              child: _CtaChip(progress: ctaT),
            ),
            // ─── Layer 9: Final white flash + fade out. ───
            if (fadeOutT > 0)
              Container(color: Colors.white.withAlpha((fadeOutT * 255).toInt())),
          ],
        );
      },
    );
  }
}

// ─── Golden ribbon ─────────────────────────────────────────────────────────

class _GoldenRibbon extends StatelessWidget {
  final double progress;
  final String label;
  const _GoldenRibbon({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final dx = (1 - Curves.easeOutCubic.transform(t)) * -300;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Opacity(
          opacity: t.clamp(0, 1).toDouble(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.coralLight, TT.coral, TT.coralDark],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: TT.goldShine,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Region name plaque ────────────────────────────────────────────────────

class _RegionNamePlaque extends StatelessWidget {
  final GameRegion region;
  final double progress;
  final double shimmer;
  const _RegionNamePlaque({
    required this.region,
    required this.progress,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final eased = Curves.elasticOut.transform(t);
    final dy = (1 - eased) * 40;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: t.toDouble(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.gold, TT.goldDeep],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(190), blurRadius: 18, offset: const Offset(0, 6)),
                BoxShadow(color: TT.gold.withAlpha((140 + 80 * shimmer).toInt()), blurRadius: 30, spreadRadius: 4),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1A), Color(0xFF3D2712)],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Region pill icon if available.
                  ClipOval(
                    child: Image.asset(
                      region.pillAsset,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.terrain_rounded,
                        color: TT.goldShine,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      region.displayName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TT.titleLarge.copyWith(
                        color: TT.goldShine,
                        fontSize: 22,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(230), blurRadius: 6, offset: const Offset(0, 2)),
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
    );
  }
}

// ─── Mascot fly-in ─────────────────────────────────────────────────────────

class _MascotFlyIn extends StatelessWidget {
  final double progress;
  const _MascotFlyIn({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final eased = Curves.easeOutBack.transform(t);
    final dx = (1 - eased) * 250;
    final bob = math.sin(progress * math.pi * 2.5) * 6;
    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: Offset(dx, bob),
          child: Opacity(
            opacity: t.toDouble(),
            child: const MascotView(
              pose: MascotPose.victory,
              height: 160,
              showHalo: true,
              bobbing: false,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Big "BÖLÜM N" number ──────────────────────────────────────────────────

class _BigLevelNumber extends StatelessWidget {
  final int level;
  final double progress;
  final double shimmer;
  const _BigLevelNumber({
    required this.level,
    required this.progress,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final eased = Curves.elasticOut.transform(t);
    final scale = 0.3 + 0.7 * eased;
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: t.toDouble(),
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing gold halo behind the number.
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TT.gold.withAlpha((140 + 80 * shimmer).toInt()),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BÖLÜM',
                      style: TextStyle(
                        color: TT.goldShine,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
                      ).createShader(rect),
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 110,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 1,
                          shadows: [
                            Shadow(color: Color(0xCC000000), blurRadius: 14, offset: Offset(0, 6)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom CTA chip ───────────────────────────────────────────────────────

class _CtaChip extends StatelessWidget {
  final double progress;
  const _CtaChip({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final dy = (1 - t) * 30;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: t.toDouble(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.palmLight, TT.palm, TT.palmDark],
                ),
                border: Border.all(color: TT.goldShine, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 12, offset: const Offset(0, 4)),
                  BoxShadow(color: TT.palm.withAlpha(180), blurRadius: 18, spreadRadius: 2),
                ],
              ),
              child: Text(
                'Maceraya başla!',
                style: TextStyle(
                  color: TT.sandLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
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

// ─── 3 staggered fireworks ─────────────────────────────────────────────────

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
    final positions = [
      Offset(size.width * 0.18, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.36),
      Offset(size.width * 0.30, size.height * 0.55),
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
    const maxR = 110.0;
    final r = maxR * Curves.easeOutCubic.transform(t);
    final color = _colors[seed % _colors.length];
    final particleAlpha = ((1 - t) * 240).toInt().clamp(0, 240);

    const n = 18;
    for (int i = 0; i < n; i++) {
      final angle = i * (math.pi * 2 / n) + rng.nextDouble() * 0.2;
      final dist = r * (0.7 + rng.nextDouble() * 0.4);
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist + t * 25;
      canvas.drawCircle(
        Offset(px, py),
        3.5 - t * 1.6,
        Paint()
          ..color = color.withAlpha(particleAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        Offset(px, py),
        1.6 - t * 0.8,
        Paint()..color = Colors.white.withAlpha(particleAlpha),
      );
    }
    if (t < 0.25) {
      final flashAlpha = ((1 - t / 0.25) * 220).toInt().clamp(0, 220);
      canvas.drawCircle(
        center,
        14,
        Paint()
          ..color = Colors.white.withAlpha(flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress;
}
