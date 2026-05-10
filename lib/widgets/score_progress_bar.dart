import 'dart:math';

import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';

/// Slim transparent star progress bar — no panel, just a thin track + fill +
/// 3 floating star markers. Sits between HUD and board.
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
    final progress = targetScore > 0 ? (score / targetScore).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
      child: SizedBox(
        height: 18,
        child: LayoutBuilder(
          builder: (_, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Slim track — black with thin gold outline
                Container(
                  height: 7,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black.withAlpha(140),
                    border: Border.all(color: TT.gold.withAlpha(180), width: 1.2),
                  ),
                ),
                // Fill — palm green to gold gradient
                Container(
                  height: 7,
                  width: barWidth * progress,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [TT.palm, TT.palmLight, TT.gold, TT.goldShine],
                      stops: [0.0, 0.4, 0.75, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(color: TT.palm.withAlpha(140), blurRadius: 6),
                    ],
                  ),
                ),
                // Floating star markers
                _Marker(left: barWidth * 0.5 - 10, filled: stars >= 1),
                _Marker(left: barWidth * 0.75 - 10, filled: stars >= 2),
                _Marker(left: min(barWidth - 20, barWidth - 10), filled: stars >= 3),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final double left;
  final bool filled;
  const _Marker({required this.left, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.goldShine, TT.gold, TT.goldDeep],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(180), Colors.black.withAlpha(220)],
                ),
          border: Border.all(
            color: filled ? Colors.white : TT.gold.withAlpha(180),
            width: 1.5,
          ),
          boxShadow: filled
              ? [BoxShadow(color: TT.gold.withAlpha(160), blurRadius: 8)]
              : [BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 4)],
        ),
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? Colors.white : TT.gold.withAlpha(220),
          size: 13,
          shadows: filled
              ? [Shadow(color: Colors.black.withAlpha(180), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
      ),
    );
  }
}
