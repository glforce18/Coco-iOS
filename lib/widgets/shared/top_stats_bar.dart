import 'package:flutter/material.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Royal Match-style top stat bar shown across meta screens (Map / Modal / Menu).
///
/// Layout (left → right):
///   [Profile circle] [⭐ stars] [🪙 coins] [❤ lives] [bell] [⚙ settings]
///
/// The whole bar is a single gold-bordered purple pill. Each stat is rendered
/// inline (icon + number) — the design intentionally keeps the bar slim and
/// horizontal so it works on narrow screens.
class TopStatsBar extends StatelessWidget {
  final int stars;
  final int coins;
  final int lives;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationTap;
  final bool showNotificationDot;

  const TopStatsBar({
    super.key,
    required this.stars,
    required this.coins,
    required this.lives,
    this.onProfileTap,
    this.onSettingsTap,
    this.onNotificationTap,
    this.showNotificationDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Profile circle (left)
          _CircleButton(
            onTap: onProfileTap,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),

          // Center pill with 3 stats
          Expanded(
            child: _StatsPill(
              stars: stars,
              coins: coins,
              lives: lives,
            ),
          ),

          const SizedBox(width: 8),

          // Notification bell
          _CircleButton(
            onTap: onNotificationTap,
            color: GameColors.starGoldFilled,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 22,
                ),
                if (showNotificationDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: GameColors.cherryRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Settings gear
          _CircleButton(
            onTap: onSettingsTap,
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Center pill containing star/coin/heart counters.
class _StatsPill extends StatelessWidget {
  final int stars;
  final int coins;
  final int lives;

  const _StatsPill({
    required this.stars,
    required this.coins,
    required this.lives,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
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
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
              icon: Icons.star_rounded,
              iconColor: GameColors.starGoldFilled,
              value: stars,
            ),
            _Divider(),
            _StatChip(
              icon: Icons.monetization_on,
              iconColor: GameColors.goldFrameMid,
              value: coins,
            ),
            _Divider(),
            _StatChip(
              icon: Icons.favorite,
              iconColor: GameColors.cherryRed,
              value: lives,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 18,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 4,
            ),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          _format(value),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(180),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _format(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: GameColors.panelPurpleLight.withAlpha(140),
    );
  }
}

/// Round gold-bordered purple button used for profile/settings/bell icons.
class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  const _CircleButton({
    required this.child,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
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
              color: Colors.black.withAlpha(120),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: color != null
                  ? [color!, color!.withAlpha(180)]
                  : const [
                      GameColors.panelPurple,
                      GameColors.panelPurpleDark,
                    ],
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
