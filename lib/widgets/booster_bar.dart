import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Bottom bar with three booster buttons + cancel.
class BoosterBar extends StatelessWidget {
  final ActiveBoosterMode boosterMode;
  final Function(BoosterType) onActivate;
  final VoidCallback onCancel;

  const BoosterBar({
    super.key,
    required this.boosterMode,
    required this.onActivate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = boosterMode != ActiveBoosterMode.none;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.bgMid.withAlpha(200),
            GameColors.bgDeep.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? GameColors.hotPink.withAlpha(160)
              : Colors.white.withAlpha(30),
        ),
      ),
      child: isActive
          ? _buildCancelRow()
          : _buildBoosterRow(),
    );
  }

  Widget _buildBoosterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BoosterButton(
          icon: Icons.gavel,
          label: 'Cekic',
          color: GameColors.orange,
          onTap: () => onActivate(BoosterType.hammer),
        ),
        _BoosterButton(
          icon: Icons.auto_awesome,
          label: 'Renk',
          color: GameColors.neonPurple,
          onTap: () => onActivate(BoosterType.colorBlast),
        ),
        _BoosterButton(
          icon: Icons.add_circle_outline,
          label: '+3',
          color: GameColors.blue,
          onTap: () => onActivate(BoosterType.extraMoves),
        ),
      ],
    );
  }

  Widget _buildCancelRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          boosterMode == ActiveBoosterMode.hammerSelect
              ? 'Hedef sec'
              : 'Renk sec',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: GameColors.hotPink.withAlpha(180),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Iptal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoosterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withAlpha(200), color.withAlpha(100)],
              ),
              border: Border.all(color: color.withAlpha(180)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
