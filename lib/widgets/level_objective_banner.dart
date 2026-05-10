import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Slim "HEDEF" banner above the score progress bar — describes the level's
/// primary objective in plain Turkish (e.g. "12 mor + 8 mavi topla", or
/// "5000 puana ulaş" when no collect goals exist).
class LevelObjectiveBanner extends StatelessWidget {
  final List<LevelGoal> goals;
  final int targetScore;

  const LevelObjectiveBanner({
    super.key,
    required this.goals,
    required this.targetScore,
  });

  String _buildText() {
    final collect = goals
        .where((g) => g.goalType == GoalType.collectJelly)
        .toList();
    if (collect.isNotEmpty) {
      final parts = collect.map((g) => '${g.count} ${_typeName(g.jellyType)}').join(' + ');
      return '$parts topla';
    }
    final ice = goals.where((g) => g.goalType == GoalType.breakIce).fold<int>(0, (a, b) => a + b.count);
    if (ice > 0) return '$ice buz kır';
    final choco = goals.where((g) => g.goalType == GoalType.clearChocolate).fold<int>(0, (a, b) => a + b.count);
    if (choco > 0) return '$choco çikolata temizle';
    final combos = goals.where((g) => g.goalType == GoalType.makeCombos).fold<int>(0, (a, b) => a + b.count);
    if (combos > 0) return '$combos kombo yap';
    return '$targetScore puana ulaş';
  }

  String _typeName(JellyType t) {
    switch (t) {
      case JellyType.purple: return 'kırmızı';
      case JellyType.yellow: return 'sarı';
      case JellyType.blue:   return 'mavi';
      case JellyType.green:  return 'yeşil';
      case JellyType.pink:   return 'pembe';
      case JellyType.orange: return 'turuncu';
      case JellyType.black:  return 'siyah';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.goldShine, TT.gold, TT.goldDeep],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 8, offset: const Offset(0, 2)),
              BoxShadow(color: TT.gold.withAlpha(120), blurRadius: 12, spreadRadius: -1),
            ],
          ),
          padding: const EdgeInsets.all(1.6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.driftWoodDark, TT.driftWood],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded,
                    color: TT.goldShine,
                    size: 14,
                    shadows: [
                      Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                    ]),
                const SizedBox(width: 5),
                Text(
                  'HEDEF',
                  style: TextStyle(
                    color: TT.goldShine,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.black.withAlpha(220), blurRadius: 2, offset: const Offset(0, 1))],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: TT.goldShine.withAlpha(120),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _buildText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Color(0xCC000000), blurRadius: 3, offset: Offset(0, 1))],
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
