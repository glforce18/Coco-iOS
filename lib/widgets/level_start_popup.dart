import 'package:flutter/material.dart';

import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/shared/gold_button.dart';
import 'package:patpat_game/widgets/shared/gold_panel.dart';
import 'package:patpat_game/widgets/shared/star_strip.dart';

/// Mockup M4 — Level start popup shown when tapping a level node on the map.
///
/// Layout (top → bottom):
///   [Seviye N badge with star strip]
///   [empty star slots — current attempt placeholders]
///   [SEVİYE N title]
///   [Region name pill — e.g. "Şeker Bahçesi"]
///   [En Yüksek line — only if highScore > 0]
///   [3 booster cards — Çekiç x3, Renk x2, +1 x1]
///   [Big OYNA button]
///   [Close X — top-right corner]
///
/// Public API preserved (level, earnedStars, highScore, onPlay, onClose).
class LevelStartPopup extends StatefulWidget {
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
  State<LevelStartPopup> createState() => _LevelStartPopupState();
}

class _LevelStartPopupState extends State<LevelStartPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = GameRegion.forLevel(widget.level);

    return GestureDetector(
      // Tap outside to close
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withAlpha(170),
        child: Center(
          child: AnimatedBuilder(
            animation: _enter,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(_enter.value.clamp(0, 1));
              return Opacity(
                opacity: _enter.value.clamp(0, 1),
                child: Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              // Block tap-outside on the panel itself
              onTap: () {},
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main panel
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: GoldPanel(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "Seviye N" badge with previous best stars
                          _LevelBadge(
                            level: widget.level,
                            earnedStars: widget.earnedStars,
                          ),

                          const SizedBox(height: 18),

                          // Empty star slots (this attempt)
                          StarStrip(
                            filled: 0,
                            size: 24,
                            spacing: 4,
                          ),

                          const SizedBox(height: 14),

                          // SEVİYE N
                          Text(
                            'SEVİYE ${widget.level}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(200),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                                Shadow(
                                  color: GameColors.goldFrameDeep,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Region name pill
                          _RegionPill(name: region.displayName),

                          if (widget.highScore > 0) ...[
                            const SizedBox(height: 10),
                            Text(
                              'En Yüksek: ${widget.highScore}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(160),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // 3 booster cards
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              _BoosterCard(
                                icon: Icons.gavel_rounded,
                                label: 'Çekiç',
                                count: 3,
                                color: GameColors.cherryRed,
                              ),
                              _BoosterCard(
                                icon: Icons.auto_awesome,
                                label: 'Renk',
                                count: 2,
                                color: GameColors.buttonPurple,
                                isRainbow: true,
                              ),
                              _BoosterCard(
                                icon: Icons.add_rounded,
                                label: '+1',
                                count: 1,
                                color: GameColors.buttonBlue,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Big OYNA button
                          GoldButton(
                            text: 'OYNA',
                            color: GoldButtonColor.gold,
                            size: GoldButtonSize.large,
                            width: 220,
                            onPressed: widget.onPlay,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close X button (overlapping top-right)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: _CloseButton(onTap: widget.onClose),
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

// ─────────────────────────────────────────────────────────────────────────────
// _LevelBadge — "Seviye N" header with 3 best-stars (mockup M4 top)
// ─────────────────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final int level;
  final int earnedStars;

  const _LevelBadge({required this.level, required this.earnedStars});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withAlpha(120),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seviye',
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 3),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$level',
              style: TextStyle(
                color: GameColors.goldFrameBright,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(220),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            StarStrip(filled: earnedStars, size: 22, spacing: 3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RegionPill — small purple pill with the region display name
// ─────────────────────────────────────────────────────────────────────────────

class _RegionPill extends StatelessWidget {
  final String name;
  const _RegionPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.panelPurpleLight,
            GameColors.panelPurple,
          ],
        ),
        border: Border.all(
          color: GameColors.goldFrameMid.withAlpha(180),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(60),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BoosterCard — round gold-bordered booster icon with count badge
// ─────────────────────────────────────────────────────────────────────────────

class _BoosterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isRainbow;

  const _BoosterCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.isRainbow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Gold frame circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isRainbow
                      ? const SweepGradient(
                          colors: [
                            Color(0xFFFF4080),
                            Color(0xFFFFCC00),
                            Color(0xFF30B050),
                            Color(0xFF00E5FF),
                            Color(0xFFB44DFF),
                            Color(0xFFFF4080),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            Color.lerp(color, Colors.black, 0.4) ?? color,
                          ],
                        ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(220),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Count badge (bottom-right)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameColors.cherryRed,
                      GameColors.cherryRedDark,
                    ],
                  ),
                  border: Border.all(
                    color: GameColors.goldFrameBright,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(140),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'x$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CloseButton — round gold-bordered X
// ─────────────────────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
              color: Colors.black.withAlpha(160),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.cherryRed,
                GameColors.cherryRedDark,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
