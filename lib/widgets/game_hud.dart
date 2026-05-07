import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Top-of-screen heads-up display matching original game design:
/// Left: mascot + "Hedef" goal panel
/// Center: Level badge
/// Right: "Hamle" moves counter
class GameHud extends StatelessWidget {
  final int level;
  final int movesLeft;
  final int score;
  final int timeLeft;
  final List<LevelGoal> goals;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const GameHud({
    super.key,
    required this.level,
    required this.movesLeft,
    required this.score,
    required this.timeLeft,
    required this.goals,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.goldHighlight,
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
            GameColors.goldHighlight,
          ],
          stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(120),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurpleLight,
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Back + Goals | Level | Timer + Moves + Pause
            Row(
              children: [
                _GoldCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                  size: 32,
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: _GoalsPanel(goals: goals),
                ),
                const SizedBox(width: 6),
                _LevelBadge(level: level),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (timeLeft > 0) ...[
                        _TimerChip(timeLeft: timeLeft),
                        const SizedBox(width: 6),
                      ],
                      _MovesCounter(movesLeft: movesLeft),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _GoldCircleButton(
                  icon: Icons.pause_rounded,
                  onTap: onPause,
                  size: 32,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Score display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    GameColors.goldFrameBright,
                    GameColors.goldFrameMid,
                    GameColors.goldFrameBright,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameColors.goldFrameMid.withAlpha(120),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  color: GameColors.panelPurpleDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Colors.white.withAlpha(120),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level Badge — ornate circle with level number
// ─────────────────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(120),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lv',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$level',
              style: const TextStyle(
                color: GameColors.goldFrameBright,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Goals Panel — "Hedef" label + goal chips
// ─────────────────────────────────────────────────────────────────────────────

class _GoalsPanel extends StatelessWidget {
  final List<LevelGoal> goals;
  const _GoalsPanel({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: goals.map((g) => _GoalChip(goal: g)).toList(),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final LevelGoal goal;
  const _GoalChip({required this.goal});

  @override
  Widget build(BuildContext context) {
    final complete = goal.isComplete;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: complete
                ? [
                    GameColors.buttonGreen,
                    GameColors.buttonGreenDark,
                  ]
                : const [
                    GameColors.panelPurple,
                    GameColors.panelPurpleDark,
                  ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goal.jellyType.color,
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: goal.jellyType.color.withAlpha(160),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${goal.collected}/${goal.count}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
                ],
              ),
            ),
            if (complete) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 13,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Moves Counter — styled circle like original
// ─────────────────────────────────────────────────────────────────────────────

class _MovesCounter extends StatelessWidget {
  final int movesLeft;
  const _MovesCounter({required this.movesLeft});

  @override
  Widget build(BuildContext context) {
    final isLow = movesLeft <= 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLow
                ? const [
                    GameColors.cherryRed,
                    GameColors.cherryRedDark,
                  ]
                : const [
                    GameColors.panelPurple,
                    GameColors.panelPurpleDark,
                  ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 16,
              shadows: [
                Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
              ],
            ),
            const SizedBox(width: 4),
            Text(
              '$movesLeft',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(200), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer Chip
// ─────────────────────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final int timeLeft;
  const _TimerChip({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final isLow = timeLeft <= 10;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLow
                ? const [
                    GameColors.cherryRed,
                    GameColors.cherryRedDark,
                  ]
                : const [
                    GameColors.panelPurple,
                    GameColors.panelPurpleDark,
                  ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_rounded,
              color: Colors.white,
              size: 14,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 3),
              ],
            ),
            const SizedBox(width: 3),
            Text(
              '$timeLeft',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(200), blurRadius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold Circle Button
// ─────────────────────────────────────────────────────────────────────────────

class _GoldCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GoldCircleButton({
    required this.icon,
    required this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              GameColors.goldFrameBright,
              GameColors.goldFrameMid,
              GameColors.goldFrameDeep,
              GameColors.goldFrameMid,
              GameColors.goldFrameBright,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.panelPurple,
                GameColors.panelPurpleDark,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.55,
            shadows: [
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }
}
