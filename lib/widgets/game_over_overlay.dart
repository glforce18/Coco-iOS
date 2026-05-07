import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/shared/gold_button.dart';
import 'package:patpat_game/widgets/shared/gold_panel.dart';

/// Overlay shown when the player runs out of moves/time.
class GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRetry;
  final VoidCallback onQuit;
  final VoidCallback? onWatchAd;
  final bool showAdButton;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRetry,
    required this.onQuit,
    this.onWatchAd,
    this.showAdButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
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
                    'OYUN BİTTİ',
                    style: TextStyle(
                      color: GameColors.cherryRed,
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
                          color: GameColors.cherryRedDark,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Score
                  Text(
                    'Puan: $score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(200),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Retry button
                  GoldButton(
                    text: 'Tekrar Dene',
                    color: GoldButtonColor.green,
                    size: GoldButtonSize.medium,
                    width: double.infinity,
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                  // Watch ad for extra moves button
                  if (showAdButton) ...[
                    const SizedBox(height: 12),
                    GoldButton(
                      text: 'Reklam İzle +3 Hamle',
                      color: GoldButtonColor.blue,
                      size: GoldButtonSize.medium,
                      width: double.infinity,
                      icon: Icons.play_circle_filled_rounded,
                      onPressed: onWatchAd,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Quit button
                  GoldButton(
                    text: 'Çık',
                    color: GoldButtonColor.red,
                    size: GoldButtonSize.medium,
                    width: double.infinity,
                    icon: Icons.close_rounded,
                    onPressed: onQuit,
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
