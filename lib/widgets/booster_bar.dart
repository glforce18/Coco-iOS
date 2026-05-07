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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: (isActive
                    ? GameColors.cherryRed
                    : GameColors.goldFrameMid)
                .withAlpha(100),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        child: isActive ? _buildCancelRow() : _buildBoosterRow(),
      ),
    );
  }

  Widget _buildBoosterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BoosterButton(
          icon: Icons.gavel_rounded,
          label: 'Çekiç',
          color: GameColors.cherryRed,
          onTap: () => onActivate(BoosterType.hammer),
        ),
        _BoosterButton(
          icon: Icons.auto_awesome,
          label: 'Renk',
          color: GameColors.buttonPurple,
          onTap: () => onActivate(BoosterType.colorBlast),
        ),
        _BoosterButton(
          icon: Icons.add_circle_outline_rounded,
          label: '+3',
          color: GameColors.buttonBlue,
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
            color: GameColors.cherryRed.withAlpha(60),
            border: Border.all(color: GameColors.cherryRed.withAlpha(160)),
          ),
          child: Icon(
            boosterMode == ActiveBoosterMode.hammerSelect
                ? Icons.gavel_rounded
                : Icons.auto_awesome,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          boosterMode == ActiveBoosterMode.hammerSelect
              ? 'Hedef seç'
              : 'Renk seç',
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.cherryRed,
                  GameColors.cherryRedDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameColors.goldFrameBright,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.cherryRed.withAlpha(120),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text(
              'İptal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 3),
                ],
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
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  GameColors.goldFrameBright,
                  GameColors.goldFrameMid,
                  GameColors.goldFrameDeep,
                  GameColors.goldFrameMid,
                  GameColors.goldFrameBright,
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.3),
                  radius: 0.9,
                  colors: [
                    color,
                    Color.lerp(color, Colors.black, 0.5) ?? color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(120),
                    blurRadius: 10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(180),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
