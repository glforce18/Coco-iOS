import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';

/// Floating "+N" label that drifts up from the match position and fades.
/// Auto-disposes after 900ms via [onDone] so the parent can prune the list.
class ScorePopup extends StatefulWidget {
  final int delta;
  final Offset start;
  final VoidCallback onDone;

  const ScorePopup({
    super.key,
    required this.delta,
    required this.start,
    required this.onDone,
  });

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().then((_) {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Bigger fonts + brighter colors for fatter scores. >100 = critical.
  (Color, double) _styleFor(int d) {
    if (d >= 200) return (TT.coralLight, 28);
    if (d >= 100) return (TT.gold, 24);
    if (d >= 50) return (TT.goldShine, 22);
    return (TT.sandLight, 20);
  }

  @override
  Widget build(BuildContext context) {
    final (color, fontSize) = _styleFor(widget.delta);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Quick punch in (0..0.18) then drift up + fade (0.18..1).
        final scaleIn = (t / 0.18).clamp(0.0, 1.0);
        final scale = Curves.elasticOut.transform(scaleIn) * 1.0;
        final dy = -50 * Curves.easeOutCubic.transform(t);
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);

        return Positioned(
          left: widget.start.dx - 40,
          top: widget.start.dy + dy,
          width: 80,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: Text(
                    '+${widget.delta}',
                    style: TextStyle(
                      color: color,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(220),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: color.withAlpha(180),
                          blurRadius: 12,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
