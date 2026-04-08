import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Show the daily reward popup dialog.
/// Call this from MapScreen when the user enters the map and hasn't claimed today.
Future<void> showDailyRewardPopup(BuildContext context, WidgetRef ref) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(170),
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (ctx, anim, secondAnim, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, anim, secondAnim) {
      return const _DailyRewardDialog();
    },
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
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    final notifier = ref.read(playerProgressProvider.notifier);
    if (!notifier.isDailyRewardAvailable) {
      _claimed = true;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    final notifier = ref.read(playerProgressProvider.notifier);
    final reward = await notifier.claimDailyReward();
    if (reward != null) {
      setState(() {
        _claimed = true;
      });
      // Check achievements after claiming
      await notifier.checkAchievements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final streak = progress.dailyRewardStreak;
    final dayIndex = _claimed
        ? (streak - 1) % 7
        : (streak) % 7; // next day index if not claimed yet

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameColors.goldFrame, width: 3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D0B80),
                Color(0xFF1A0660),
                Color(0xFF0D0235),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.goldFrame.withAlpha(60),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              _buildTitleBar(),
              const SizedBox(height: 8),

              // Streak info
              _buildStreakInfo(streak),
              const SizedBox(height: 12),

              // 7 day cards
              _buildDayCards(dayIndex, streak),
              const SizedBox(height: 16),

              // Main reward display
              _buildRewardDisplay(dayIndex),
              const SizedBox(height: 16),

              // Claim / OK button
              _buildButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
        gradient: LinearGradient(
          colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFB8860B)],
        ),
      ),
      child: const Text(
        'GUNLUK ODUL',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF3E2000),
          letterSpacing: 2,
          shadows: [
            Shadow(color: Color(0x40FFFFFF), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakInfo(int streak) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Bugun seni bekleyen odul',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: GameColors.orangeDark.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.orange.withAlpha(100)),
            ),
            child: Text(
              '\uD83D\uDD25 Seri: $streak gun',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: GameColors.orangeLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCards(int currentDayIndex, int streak) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final bool isPast;
          final bool isToday;

          if (_claimed) {
            isPast = i <= currentDayIndex;
            isToday = i == currentDayIndex;
          } else {
            isPast = i < currentDayIndex;
            isToday = i == currentDayIndex;
          }
          final isFuture = !isPast && !isToday;

          return _DayCard(
            day: i + 1,
            isPast: isPast && !isToday,
            isToday: isToday,
            isFuture: isFuture,
            shineController: _shineController,
          );
        }),
      ),
    );
  }

  Widget _buildRewardDisplay(int dayIndex) {
    final rewards = PlayerProgressNotifier.dailyRewards;
    final reward = rewards[dayIndex];
    final coins = reward['coins'] ?? 0;
    final hammers = reward['hammer'] ?? 0;
    final blasts = reward['colorBlast'] ?? 0;
    final extraMoves = reward['extraMoves'] ?? 0;

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnim.value),
          child: child,
        );
      },
      child: Column(
        children: [
          // Coin icon + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\uD83E\uDE99', style: TextStyle(fontSize: 42)),
              const SizedBox(width: 8),
              Text(
                '+$coins',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: GameColors.goldLight,
                  shadows: [
                    Shadow(color: GameColors.goldDark, blurRadius: 12),
                  ],
                ),
              ),
            ],
          ),

          // Booster badges
          if (hammers > 0 || blasts > 0 || extraMoves > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (hammers > 0)
                    _BoosterBadge(
                        emoji: '\uD83D\uDD28', label: '$hammers Cekic'),
                  if (blasts > 0)
                    _BoosterBadge(
                        emoji: '\uD83C\uDF08', label: '$blasts Renk Patlatma'),
                  if (extraMoves > 0)
                    _BoosterBadge(
                        emoji: '\u27A1\uFE0F', label: '$extraMoves Hamle'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (_claimed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: _GradientButton(
            label: 'TAMAM',
            colors: const [Color(0xFF6040A0), Color(0xFF4020A0)],
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: _GradientButton(
          label: 'ODUL AL!',
          colors: const [Color(0xFF30B050), Color(0xFF1A7030)],
          onTap: _claimReward,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day Card — small card for each day in the 7-day cycle
// ---------------------------------------------------------------------------
class _DayCard extends StatelessWidget {
  final int day;
  final bool isPast;
  final bool isToday;
  final bool isFuture;
  final AnimationController shineController;

  const _DayCard({
    required this.day,
    required this.isPast,
    required this.isToday,
    required this.isFuture,
    required this.shineController,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPast
        ? GameColors.greenDark.withAlpha(160)
        : isToday
            ? GameColors.goldDark.withAlpha(180)
            : Colors.grey.shade800.withAlpha(120);

    final borderColor = isPast
        ? GameColors.green.withAlpha(120)
        : isToday
            ? GameColors.goldFrame
            : Colors.grey.withAlpha(60);

    return AnimatedBuilder(
      animation: shineController,
      builder: (context, child) {
        final scale = isToday ? 1.0 + sin(shineController.value * pi * 2) * 0.05 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 38,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isToday ? 2 : 1),
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: GameColors.goldFrame.withAlpha(80),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isToday
                    ? GameColors.goldLight
                    : isPast
                        ? Colors.white
                        : Colors.white38,
              ),
            ),
            const SizedBox(height: 2),
            if (isPast)
              const Icon(Icons.check_circle, size: 16, color: GameColors.neonGreen)
            else if (isToday)
              const Text('\uD83E\uDE99', style: TextStyle(fontSize: 16))
            else
              Icon(Icons.lock, size: 14, color: Colors.white.withAlpha(60)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booster Badge — small tag for booster rewards
// ---------------------------------------------------------------------------
class _BoosterBadge extends StatelessWidget {
  final String emoji;
  final String label;

  const _BoosterBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.purpleDark.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.purpleLight.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient Button — reusable button with gradient background
// ---------------------------------------------------------------------------
class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
