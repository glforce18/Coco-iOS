import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

/// 6.5-second cinematic that plays when the player crosses from one
/// region into a new one (every 20 levels). The tropical archipelago
/// world map fills the screen, the camera focuses the just-completed
/// island with a "TAMAMLANDI!" check, then Coco flies along a curved
/// path to the next island while the golden trail lights up segment-
/// by-segment. Lands with a sparkle burst + region name plaque.
class WorldMapFlyoverOverlay extends StatefulWidget {
  final GameRegion completedRegion;
  final GameRegion newRegion;
  final int startingLevel;
  final VoidCallback onFinished;

  const WorldMapFlyoverOverlay({
    super.key,
    required this.completedRegion,
    required this.newRegion,
    required this.startingLevel,
    required this.onFinished,
  });

  @override
  State<WorldMapFlyoverOverlay> createState() => _WorldMapFlyoverOverlayState();
}

class _WorldMapFlyoverOverlayState extends State<WorldMapFlyoverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _master;

  /// Approximate (x%, y%) positions of the 12 islands inside the world
  /// map background. Tweak as the asset evolves.
  static const Map<int, ({double x, double y})> _islandPos = {
    1: (x: 0.22, y: 0.38),
    2: (x: 0.38, y: 0.30),
    3: (x: 0.50, y: 0.22),
    4: (x: 0.65, y: 0.28),
    5: (x: 0.18, y: 0.50),
    6: (x: 0.45, y: 0.50),
    7: (x: 0.62, y: 0.50),
    8: (x: 0.80, y: 0.35),
    9: (x: 0.80, y: 0.60),
    10: (x: 0.60, y: 0.70),
    11: (x: 0.40, y: 0.78),
    12: (x: 0.20, y: 0.78),
  };

  int get _completedRegionIndex =>
      GameRegion.values.indexOf(widget.completedRegion) + 1;
  int get _newRegionIndex => GameRegion.values.indexOf(widget.newRegion) + 1;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..forward().then((_) {
        if (mounted) widget.onFinished();
      });
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  Offset _islandPxOffset(int index, Size size) {
    final p = _islandPos[index] ?? (x: 0.5, y: 0.5);
    return Offset(p.x * size.width, p.y * size.height);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fromPos = _islandPxOffset(_completedRegionIndex, size);
    final toPos = _islandPxOffset(_newRegionIndex, size);

    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _master.value;
        // Phase windows.
        final dimT = (t / 0.10).clamp(0.0, 1.0);
        final mapT = ((t - 0.05) / 0.15).clamp(0.0, 1.0);
        final completeT = ((t - 0.20) / 0.18).clamp(0.0, 1.0);
        final flightT = ((t - 0.30) / 0.40).clamp(0.0, 1.0);
        final landT = ((t - 0.72) / 0.18).clamp(0.0, 1.0);
        final plaqueT = ((t - 0.80) / 0.15).clamp(0.0, 1.0);
        final fadeOutT = ((t - 0.94) / 0.06).clamp(0.0, 1.0);

        // Coco flies along a Bezier curve from completed to new island.
        final ctrl = Offset(
          (fromPos.dx + toPos.dx) / 2,
          math.min(fromPos.dy, toPos.dy) - 80,
        );
        final cocoPos = _bezier(fromPos, ctrl, toPos, flightT);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: World map background fades in with subtle zoom-in.
            Opacity(
              opacity: mapT,
              child: Transform.scale(
                scale: 1.0 + (1 - Curves.easeOutCubic.transform(mapT)) * 0.1,
                child: Image.asset(
                  'assets/tropical/backgrounds/world_map.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: TT.oceanDeep),
                ),
              ),
            ),
            // Layer 2: Initial dark veil that opens like a pinhole.
            if (dimT < 1)
              Container(
                color: Colors.black.withAlpha(
                  ((1 - Curves.easeOutCubic.transform(dimT)) * 230).toInt(),
                ),
              ),
            // (No custom path overlay — the world map background already
            // renders its own bridges/connectors between islands.)
            // Layer 4: "TAMAMLANDI!" check pop-up over the just-finished island.
            if (completeT > 0 && completeT < 1)
              Positioned(
                left: fromPos.dx - 80,
                top: fromPos.dy - 60,
                width: 160,
                height: 60,
                child: _CompletedBadge(progress: completeT),
              ),
            // Layer 5: Coco mascot flies along the curve.
            if (flightT > 0 && flightT < 1)
              Positioned(
                left: cocoPos.dx - 50,
                top: cocoPos.dy - 50,
                width: 100,
                height: 100,
                child: const MascotView(
                  pose: MascotPose.victory,
                  height: 100,
                  showHalo: true,
                  bobbing: false,
                ),
              ),
            // Layer 6: Sparkle burst on the new island when Coco lands.
            if (landT > 0)
              Positioned(
                left: toPos.dx - 80,
                top: toPos.dy - 80,
                width: 160,
                height: 160,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LandingBurstPainter(progress: landT),
                  ),
                ),
              ),
            // Layer 7: New region name plaque slides in at center.
            if (plaqueT > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.18,
                child: Center(
                  child: _RegionPlaque(
                    region: widget.newRegion,
                    level: widget.startingLevel,
                    progress: plaqueT,
                  ),
                ),
              ),
            // Layer 8: White flash + fade out at the very end.
            if (fadeOutT > 0)
              Container(
                  color: Colors.white.withAlpha((fadeOutT * 255).toInt())),
          ],
        );
      },
    );
  }

  static Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }
}

// ─── Sub-components ────────────────────────────────────────────────────────

class _CompletedBadge extends StatelessWidget {
  final double progress;
  const _CompletedBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(t);
    final opacity = (t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15)).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.palmLight, TT.palm, TT.palmDark],
            ),
            border: Border.all(color: TT.goldShine, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 10, offset: const Offset(0, 3)),
              BoxShadow(color: TT.palm.withAlpha(180), blurRadius: 18, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'TAMAMLANDI!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionPlaque extends StatelessWidget {
  final GameRegion region;
  final int level;
  final double progress;

  const _RegionPlaque({
    required this.region,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final eased = Curves.elasticOut.transform(t);
    final dy = (1 - eased) * 50;

    return Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(
        opacity: t,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.goldShine, TT.gold, TT.goldDeep],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(220), blurRadius: 18, offset: const Offset(0, 6)),
              BoxShadow(color: TT.gold.withAlpha(180), blurRadius: 28, spreadRadius: 2),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.driftWoodDark, Color(0xFF3D2712)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YENİ ADA',
                  style: TextStyle(
                    color: TT.coralLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [Shadow(color: Colors.black.withAlpha(220), blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  region.displayName.toUpperCase(),
                  style: TT.titleLarge.copyWith(
                    color: TT.goldShine,
                    fontSize: 22,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black.withAlpha(230), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bölüm $level\'den başlıyor',
                  style: TextStyle(
                    color: TT.sandLight.withAlpha(220),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingBurstPainter extends CustomPainter {
  final double progress;
  _LandingBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final t = progress;
    final r = (size.width / 2) * (0.4 + t * 0.6);
    final alpha = ((1 - t) * 230).toInt().clamp(0, 230);
    // Soft halo
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFFFE89C).withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // 12 spike rays
    final spikePaint = Paint()
      ..color = const Color(0xFFFFFAD8).withAlpha(alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (int i = 0; i < 12; i++) {
      final ang = i * (math.pi * 2 / 12) + t * 0.5;
      final inner = r * 0.55;
      final outer = r * (0.95 + t * 0.05);
      canvas.drawLine(
        Offset(c.dx + math.cos(ang) * inner, c.dy + math.sin(ang) * inner),
        Offset(c.dx + math.cos(ang) * outer, c.dy + math.sin(ang) * outer),
        spikePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LandingBurstPainter old) =>
      old.progress != progress;
}
