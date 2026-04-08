import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';

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
              border: Border.all(color: GameColors.hotPink, width: 2),
              boxShadow: [
                BoxShadow(
                  color: GameColors.hotPink.withAlpha(60),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'OYUN BITTI',
                  style: TextStyle(
                    color: GameColors.hotPink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Color(0xFFC01050), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Score
                Text(
                  'Puan: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                // Retry button
                GestureDetector(
                  onTap: onRetry,
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
                      'Tekrar Dene',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Watch ad for extra moves button
                if (showAdButton) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onWatchAd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF009624)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C853).withAlpha(80),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\uD83D\uDCFA',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reklam Izle +3 Hamle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Quit button
                GestureDetector(
                  onTap: onQuit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          GameColors.hotPink,
                          GameColors.hotPink.withAlpha(180),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.hotPink.withAlpha(60),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Cik',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
