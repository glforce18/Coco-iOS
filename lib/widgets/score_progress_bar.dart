import 'dart:math';

import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';

/// Horizontal progress bar showing score vs target with star markers.
class ScoreProgressBar extends StatelessWidget {
  final int score;
  final int targetScore;
  final int stars;

  const ScoreProgressBar({
    super.key,
    required this.score,
    required this.targetScore,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        targetScore > 0 ? (score / targetScore).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Track
                Container(
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // Fill
                Container(
                  height: 10,
                  width: barWidth * progress,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        GameColors.purple,
                        GameColors.hotPink,
                        GameColors.goldFrame,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.hotPink.withAlpha(80),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Star markers at 50%, 75%, 100%
                _StarMarker(
                  offset: barWidth * 0.5,
                  filled: stars >= 1,
                ),
                _StarMarker(
                  offset: barWidth * 0.75,
                  filled: stars >= 2,
                ),
                _StarMarker(
                  offset: min(barWidth - 10, barWidth * 1.0),
                  filled: stars >= 3,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StarMarker extends StatelessWidget {
  final double offset;
  final bool filled;

  const _StarMarker({required this.offset, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset - 7,
      top: 0,
      child: Icon(
        filled ? Icons.star : Icons.star_border,
        size: 18,
        color: filled ? GameColors.goldFrame : Colors.white38,
      ),
    );
  }
}
