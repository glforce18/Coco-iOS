import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative tropical frame overlay — animated palm leaves at L+R edges,
/// string lights at top with warm pulsing glow, optional hibiscus accents.
/// Place ABOVE content but BELOW the top bar / navigation in a Stack.
///
/// Matches reference screenshots (Yuva / Profile / Adalar / Tebrikler) —
/// "yapraklar sallansin, deniz aksin" — leaves sway gently with wind.
class TropicalFrame extends StatefulWidget {
  final bool showStringLights;
  final bool showHibiscus;
  final bool showLeaves;
  final double leafScale;
  final double topPadding; // string lights start below status bar

  const TropicalFrame({
    super.key,
    this.showStringLights = true,
    this.showHibiscus = true,
    this.showLeaves = true,
    this.leafScale = 1.0,
    this.topPadding = 0,
  });

  @override
  State<TropicalFrame> createState() => _TropicalFrameState();
}

class _TropicalFrameState extends State<TropicalFrame>
    with TickerProviderStateMixin {
  late final AnimationController _swayCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _swayCtrl = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swayCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // === Top: String lights row ===
          if (widget.showStringLights)
            Positioned(
              top: widget.topPadding,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (context, child) => CustomPaint(
                  size: const Size.fromHeight(64),
                  painter: _StringLightsPainter(glow: _glowCtrl.value),
                ),
              ),
            ),

          // === Left palm leaves cluster (sways) ===
          if (widget.showLeaves && widget.leafScale > 0)
          Positioned(
            left: -28 * widget.leafScale,
            top: widget.topPadding + 24,
            bottom: 80,
            width: 150 * widget.leafScale,
            child: AnimatedBuilder(
              animation: _swayCtrl,
              builder: (context, child) {
                final t = _swayCtrl.value;
                final wave = math.sin(t * math.pi * 2);
                return Transform.rotate(
                  angle: wave * 0.04, // ±~2.3°
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: _LeafCluster(
                side: _LeafSide.left,
                showHibiscus: widget.showHibiscus,
              ),
            ),
          ),

          // === Right palm leaves cluster (sways opposite) ===
          if (widget.showLeaves && widget.leafScale > 0)
          Positioned(
            right: -28 * widget.leafScale,
            top: widget.topPadding + 24,
            bottom: 80,
            width: 150 * widget.leafScale,
            child: AnimatedBuilder(
              animation: _swayCtrl,
              builder: (context, child) {
                final t = _swayCtrl.value;
                final wave = math.sin((t + 0.5) * math.pi * 2);
                return Transform.rotate(
                  angle: wave * 0.04,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: _LeafCluster(
                side: _LeafSide.right,
                showHibiscus: widget.showHibiscus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeafSide { left, right }

class _LeafCluster extends StatelessWidget {
  final _LeafSide side;
  final bool showHibiscus;
  const _LeafCluster({required this.side, required this.showHibiscus});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main palm leaves PNG (mirror for right side)
        Positioned.fill(
          child: Transform(
            alignment: Alignment.center,
            transform: side == _LeafSide.right
                ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                : Matrix4.identity(),
            child: Image.asset(
              'assets/tropical/decor/decor_palm_leaves.png',
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        // Secondary leaves lower (overlapping for fuller look)
        Positioned(
          left: side == _LeafSide.left ? -16 : null,
          right: side == _LeafSide.right ? -16 : null,
          bottom: 80,
          width: 130,
          height: 140,
          child: Transform(
            alignment: Alignment.center,
            transform: side == _LeafSide.right
                ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                : Matrix4.identity(),
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(
                'assets/tropical/decor/decor_palm_leaves.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        // Hibiscus flower (red tropical accent)
        if (showHibiscus)
          Positioned(
            left: side == _LeafSide.left ? 24 : null,
            right: side == _LeafSide.right ? 24 : null,
            top: 180,
            child: const _Hibiscus(size: 56),
          ),
        if (showHibiscus)
          Positioned(
            left: side == _LeafSide.left ? 38 : null,
            right: side == _LeafSide.right ? 38 : null,
            bottom: 140,
            child: const _Hibiscus(size: 48),
          ),
      ],
    );
  }
}

/// Custom-painted hibiscus flower (red 5 petals + yellow center stamen).
class _Hibiscus extends StatelessWidget {
  final double size;
  const _Hibiscus({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HibiscusPainter()),
    );
  }
}

class _HibiscusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;

    // 5 petals — radial layout
    final petalPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFD32F2F), Color(0xFF8B0000)],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final petalOutline = Paint()
      ..color = const Color(0x60000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 - math.pi / 2;
      final petalCx = cx + math.cos(angle) * r * 0.45;
      final petalCy = cy + math.sin(angle) * r * 0.45;
      canvas.save();
      canvas.translate(petalCx, petalCy);
      canvas.rotate(angle + math.pi / 2);
      final petalRect = Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.85,
        height: r * 1.35,
      );
      canvas.drawOval(petalRect, petalPaint);
      canvas.drawOval(petalRect, petalOutline);
      canvas.restore();
    }

    // Center stamen (yellow with red dot)
    final stamenPaint = Paint()..color = const Color(0xFFFFDA44);
    canvas.drawCircle(Offset(cx, cy), r * 0.28, stamenPaint);
    final centerPaint = Paint()..color = const Color(0xFFB8860B);
    canvas.drawCircle(Offset(cx, cy), r * 0.12, centerPaint);

    // Yellow stamen dots radial
    final dotPaint = Paint()..color = const Color(0xFFFFB80F);
    for (int i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      final px = cx + math.cos(a) * r * 0.22;
      final py = cy + math.sin(a) * r * 0.22;
      canvas.drawCircle(Offset(px, py), r * 0.06, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Top-of-screen warm fairy string lights — bulbs hanging from a dark wire.
class _StringLightsPainter extends CustomPainter {
  final double glow;
  _StringLightsPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wirePaint = Paint()
      ..color = const Color(0xFF2A1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Wire path — gentle U curve
    final path = Path();
    path.moveTo(-8, 18);
    path.cubicTo(
      w * 0.25, h * 0.55,
      w * 0.75, h * 0.55,
      w + 8, 18,
    );
    canvas.drawPath(path, wirePaint);

    // Bulbs along curve
    const bulbCount = 9;
    for (int i = 0; i < bulbCount; i++) {
      final t = i / (bulbCount - 1);
      final p = _cubicPoint(t, w, h);
      _drawBulb(canvas, p, glow, i);
    }
  }

  Offset _cubicPoint(double t, double w, double h) {
    // Quadratic-ish cubic eval
    final p0 = Offset(-8, 18);
    final p1 = Offset(w * 0.25, h * 0.55);
    final p2 = Offset(w * 0.75, h * 0.55);
    final p3 = Offset(w + 8, 18);
    final u = 1 - t;
    final x = u * u * u * p0.dx +
        3 * u * u * t * p1.dx +
        3 * u * t * t * p2.dx +
        t * t * t * p3.dx;
    final y = u * u * u * p0.dy +
        3 * u * u * t * p1.dy +
        3 * u * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(x, y);
  }

  void _drawBulb(Canvas canvas, Offset center, double glow, int idx) {
    // Stagger glow per bulb so they don't pulse in unison
    final phase = (glow + idx * 0.18) % 1.0;
    final brightness = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));

    // Halo (warm yellow blur)
    final haloPaint = Paint()
      ..color = const Color(0xFFFFD060).withValues(alpha: 0.4 * brightness)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(0, 4), 14, haloPaint);

    // Bulb body
    final bulbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xFFFFFAA0), const Color(0xFFFFD56F), 1 - brightness)!,
          const Color(0xFFFFA830),
          const Color(0xFFC97A1A),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center.translate(0, 4), radius: 7));
    canvas.drawCircle(center.translate(0, 4), 6, bulbPaint);

    // Highlight dot
    canvas.drawCircle(
      center.translate(-2, 1),
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * brightness),
    );

    // Socket (small brown)
    final socketPaint = Paint()..color = const Color(0xFF3A2410);
    canvas.drawCircle(center.translate(0, -1), 2.5, socketPaint);
  }

  @override
  bool shouldRepaint(_StringLightsPainter old) => old.glow != glow;
}
