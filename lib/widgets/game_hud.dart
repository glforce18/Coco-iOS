import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Top-of-screen heads-up display: level, moves, timer, score, goals.
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0660), Color(0xFF2D0B80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.goldFrame.withAlpha(120), width: 1),
        boxShadow: [
          BoxShadow(
            color: GameColors.neonPurple.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─ Top row ────────────────────────────────────────────────────
          Row(
            children: [
              // Back button
              _CircleButton(
                icon: Icons.arrow_back,
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              // Level
              Text(
                'Seviye $level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Timer (if > 0)
              if (timeLeft > 0) ...[
                Icon(Icons.timer, color: GameColors.neonCyan, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$timeLeft',
                  style: TextStyle(
                    color: timeLeft <= 10
                        ? GameColors.hotPink
                        : GameColors.neonCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Moves
              const Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                '$movesLeft',
                style: TextStyle(
                  color: movesLeft <= 3 ? GameColors.hotPink : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Pause button
              _CircleButton(
                icon: Icons.pause,
                onTap: onPause,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ─ Score ──────────────────────────────────────────────────────
          Text(
            '$score',
            style: const TextStyle(
              color: GameColors.goldFrame,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: GameColors.goldDark, blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // ─ Goals row ─────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: goals.map((g) => _GoalChip(goal: g)).toList(),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(25),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: complete
            ? GameColors.neonGreen.withAlpha(40)
            : Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete
              ? GameColors.neonGreen.withAlpha(160)
              : Colors.white.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goal.jellyType.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${goal.collected}/${goal.count}',
            style: TextStyle(
              color: complete ? GameColors.neonGreen : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (complete) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, color: GameColors.neonGreen, size: 14),
          ],
        ],
      ),
    );
  }
}
