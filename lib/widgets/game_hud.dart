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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD1A0660), Color(0xDD2D0B80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameColors.goldFrame.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldDark.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: GameColors.neonPurple.withAlpha(20),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Back + Goals | Level | Timer + Moves + Pause
          Row(
            children: [
              // Back button
              _GoldCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
                size: 30,
              ),
              const SizedBox(width: 6),

              // Hedef (goals) section
              Expanded(
                flex: 3,
                child: _GoalsPanel(goals: goals),
              ),

              const SizedBox(width: 6),

              // Level badge — center
              _LevelBadge(level: level),

              const SizedBox(width: 6),

              // Right side: timer + moves
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Timer (if > 0)
                    if (timeLeft > 0) ...[
                      _TimerChip(timeLeft: timeLeft),
                      const SizedBox(width: 6),
                    ],
                    // Moves counter
                    _MovesCounter(movesLeft: movesLeft),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Pause button
              _GoldCircleButton(
                icon: Icons.pause_rounded,
                onTap: onPause,
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GameColors.goldDark.withAlpha(40),
                  GameColors.goldFrame.withAlpha(20),
                  GameColors.goldDark.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: GameColors.goldLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: [
                  Shadow(color: GameColors.goldDark, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D1A70),
            Color(0xFF1A0A40),
          ],
        ),
        border: Border.all(
          color: GameColors.goldFrame,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrame.withAlpha(60),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: GameColors.neonPurple.withAlpha(40),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lv',
            style: TextStyle(
              color: GameColors.goldLight.withAlpha(200),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          Text(
            '$level',
            style: const TextStyle(
              color: GameColors.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.1,
              shadows: [
                Shadow(color: GameColors.goldDark, blurRadius: 6),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hedef',
            style: TextStyle(
              color: GameColors.goldLight.withAlpha(180),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: goals.map((g) => _GoalChip(goal: g)).toList(),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: complete
            ? GameColors.neonGreen.withAlpha(30)
            : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete
              ? GameColors.neonGreen.withAlpha(120)
              : Colors.white.withAlpha(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Jelly color dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goal.jellyType.color,
              boxShadow: [
                BoxShadow(
                  color: goal.jellyType.color.withAlpha(100),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${goal.collected}/${goal.count}',
            style: TextStyle(
              color: complete ? GameColors.neonGreen : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (complete) ...[
            const SizedBox(width: 2),
            const Icon(Icons.check_circle, color: GameColors.neonGreen, size: 11),
          ],
        ],
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
    final bgColor = isLow
        ? GameColors.hotPink.withAlpha(40)
        : const Color(0xFF1A5060);
    final borderColor = isLow
        ? GameColors.hotPink
        : GameColors.neonCyan;
    final textColor = isLow
        ? GameColors.hotPink
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hamle',
          style: TextStyle(
            color: borderColor.withAlpha(180),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withAlpha(40),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$movesLeft',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (isLow ? GameColors.hotPink : GameColors.neonCyan).withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isLow ? GameColors.hotPink : GameColors.neonCyan).withAlpha(100),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            color: isLow ? GameColors.hotPink : GameColors.neonCyan,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            '$timeLeft',
            style: TextStyle(
              color: isLow ? GameColors.hotPink : GameColors.neonCyan,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(30),
              Colors.white.withAlpha(10),
            ],
          ),
          border: Border.all(
            color: GameColors.goldFrame.withAlpha(100),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldDark.withAlpha(30),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: GameColors.goldLight, size: size * 0.55),
      ),
    );
  }
}
