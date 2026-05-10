import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

/// "İyi şanslar!" greeting that flies in from the right at level start,
/// hovers briefly, then sails back out. Shows ONLY on the first level
/// load — not after retry. Auto-removes via [onFinished].
class LevelStartGreeting extends StatefulWidget {
  final VoidCallback onFinished;
  const LevelStartGreeting({super.key, required this.onFinished});

  @override
  State<LevelStartGreeting> createState() => _LevelStartGreetingState();
}

class _LevelStartGreetingState extends State<LevelStartGreeting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward().then((_) {
        if (mounted) widget.onFinished();
      });
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
        final t = _ctrl.value;
        // Phases:
        // 0..0.18 → fly in from right (slide + scale up)
        // 0.18..0.30 → bubble appears + bobs
        // 0.30..0.75 → hover (slight bob)
        // 0.75..1.0 → fly out left + fade
        final inT = (t / 0.18).clamp(0.0, 1.0);
        final inEase = Curves.easeOutCubic.transform(inT);
        final outT = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
        final bubbleT = ((t - 0.18) / 0.12).clamp(0.0, 1.0);
        final bubbleEase = Curves.elasticOut.transform(bubbleT);
        final bobY = math.sin((t - 0.30) * math.pi * 2.5) * 4;

        // Translate values
        final dx = (1 - inEase) * 220 - outT * 280; // in from right, out to left
        final dy = (t > 0.30 && t < 0.75) ? bobY : 0.0;
        final scale = inEase * (1 - outT * 0.4);
        final opacity = (inT.clamp(0, 1) * (1 - outT)).toDouble().clamp(0, 1).toDouble();

        return Positioned(
          right: 0,
          left: 0,
          top: MediaQuery.of(context).size.height * 0.32,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: const MascotView(
                          pose: MascotPose.victory,
                          height: 110,
                          showHalo: true,
                          bobbing: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Speech bubble — appears slightly after the mascot.
                      Transform.scale(
                        scale: bubbleEase,
                        child: _SpeechBubble(),
                      ),
                    ],
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

class _SpeechBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF5E0)],
        ),
        border: Border.all(color: TT.gold, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: TT.gold.withAlpha(100), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Text(
        'İyi şanslar!',
        style: TT.titleMedium.copyWith(
          color: TT.driftWoodDark,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
