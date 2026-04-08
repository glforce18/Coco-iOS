import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/models/achievement.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);
    final earnedIds = progress.achievements;
    final earned =
        Achievement.values.where((a) => earnedIds.contains(a.id)).toList();
    final locked =
        Achievement.values.where((a) => !earnedIds.contains(a.id)).toList();
    final totalReward =
        earned.fold<int>(0, (sum, a) => sum + a.coinReward);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0660),
              Color(0xFF0D0235),
              Color(0xFF050120),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _AchievementHeader(
                earned: earned.length,
                total: Achievement.values.length,
                totalReward: totalReward,
                onBack: () {
                  context.go('/map');
                },
              ),

              // Progress bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _ProgressBar(
                  value: earned.length / Achievement.values.length,
                  label:
                      '${earned.length} / ${Achievement.values.length}',
                ),
              ),

              const SizedBox(height: 8),

              // Achievement list
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    // Earned section
                    if (earned.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'KAZANILAN',
                        color: GameColors.neonGreen,
                        count: earned.length,
                      ),
                      const SizedBox(height: 8),
                      ...earned.map((a) => _AchievementCard(
                            achievement: a,
                            isEarned: true,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Locked section
                    if (locked.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'KILITLI',
                        color: Colors.white38,
                        count: locked.length,
                      ),
                      const SizedBox(height: 8),
                      ...locked.map((a) => _AchievementCard(
                            achievement: a,
                            isEarned: false,
                          )),
                    ],

                    const SizedBox(height: 24),
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _AchievementHeader extends StatelessWidget {
  final int earned;
  final int total;
  final int totalReward;
  final VoidCallback onBack;

  const _AchievementHeader({
    required this.earned,
    required this.total,
    required this.totalReward,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameColors.purpleLight.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(140),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'BASARIMLAR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: GameColors.goldLight,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: GameColors.goldDark, blurRadius: 8),
                  ],
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GameColors.goldDark.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: GameColors.goldFrame.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\uD83C\uDFC6',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$earned/$total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: GameColors.goldLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------
class _ProgressBar extends StatelessWidget {
  final double value;
  final String label;

  const _ProgressBar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          GameColors.goldDark,
                          GameColors.goldFrame,
                          GameColors.goldLight,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.goldFrame.withAlpha(80),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // Label
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withAlpha(220),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Achievement card
// ---------------------------------------------------------------------------
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;

  const _AchievementCard({
    required this.achievement,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isEarned
                ? [
                    GameColors.greenDark.withAlpha(60),
                    GameColors.bgMid.withAlpha(120),
                  ]
                : [
                    Colors.grey.shade900.withAlpha(80),
                    GameColors.bgDeep.withAlpha(120),
                  ],
          ),
          border: Border.all(
            color: isEarned
                ? GameColors.neonGreen.withAlpha(80)
                : Colors.white.withAlpha(20),
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: GameColors.neonGreen.withAlpha(20),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? GameColors.greenDark.withAlpha(120)
                    : Colors.grey.shade800.withAlpha(120),
                border: Border.all(
                  color: isEarned
                      ? GameColors.neonGreen.withAlpha(100)
                      : Colors.white.withAlpha(30),
                ),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: GameColors.neonGreen.withAlpha(40),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: isEarned ? null : Colors.white38,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isEarned ? Colors.white : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEarned
                          ? Colors.white.withAlpha(140)
                          : Colors.white.withAlpha(80),
                    ),
                  ),
                ],
              ),
            ),

            // Reward or checkmark
            if (isEarned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GameColors.neonGreen.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: GameColors.neonGreen,
                  size: 22,
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GameColors.goldDark.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: GameColors.goldFrame.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\uD83E\uDE99',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${achievement.coinReward}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GameColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
