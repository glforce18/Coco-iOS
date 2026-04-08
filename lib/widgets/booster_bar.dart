import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Bottom bar with three booster buttons in gold-framed circles + cancel mode.
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xDD1A0660),
            const Color(0xDD2D0B80),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? GameColors.hotPink.withAlpha(160)
              : GameColors.goldFrame.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? GameColors.hotPink : GameColors.goldDark)
                .withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isActive ? _buildCancelRow() : _buildBoosterRow(),
    );
  }

  Widget _buildBoosterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BoosterButton(
          icon: Icons.gavel_rounded,
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
          icon: Icons.add_circle_outline_rounded,
          label: '+3',
          color: GameColors.neonCyan,
          onTap: () => onActivate(BoosterType.extraMoves),
        ),
      ],
    );
  }

  Widget _buildCancelRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mode indicator icon
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.hotPink.withAlpha(40),
            border: Border.all(color: GameColors.hotPink.withAlpha(120)),
          ),
          child: Icon(
            boosterMode == ActiveBoosterMode.hammerSelect
                ? Icons.gavel_rounded
                : Icons.auto_awesome,
            color: GameColors.hotPink,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          boosterMode == ActiveBoosterMode.hammerSelect
              ? 'Hedef sec'
              : 'Renk sec',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GameColors.hotPink.withAlpha(200),
                  GameColors.hotPink.withAlpha(140),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameColors.hotPink.withAlpha(200),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.hotPink.withAlpha(50),
                  blurRadius: 8,
                ),
              ],
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

// ─────────────────────────────────────────────────────────────────────────────
// _BoosterButton — gold-framed circle with icon
// ─────────────────────────────────────────────────────────────────────────────

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
          // Gold-framed icon circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.3),
                radius: 0.9,
                colors: [
                  color.withAlpha(220),
                  color.withAlpha(140),
                  color.withAlpha(80),
                ],
              ),
              border: Border.all(
                color: GameColors.goldFrame.withAlpha(200),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: GameColors.goldDark.withAlpha(30),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: GameColors.goldLight.withAlpha(200),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: GameColors.goldDark.withAlpha(100),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
