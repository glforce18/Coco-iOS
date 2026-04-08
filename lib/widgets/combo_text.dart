import 'package:flutter/material.dart';

import 'package:patpat_game/theme/game_colors.dart';

/// Animated combo label displayed when combo count >= 2.
class ComboText extends StatelessWidget {
  final int comboCount;

  const ComboText({super.key, required this.comboCount});

  String get _label {
    if (comboCount >= 8) return 'EFSANE! x$comboCount';
    if (comboCount >= 6) return 'MUHTESEM! x$comboCount';
    if (comboCount >= 4) return 'HARIKA! x$comboCount';
    if (comboCount >= 3) return 'KOMBO! x$comboCount';
    return 'SUPER! x$comboCount';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(comboCount),
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Text(
        _label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GameColors.goldFrame,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [
            Shadow(color: GameColors.goldDark, blurRadius: 12),
            Shadow(color: GameColors.hotPink, blurRadius: 24),
          ],
        ),
      ),
    );
  }
}
