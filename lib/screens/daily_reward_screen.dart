import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';

/// Show tropical daily reward popup.
Future<void> showDailyRewardPopup(BuildContext context, WidgetRef ref) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (_, anim, __, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (_, __, ___) => const _DailyRewardDialog(),
  );
}

class _DailyRewardDialog extends ConsumerStatefulWidget {
  const _DailyRewardDialog();

  @override
  ConsumerState<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<_DailyRewardDialog>
    with TickerProviderStateMixin {
  bool _claimed = false;
  late final AnimationController _bounceCtrl;
  // Celebration burst when the reward lands.
  late final AnimationController _burstCtrl;
  Map<String, int>? _lastReward;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    final n = ref.read(playerProgressProvider.notifier);
    if (!n.isDailyRewardAvailable) _claimed = true;
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  Future<void> _claim({bool doubleCoins = false}) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final n = ref.read(playerProgressProvider.notifier);
    Map<String, int>? reward;
    try {
      reward = await n.claimDailyReward();
      // Double-coin bonus from rewarded-ad path: add the same coin amount
      // a second time so the total is 2x.
      if (doubleCoins && reward != null) {
        final bonus = reward['coins'] ?? 0;
        if (bonus > 0) {
          await n.addBonusCoins(bonus);
          reward = {...reward, 'coins': bonus * 2};
        }
      }
    } catch (_) {
      reward = null;
    }
    () => n.checkAchievements();
    // Always close the dialog — even if the claim failed (e.g. already
    // claimed today, network glitch). A celebration toast handles the
    // "yes you got the prize!" feedback on the underlying screen.
    if (navigator.canPop()) navigator.pop();
    if (reward != null && messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: TT.palmDark,
          duration: const Duration(milliseconds: 2400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: TT.goldShine),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Günlük ödülü topladın: ${_summarize(reward)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _summarize(Map<String, int> p) {
    final parts = <String>[];
    if ((p['coins'] ?? 0) > 0) parts.add('${p['coins']} altın');
    if ((p['hammer'] ?? 0) > 0) parts.add('${p['hammer']} Çekiç');
    if ((p['colorBlast'] ?? 0) > 0) parts.add('${p['colorBlast']} Renk');
    if ((p['extraMoves'] ?? 0) > 0) parts.add('${p['extraMoves']} +3 Hamle');
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final streak = progress.dailyRewardStreak;
    final dayIdx = _claimed ? (streak - 1) % 7 : streak % 7;

    return Stack(
      children: [
        Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: IslandPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: TT.coralButtonGradient,
                      border: Border.all(color: TT.goldShine, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      'GÜNLÜK ÖDÜL',
                      style: TT.titleLarge.copyWith(
                        color: TT.sandLight,
                        letterSpacing: 1.5,
                        fontSize: 18,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$streak günlük seri', style: TT.bodyMedium.copyWith(color: TT.driftWoodDark, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),

                  // 7-day grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 7,
                    itemBuilder: (_, i) {
                      final reward = PlayerProgressNotifier.dailyRewards[i];
                      final claimed = streak > i || (streak == i && _claimed);
                      final isToday = i == dayIdx && !_claimed;
                      return _DayCard(
                        day: i + 1,
                        coins: reward['coins'] ?? 0,
                        hammer: reward['hammer'] ?? 0,
                        colorBlast: reward['colorBlast'] ?? 0,
                        extraMoves: reward['extraMoves'] ?? 0,
                        claimed: claimed,
                        isToday: isToday,
                        bounceAnim: _bounceCtrl,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_claimed)
                    IslandButton(
                      text: 'Kapat',
                      icon: Icons.check_rounded,
                      color: IslandButtonColor.palm,
                      size: IslandButtonSize.medium,
                      fullWidth: true,
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                    )
                  else ...[
                    IslandButton(
                      text: 'Topla!',
                      icon: Icons.card_giftcard_rounded,
                      color: IslandButtonColor.coral,
                      size: IslandButtonSize.large,
                      fullWidth: true,
                      onPressed: _claim,
                    ),
                    if (AdManager.instance.isRewardedAdReady) ...[
                      const SizedBox(height: 8),
                      IslandButton(
                        text: 'Reklam İzle 2x Altın',
                        icon: Icons.play_circle_filled_rounded,
                        color: IslandButtonColor.lagoon,
                        size: IslandButtonSize.medium,
                        fullWidth: true,
                        onPressed: () {
                          AdManager.instance.showRewardedAd(
                            onRewarded: () {
                              if (mounted) _claim(doubleCoins: true);
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
        ),
        // Celebration burst overlay — only renders during claim animation.
        if (_lastReward != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burstCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RewardBurstPainter(progress: _burstCtrl.value),
                ),
              ),
            ),
          ),
        if (_lastReward != null && _burstCtrl.value > 0 && _burstCtrl.value < 0.85)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _burstCtrl,
                  builder: (_, __) {
                    final t = _burstCtrl.value;
                    final scale = t < 0.18
                        ? Curves.elasticOut.transform(t / 0.18) * 1.0
                        : 1.0 + 0.12 * math.sin(t * math.pi * 2);
                    final dy = -40 * Curves.easeOutCubic.transform(t);
                    final opacity = t > 0.7 ? (1 - (t - 0.7) / 0.15).clamp(0, 1).toDouble() : 1.0;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [TT.goldShine, TT.gold, TT.goldDeep],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: TT.gold.withAlpha(220), blurRadius: 30, spreadRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '+${_lastReward!['coins'] ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tiny confetti micro-burst around the daily reward popup when the player
/// claims. 26 colored squares fly outward + tumble + fade.
class _RewardBurstPainter extends CustomPainter {
  final double progress;
  _RewardBurstPainter({required this.progress});

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
    if (progress <= 0) return;
    final rng = math.Random(7);
    final c = Offset(size.width / 2, size.height / 2);
    const count = 26;
    for (int i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final speed = 60 + rng.nextDouble() * 200;
      final dist = speed * Curves.easeOutCubic.transform(progress);
      final gravityY = 70 * progress * progress;
      final x = c.dx + math.cos(ang) * dist;
      final y = c.dy + math.sin(ang) * dist + gravityY;
      final color = _colors[i % _colors.length];
      final alpha = ((1 - progress) * 230).toInt().clamp(0, 230);
      final s = 4.5 + rng.nextDouble() * 3;
      final rot = rng.nextDouble() * math.pi * 2 + progress * math.pi * 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 1.4),
        Paint()..color = color.withAlpha(alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RewardBurstPainter old) => old.progress != progress;
}

class _DayCard extends StatelessWidget {
  final int day;
  final int coins;
  final int hammer;
  final int colorBlast;
  final int extraMoves;
  final bool claimed;
  final bool isToday;
  final AnimationController bounceAnim;

  const _DayCard({
    required this.day,
    required this.coins,
    required this.hammer,
    required this.colorBlast,
    required this.extraMoves,
    required this.claimed,
    required this.isToday,
    required this.bounceAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: isToday ? bounceAnim : const AlwaysStoppedAnimation(0),
      builder: (_, __) {
        final dy = isToday ? -2.0 - 4 * bounceAnim.value : 0.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isToday
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.goldShine, TT.goldBright, TT.gold],
                    )
                  : claimed
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [TT.palmLight, TT.palm, TT.palmDark],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [TT.bambooLight.withAlpha(180), TT.bambooDark.withAlpha(180)],
                        ),
              boxShadow: [
                if (isToday)
                  BoxShadow(color: TT.gold.withAlpha(180), blurRadius: 14, spreadRadius: 1),
                BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: claimed
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCCFFF1D9), Color(0xCCF5DBA8)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
                      ),
              ),
              child: Column(
                children: [
                  Text(
                    'Gün $day',
                    style: TT.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: TT.driftWoodDark,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          TA.dailyReward(day),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard_rounded, color: TT.gold, size: 30),
                        ),
                        if (claimed)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withAlpha(140),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: TT.goldDeep, size: 11),
                      const SizedBox(width: 2),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: TT.goldDeep,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
