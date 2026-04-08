import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Weekly event task definition.
class _EventTask {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int target;
  final int coinReward;

  const _EventTask({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.target,
    required this.coinReward,
  });
}

/// 4 task pools that rotate weekly. Each week picks tasks based on week number.
const _allTasks = <_EventTask>[
  _EventTask(
    id: 'collect_purple',
    title: 'Mor Jole Topla',
    description: '20 mor jole topla',
    emoji: '\uD83D\uDFE3',
    target: 20,
    coinReward: 50,
  ),
  _EventTask(
    id: 'win_levels',
    title: 'Seviye Kazan',
    description: '3 seviye kazan',
    emoji: '\uD83C\uDFC6',
    target: 3,
    coinReward: 75,
  ),
  _EventTask(
    id: 'earn_stars',
    title: 'Yildiz Topla',
    description: '10 yildiz kazan',
    emoji: '\u2B50',
    target: 10,
    coinReward: 100,
  ),
  _EventTask(
    id: 'use_specials',
    title: 'Ozel Guc Kullan',
    description: '5 booster kullan',
    emoji: '\uD83D\uDE80',
    target: 5,
    coinReward: 50,
  ),
  _EventTask(
    id: 'make_combos',
    title: 'Kombo Yap',
    description: '3 kombo yap',
    emoji: '\uD83D\uDD25',
    target: 3,
    coinReward: 75,
  ),
  _EventTask(
    id: 'score_points',
    title: 'Puan Topla',
    description: '5000 puan topla',
    emoji: '\uD83D\uDCAF',
    target: 5000,
    coinReward: 100,
  ),
  _EventTask(
    id: 'boss_level',
    title: 'Boss Seviyesi',
    description: 'Bir boss seviyesini tamamla',
    emoji: '\uD83D\uDC79',
    target: 1,
    coinReward: 200,
  ),
];

/// Get the tasks for the current week based on week number.
List<_EventTask> _tasksForWeek(int weekNumber) {
  // Rotate through tasks — pick 5 tasks per week
  final offset = (weekNumber * 3) % _allTasks.length;
  final tasks = <_EventTask>[];
  for (int i = 0; i < 5; i++) {
    tasks.add(_allTasks[(offset + i) % _allTasks.length]);
  }
  return tasks;
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
    // Ensure event week is current
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProgressProvider.notifier).checkEventWeekReset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final weekNumber = PlayerProgressNotifier.currentWeekNumber();
    final tasks = _tasksForWeek(weekNumber);

    // Calculate days remaining in the week (Mon=1..Sun=7)
    final now = DateTime.now();
    final daysRemaining = 7 - now.weekday;

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
              _buildHeader(context),
              const SizedBox(height: 8),

              // Event info box
              _buildEventInfo(weekNumber, daysRemaining),
              const SizedBox(height: 12),

              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final currentProgress =
                        progress.eventProgress[task.id] ?? 0;
                    return _EventTaskCard(
                      task: task,
                      currentProgress: currentProgress,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/map');
              },
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
                'HAFTALIK ETKINLIK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameColors.goldLight,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: GameColors.goldDark, blurRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(int weekNumber, int daysRemaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameColors.purpleDark.withAlpha(120),
              GameColors.bgMid.withAlpha(160),
            ],
          ),
          border: Border.all(color: GameColors.purpleLight.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: GameColors.purple.withAlpha(30),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Week badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameColors.goldFrame.withAlpha(60),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'HAFTA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2000),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$weekNumber',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E2000),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gorevleri tamamla, odul kazan!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Her hafta yeni gorevler seni bekliyor.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            // Days remaining
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: daysRemaining <= 1
                    ? GameColors.pinkDark.withAlpha(120)
                    : GameColors.greenDark.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: daysRemaining <= 1
                      ? GameColors.hotPink.withAlpha(80)
                      : GameColors.neonGreen.withAlpha(60),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$daysRemaining',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: daysRemaining <= 1
                          ? GameColors.hotPink
                          : GameColors.neonGreen,
                    ),
                  ),
                  Text(
                    'gun',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: daysRemaining <= 1
                          ? GameColors.pinkLight
                          : Colors.white60,
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
// Event Task Card
// ---------------------------------------------------------------------------
class _EventTaskCard extends StatelessWidget {
  final _EventTask task;
  final int currentProgress;

  const _EventTaskCard({
    required this.task,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = currentProgress >= task.target;
    final progressFraction =
        (currentProgress / task.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isComplete
                ? [
                    GameColors.greenDark.withAlpha(60),
                    GameColors.bgMid.withAlpha(100),
                  ]
                : [
                    GameColors.bgLight.withAlpha(80),
                    GameColors.bgMid.withAlpha(120),
                  ],
          ),
          border: Border.all(
            color: isComplete
                ? GameColors.neonGreen.withAlpha(80)
                : GameColors.purpleLight.withAlpha(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete
                        ? GameColors.greenDark.withAlpha(120)
                        : GameColors.purpleDark.withAlpha(100),
                    border: Border.all(
                      color: isComplete
                          ? GameColors.neonGreen.withAlpha(80)
                          : GameColors.purpleLight.withAlpha(60),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      task.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? GameColors.neonGreen
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reward
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? GameColors.neonGreen.withAlpha(30)
                        : GameColors.goldDark.withAlpha(60),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isComplete
                          ? GameColors.neonGreen.withAlpha(60)
                          : GameColors.goldFrame.withAlpha(40),
                    ),
                  ),
                  child: isComplete
                      ? const Icon(Icons.check_circle,
                          color: GameColors.neonGreen, size: 20)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('\uD83E\uDE99',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              '${task.coinReward}',
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

            const SizedBox(height: 10),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.white.withAlpha(20),
                          ),
                          FractionallySizedBox(
                            widthFactor: progressFraction,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: isComplete
                                      ? [
                                          GameColors.neonGreen,
                                          GameColors.greenLight,
                                        ]
                                      : [
                                          GameColors.neonCyan,
                                          GameColors.blueLight,
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isComplete
                                        ? GameColors.neonGreen
                                            .withAlpha(60)
                                        : GameColors.neonCyan
                                            .withAlpha(60),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${currentProgress.clamp(0, task.target)}/${task.target}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isComplete
                        ? GameColors.neonGreen
                        : Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
