import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Tropical 0-3 star rating strip with golden gradient stars and a proper
/// staggered "land" animation: each filled star lands ~280ms apart, with a
/// momentary scale-pop + radial gold sparkle burst as it touches down.
class ShellStrip extends StatefulWidget {
  final int filled; // 0..3
  final double size;
  final bool animate;
  const ShellStrip({
    super.key,
    required this.filled,
    this.size = 24,
    this.animate = false,
  });

  @override
  State<ShellStrip> createState() => _ShellStripState();
}

class _ShellStripState extends State<ShellStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Total length covers all 3 stars: each star takes ~360ms, 200ms apart.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant ShellStrip old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = widget.animate ? _ctrl.value : 1.0;
        final stars = <Widget>[];
        for (int i = 0; i < 3; i++) {
          stars.add(_StarSlot(
            filled: i < widget.filled,
            size: widget.size,
            index: i,
            globalProgress: t,
            animate: widget.animate,
          ));
          if (i < 2) stars.add(SizedBox(width: widget.size * 0.18));
        }
        return Row(mainAxisSize: MainAxisSize.min, children: stars);
      },
    );
  }
}

class _StarSlot extends StatelessWidget {
  final bool filled;
  final double size;
  final int index;
  final double globalProgress;
  final bool animate;

  const _StarSlot({
    required this.filled,
    required this.size,
    required this.index,
    required this.globalProgress,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    // Per-star stagger: starts at delay, runs for ~0.35 of master timeline.
    final delay = 0.16 * index; // 0.0, 0.16, 0.32 — first half of timeline
    const span = 0.35;
    final raw = ((globalProgress - delay) / span).clamp(0.0, 1.0);
    final eased = Curves.elasticOut.transform(raw);
    // Pop overshoots 1.18 then settles to 1.0.
    final scale = (filled && animate) ? eased.clamp(0.0, 1.18) : 1.0;
    // Burst alpha — a single brief flash centered on the star landing
    // moment (raw ≈ 0.4..0.7 of the star's local span).
    final burstT = (raw - 0.25).clamp(0.0, 1.0) / 0.6;
    final burstAlpha = filled && animate
        ? (math.sin(burstT.clamp(0, 1) * math.pi) * 220).toInt().clamp(0, 220)
        : 0;

    return SizedBox(
      width: size * 1.4,
      height: size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (burstAlpha > 0)
            CustomPaint(
              size: Size.square(size * 1.4),
              painter: _StarBurstPainter(progress: burstT, alpha: burstAlpha),
            ),
          Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: (animate && filled) ? raw.clamp(0.2, 1.0).toDouble() : 1.0,
              child: CustomPaint(
                size: Size.square(size),
                painter: _StarPainter(filled: filled),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBurstPainter extends CustomPainter {
  final double progress;
  final int alpha;
  _StarBurstPainter({required this.progress, required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || alpha <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    // Soft halo
    final r = size.width * 0.5 * (0.55 + progress * 0.55);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE89C).withAlpha(alpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // 8 short radial spikes
    final spikePaint = Paint()
      ..color = const Color(0xFFFFFAD8).withAlpha(alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    final inner = size.width * 0.32;
    final outer = size.width * (0.52 + progress * 0.18);
    for (int i = 0; i < 8; i++) {
      final ang = i * (math.pi / 4) + progress * 0.4;
      final p1 = Offset(c.dx + math.cos(ang) * inner, c.dy + math.sin(ang) * inner);
      final p2 = Offset(c.dx + math.cos(ang) * outer, c.dy + math.sin(ang) * outer);
      canvas.drawLine(p1, p2, spikePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter old) =>
      old.progress != progress || old.alpha != alpha;
}

class _StarPainter extends CustomPainter {
  final bool filled;
  _StarPainter({required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final path = _starPath(c, r, 5);

    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withAlpha(100)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.06
          ..color = TT.goldDeep,
      );
      final sheen = Paint()
        ..color = Colors.white.withAlpha(160)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(c.dx - r * 0.18, c.dy - r * 0.45), r * 0.12, sheen);
    } else {
      canvas.drawPath(
        path,
        Paint()..color = TT.driftWoodDark.withAlpha(180),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.06
          ..color = TT.bambooDark,
      );
    }
  }

  Path _starPath(Offset c, double r, int points) {
    final p = Path();
    final outer = r * 0.95;
    final inner = r * 0.42;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final x = c.dx + radius * math.cos(angle);
      final y = c.dy + radius * math.sin(angle);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}
