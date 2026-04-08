import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Beautiful level start popup shown before starting a game.
///
/// Displays level number, region name, star slots, booster pre-selection,
/// and a gold "OYNA" (Play) button.
class LevelStartPopup extends StatelessWidget {
  final int level;
  final int earnedStars;
  final int highScore;
  final VoidCallback onPlay;
  final VoidCallback onClose;

  const LevelStartPopup({
    super.key,
    required this.level,
    required this.earnedStars,
    required this.highScore,
    required this.onPlay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final region = GameRegion.forLevel(level);

    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D0B80),
                Color(0xFF1A0660),
                Color(0xFF0D0235),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: GameColors.goldFrame,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.goldFrame.withAlpha(50),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: GameColors.neonPurple.withAlpha(30),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              // Close button (top-right)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),

              // Gold level circle
              _LevelCircle(level: level),

              const SizedBox(height: 12),

              // Stars row
              _StarsRow(earnedStars: earnedStars),

              const SizedBox(height: 16),

              // "SEVIYE N" text
              Text(
                'SEViYE $level',
                style: const TextStyle(
                  color: GameColors.goldLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: GameColors.goldDark, blurRadius: 8),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Region name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GameColors.neonPurple.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameColors.neonPurple.withAlpha(60),
                  ),
                ),
                child: Text(
                  region.displayName,
                  style: TextStyle(
                    color: GameColors.purpleLight.withAlpha(220),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // High score (if > 0)
              if (highScore > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'En Yuksek: $highScore',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      GameColors.goldFrame.withAlpha(60),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Booster pre-selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BoosterSlot(
                      icon: Icons.gavel_rounded,
                      label: 'Cekic',
                      color: GameColors.orange,
                    ),
                    _BoosterSlot(
                      icon: Icons.auto_awesome,
                      label: 'Renk',
                      color: GameColors.neonPurple,
                    ),
                    _BoosterSlot(
                      icon: Icons.add_circle_outline_rounded,
                      label: '+3',
                      color: GameColors.neonCyan,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // OYNA button
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE44D),
                        Color(0xFFFFD700),
                        Color(0xFFB8860B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: GameColors.goldLight.withAlpha(200),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.goldFrame.withAlpha(80),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: GameColors.goldDark.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'OYNA',
                      style: TextStyle(
                        color: Color(0xFF2D0B00),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Color(0x40FFFFFF),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LevelCircle — large gold circle with level number
// ─────────────────────────────────────────────────────────────────────────────

class _LevelCircle extends StatelessWidget {
  final int level;
  const _LevelCircle({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D1A70),
            Color(0xFF2D0B80),
            Color(0xFF1A0A40),
          ],
        ),
        border: Border.all(
          color: GameColors.goldFrame,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrame.withAlpha(70),
            blurRadius: 16,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: GameColors.neonPurple.withAlpha(40),
            blurRadius: 24,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: GameColors.goldLight,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: GameColors.goldDark, blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StarsRow — 3 star icons
// ─────────────────────────────────────────────────────────────────────────────

class _StarsRow extends StatelessWidget {
  final int earnedStars;
  const _StarsRow({required this.earnedStars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < earnedStars;
        // Middle star slightly larger
        final size = i == 1 ? 32.0 : 26.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: filled
                ? GameColors.goldFrame
                : Colors.white.withAlpha(50),
            shadows: filled
                ? [
                    Shadow(
                      color: GameColors.goldFrame.withAlpha(120),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BoosterSlot — booster pre-selection slot
// ─────────────────────────────────────────────────────────────────────────────

class _BoosterSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BoosterSlot({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(30),
            border: Border.all(
              color: GameColors.goldFrame.withAlpha(120),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: color.withAlpha(180), size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(140),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
