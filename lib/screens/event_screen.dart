import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_chip.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';

class _EventTask {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int coinReward;

  const _EventTask({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.coinReward,
  });
}

const _allTasks = <_EventTask>[
  _EventTask(id: 'collect_purple', title: 'Mor Jöle Topla', description: '20 mor jöle topla', icon: Icons.bubble_chart_rounded, target: 20, coinReward: 50),
  _EventTask(id: 'win_levels', title: 'Bölüm Kazan', description: '3 bölüm kazan', icon: Icons.emoji_events_rounded, target: 3, coinReward: 75),
  _EventTask(id: 'earn_stars', title: 'Yıldız Topla', description: '10 yıldız kazan', icon: Icons.star_rounded, target: 10, coinReward: 100),
  _EventTask(id: 'use_specials', title: 'Güçlendirici Kullan', description: '5 güçlendirici kullan', icon: Icons.bolt_rounded, target: 5, coinReward: 50),
  _EventTask(id: 'make_combos', title: 'Kombo Yap', description: '3 kombo yap', icon: Icons.local_fire_department_rounded, target: 3, coinReward: 75),
  _EventTask(id: 'score_points', title: 'Puan Topla', description: '5000 puan topla', icon: Icons.bar_chart_rounded, target: 5000, coinReward: 100),
  _EventTask(id: 'boss_level', title: 'Boss Bölümü', description: 'Bir boss bölümünü tamamla', icon: Icons.castle_rounded, target: 1, coinReward: 200),
];

List<_EventTask> _tasksForWeek(int weekNumber) {
  final offset = (weekNumber * 3) % _allTasks.length;
  return List.generate(5, (i) => _allTasks[(offset + i) % _allTasks.length]);
}

class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProgressProvider.notifier).checkEventWeekReset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final weekNumber = PlayerProgressNotifier.currentWeekNumber();
    final tasks = _tasksForWeek(weekNumber);
    final now = DateTime.now();
    final daysRemaining = 7 - now.weekday;

    return IslandScaffold(
      backgroundAsset: TA.eventBg,
      overlayOpacity: 0.5,
      child: Column(
        children: [
          IslandTopBar(
            stars: progress.totalStars,
            coins: progress.coins,
            hearts: progress.lives,
            leading: IslandCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/map')),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: TT.coralButtonGradient,
                border: Border.all(color: TT.goldShine, width: 2),
                boxShadow: [
                  BoxShadow(color: TT.coral.withAlpha(160), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: TT.goldShine, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HAFTALIK ETKİNLİK',
                          style: TT.titleMedium.copyWith(
                            color: TT.sandLight,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                        ),
                        Text(
                          'Hafta $weekNumber',
                          style: TT.bodySmall.copyWith(color: TT.sandLight.withAlpha(210)),
                        ),
                      ],
                    ),
                  ),
                  IslandChip(
                    text: '$daysRemaining gün',
                    icon: Icons.access_time_rounded,
                    bg: TT.gold,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final task = tasks[i];
                final p = progress.eventProgress[task.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EventTaskCard(task: task, currentProgress: p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTaskCard extends StatelessWidget {
  final _EventTask task;
  final int currentProgress;
  const _EventTaskCard({required this.task, required this.currentProgress});

  @override
  Widget build(BuildContext context) {
    final pct = (currentProgress / task.target).clamp(0.0, 1.0);
    final done = currentProgress >= task.target;
    return IslandSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? TT.palmButtonGradient : TT.lagoonButtonGradient,
              border: Border.all(color: TT.goldShine, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(
              done ? Icons.check_rounded : task.icon,
              color: Colors.white,
              size: 28,
              shadows: [
                Shadow(color: Colors.black.withAlpha(200), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task.title, style: TT.titleMedium.copyWith(color: TT.goldDeep)),
                Text(task.description, style: TT.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              Container(color: TT.driftWoodDark.withAlpha(180)),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: done ? TT.palmButtonGradient : TT.coralButtonGradient,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currentProgress/${task.target}',
                      style: TT.bodySmall.copyWith(fontWeight: FontWeight.w900, color: TT.driftWoodDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IslandChip(
            text: '${task.coinReward}',
            icon: Icons.monetization_on_rounded,
            bg: done ? TT.palm : TT.gold,
            fontSize: 13,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ],
      ),
    );
  }
}
