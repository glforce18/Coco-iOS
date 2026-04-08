import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';

/// Overlay shown when the player completes a level.
class LevelCompleteOverlay extends StatelessWidget {
  final int score;
  final int stars;
  final int coinsEarned;
  final int maxCombo;
  final VoidCallback onContinue;

  const LevelCompleteOverlay({
    super.key,
    required this.score,
    required this.stars,
    required this.coinsEarned,
    required this.maxCombo,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D0B80), Color(0xFF1A0660)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GameColors.goldFrame, width: 2),
              boxShadow: [
                BoxShadow(
                  color: GameColors.goldFrame.withAlpha(60),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'TEBRIKLER!',
                  style: TextStyle(
                    color: GameColors.goldFrame,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: GameColors.goldDark, blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final filled = i < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 40,
                        color: filled
                            ? GameColors.goldFrame
                            : Colors.white.withAlpha(60),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Stats
                _StatRow(label: 'Puan', value: '$score'),
                const SizedBox(height: 8),
                _StatRow(label: 'Altin', value: '$coinsEarned'),
                const SizedBox(height: 8),
                _StatRow(label: 'Maks Kombo', value: 'x$maxCombo'),
                const SizedBox(height: 24),
                // Continue button
                GestureDetector(
                  onTap: onContinue,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GameColors.neonGreen, Color(0xFF1A7030)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.neonGreen.withAlpha(80),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Text(
                      'DEVAM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
