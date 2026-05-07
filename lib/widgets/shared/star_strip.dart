import 'dart:math';
import 'package:flutter/material.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Horizontal row of 3 stars showing fill state (0..3).
///
/// Filled stars are gold with glow + outline. Empty stars are dark purple
/// outlined. Optional [animate] performs a staggered pop-in (scale + rotate)
/// when the widget is mounted — used for level complete celebration.
class StarStrip extends StatefulWidget {
  final int filled; // 0..3
  final double size;
  final bool animate;
  final double spacing;

  const StarStrip({
    super.key,
    required this.filled,
    this.size = 32,
    this.animate = false,
    this.spacing = 6,
  });

  @override
  State<StarStrip> createState() => _StarStripState();
}

class _StarStripState extends State<StarStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _starProgress(int index) {
    // Stagger: each star starts 0.2 later and finishes over 0.4 of the timeline.
    if (!widget.animate) return 1;
    final start = 0.1 + index * 0.25;
    final end = start + 0.45;
    if (_ctrl.value <= start) return 0;
    if (_ctrl.value >= end) return 1;
    return ((_ctrl.value - start) / (end - start)).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final isFilled = i < widget.filled;
            final p = _starProgress(i);
            final scale = isFilled
                ? Curves.easeOutBack.transform(p)
                : 1.0;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing),
              child: Transform.rotate(
                angle: isFilled ? (1 - p) * pi / 4 : 0,
                child: Transform.scale(
                  scale: scale,
                  child: _StarIcon(
                    size: widget.size,
                    filled: isFilled,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StarIcon extends StatelessWidget {
  final double size;
  final bool filled;

  const _StarIcon({required this.size, required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(filled: filled),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final bool filled;

  const _StarPainter({required this.filled});

  Path _starPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2 * 0.95;
    final inner = outer * 0.42;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -pi / 2 + i * pi / 5;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);

    if (filled) {
      // Outer glow
      canvas.drawPath(
        path,
        Paint()
          ..color = GameColors.starGoldFilled.withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Gold gradient fill
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.goldHighlight,
              GameColors.starGoldFilled,
              GameColors.goldFrameMid,
            ],
          ).createShader(Offset.zero & size),
      );

      // Outline
      canvas.drawPath(
        path,
        Paint()
          ..color = GameColors.goldFrameDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.06
          ..strokeJoin = StrokeJoin.round,
      );

      // Inner highlight (top-left small white reflection)
      final highlightPath = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(size.width * 0.38, size.height * 0.35),
          radius: size.width * 0.08,
        ));
      canvas.drawPath(
        highlightPath,
        Paint()..color = Colors.white.withAlpha(180),
      );
    } else {
      // Empty star: dark fill + outline
      canvas.drawPath(
        path,
        Paint()..color = GameColors.starGoldEmpty.withAlpha(180),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = GameColors.goldFrameDeep.withAlpha(160)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.05
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}
