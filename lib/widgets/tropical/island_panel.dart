import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Tropical Adventure — premium 3D modal/popup container.
///
/// Layered structure (outer → inner):
/// 1. Drop shadow + warm gold glow
/// 2. Treasure-gold metallic frame (7-stop highlight gradient)
/// 3. Inner driftwood line
/// 4. Sand parchment surface (warm cream gradient)
/// 5. Optional sun-rays + sparkles overlay
/// 6. Child content with padding
class IslandPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool showSparkles;
  final double frameWidth;
  final IslandPanelTheme theme;

  const IslandPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.showSparkles = true,
    this.frameWidth = 4,
    this.theme = IslandPanelTheme.sand,
  });

  @override
  Widget build(BuildContext context) {
    final innerGradient = switch (theme) {
      IslandPanelTheme.sand => TT.sandPanelGradient,
      IslandPanelTheme.driftwood => TT.driftPanelGradient,
      IslandPanelTheme.ocean => TT.oceanDepthGradient,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + frameWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(170),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: TT.gold.withAlpha(120),
            blurRadius: 40,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius + frameWidth),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TT.goldShine,
              TT.goldBright,
              TT.gold,
              TT.goldDeep,
              TT.gold,
              TT.goldBright,
              TT.goldShine,
            ],
            stops: [0.0, 0.18, 0.34, 0.5, 0.66, 0.82, 1.0],
          ),
        ),
        padding: EdgeInsets.all(frameWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius + 1),
            color: TT.driftWoodDark,
          ),
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: innerGradient),
              child: Stack(
                children: [
                  if (showSparkles)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SunraysSparkPainter(theme: theme),
                        ),
                      ),
                    ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum IslandPanelTheme { sand, driftwood, ocean }

class _SunraysSparkPainter extends CustomPainter {
  final IslandPanelTheme theme;
  _SunraysSparkPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == IslandPanelTheme.ocean) {
      // light caustics on ocean theme
      final caustic = Paint()
        ..color = Colors.white.withAlpha(28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      for (int i = 0; i < 12; i++) {
        final x = (i * 47.3) % size.width;
        final y = ((i * 71.1) % size.height);
        canvas.drawCircle(Offset(x, y), 18 + (i % 3) * 6, caustic);
      }
      return;
    }
    // Sand / driftwood themes — warm sun glints
    final glow = Paint()
      ..color = TT.goldShine.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.12), 60, glow);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 40, glow);

    final spark = Paint()
      ..color = TT.goldShine.withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    final coords = [
      [0.15, 0.08],
      [0.88, 0.14],
      [0.22, 0.32],
      [0.78, 0.45],
      [0.45, 0.20],
      [0.62, 0.08],
      [0.05, 0.55],
      [0.95, 0.62],
      [0.30, 0.90],
      [0.70, 0.92],
    ];
    for (final c in coords) {
      final x = c[0] * size.width;
      final y = c[1] * size.height;
      canvas.drawCircle(Offset(x, y), 3, spark);
      canvas.drawCircle(Offset(x, y), 1.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
