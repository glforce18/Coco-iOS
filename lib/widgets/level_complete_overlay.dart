import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/shared/gold_button.dart';
import 'package:patpat_game/widgets/shared/gold_panel.dart';
import 'package:patpat_game/widgets/shared/star_strip.dart';

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: GoldPanel(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'TEBRİKLER!',
                    style: TextStyle(
                      color: GameColors.goldFrameBright,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(220),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        const Shadow(
                          color: GameColors.goldFrameDeep,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Stars (animated)
                  StarStrip(filled: stars, size: 44, animate: true, spacing: 6),
                  const SizedBox(height: 22),
                  // Stats
                  _StatRow(label: 'Puan', value: '$score'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'Altın', value: '$coinsEarned'),
                  const SizedBox(height: 8),
                  _StatRow(label: 'Maks Kombo', value: 'x$maxCombo'),
                  const SizedBox(height: 24),
                  // Continue button
                  GoldButton(
                    text: 'DEVAM',
                    color: GoldButtonColor.green,
                    size: GoldButtonSize.large,
                    width: double.infinity,
                    onPressed: onContinue,
                  ),
                ],
              ),
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
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
            ],
          ),
        ),
        Text(
          value,
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
    );
  }
}
