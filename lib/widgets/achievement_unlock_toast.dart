import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:patpat_game/models/achievement.dart';
import 'package:patpat_game/notifications/achievement_bus.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Global achievement unlock banner — mounted in the MaterialApp builder so
/// it appears no matter what screen is active. Listens to [AchievementBus]
/// and pops one toast at a time, queueing any extras.
class AchievementUnlockToast extends StatefulWidget {
  const AchievementUnlockToast({super.key});

  @override
  State<AchievementUnlockToast> createState() => _AchievementUnlockToastState();
}

class _AchievementUnlockToastState extends State<AchievementUnlockToast>
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _sparkle;
  Achievement? _showing;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    AchievementBus.instance.notifier.addListener(_onEmit);
  }

  void _onEmit() {
    if (_showing != null) return; // already animating; queue handled when current ends
    _drainNext();
  }

  void _drainNext() {
    final next = AchievementBus.instance.pop();
    if (next == null) {
      setState(() => _showing = null);
      return;
    }
    setState(() => _showing = next);
    _slide.forward(from: 0).then((_) {
      // Hold a moment before draining the queue.
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _drainNext();
      });
    });
  }

  @override
  void dispose() {
    AchievementBus.instance.notifier.removeListener(_onEmit);
    _slide.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showing == null) return const SizedBox.shrink();
    final a = _showing!;
    return AnimatedBuilder(
      animation: Listenable.merge([_slide, _sparkle]),
      builder: (_, __) {
        final t = _slide.value;
        // Phases: 0..0.18 slide+scale in, 0.18..0.85 hold, 0.85..1 fade out.
        final inT = (t / 0.18).clamp(0.0, 1.0);
        final outT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        final scale = Curves.elasticOut.transform(inT) * (1 - outT * 0.2);
        final dy = (1 - inT) * -120;
        final opacity = (inT * (1 - outT)).clamp(0.0, 1.0);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _ToastBody(achievement: a, sparkleT: _sparkle.value),
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

class _ToastBody extends StatelessWidget {
  final Achievement achievement;
  final double sparkleT;

  const _ToastBody({required this.achievement, required this.sparkleT});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(190), blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(color: TT.gold.withAlpha(220), blurRadius: 26, spreadRadius: 4),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sparkles flying around the toast.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ToastSparklePainter(progress: sparkleT),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1A)],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.coralLight, TT.coral, TT.coralDark],
                    ),
                    border: Border.all(color: TT.goldShine, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: TT.coral.withAlpha(220), blurRadius: 14, spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BAŞARIM AÇILDI!',
                        style: TextStyle(
                          color: TT.goldShine,
                          fontSize: 11,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black.withAlpha(220), blurRadius: 2)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement.title,
                        style: TextStyle(
                          color: TT.sandLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black.withAlpha(220), blurRadius: 3)],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: TT.gold, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '+${achievement.coinReward}',
                            style: const TextStyle(
                              color: TT.goldShine,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastSparklePainter extends CustomPainter {
  final double progress;
  _ToastSparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(13);
    for (int i = 0; i < 10; i++) {
      final lane = rng.nextDouble();
      final x = lane * size.width;
      final y0 = rng.nextDouble() * size.height;
      final phase = rng.nextDouble();
      final tw = (math.sin(progress * 2 * math.pi + phase * 6) + 1) / 2;
      final alpha = (50 + 130 * tw).toInt();
      canvas.drawCircle(
        Offset(x, y0),
        1.4 + 1.2 * tw,
        Paint()
          ..color = const Color(0xFFFFFAD8).withAlpha(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ToastSparklePainter old) => true;
}
