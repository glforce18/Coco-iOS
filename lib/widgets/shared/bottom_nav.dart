import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// 5-tab bottom navigation used across all meta screens (Menu, Map, Shop,
/// Achievements, Profile). NOT shown during gameplay (`/game/:level`).
///
/// The active tab is rendered as an elevated gold-bordered purple card with
/// blue accent fill, while inactive tabs are subdued purple icons + label.
enum BottomNavTab {
  home,
  market,
  map,
  achievements,
  profile,
}

extension BottomNavTabRoute on BottomNavTab {
  String get route {
    switch (this) {
      case BottomNavTab.home:
        return '/menu';
      case BottomNavTab.market:
        return '/shop';
      case BottomNavTab.map:
        return '/map';
      case BottomNavTab.achievements:
        return '/achievements';
      case BottomNavTab.profile:
        return '/profile';
    }
  }

  String get label {
    switch (this) {
      case BottomNavTab.home:
        return 'Ana Sayfa';
      case BottomNavTab.market:
        return 'Market';
      case BottomNavTab.map:
        return 'Harita';
      case BottomNavTab.achievements:
        return 'Başarımlar';
      case BottomNavTab.profile:
        return 'Profil';
    }
  }

  IconData get icon {
    switch (this) {
      case BottomNavTab.home:
        return Icons.home_rounded;
      case BottomNavTab.market:
        return Icons.shopping_cart_rounded;
      case BottomNavTab.map:
        return Icons.map_rounded;
      case BottomNavTab.achievements:
        return Icons.emoji_events_rounded;
      case BottomNavTab.profile:
        return Icons.person_rounded;
    }
  }
}

class PatPatBottomNav extends StatelessWidget {
  final BottomNavTab activeTab;

  const PatPatBottomNav({
    super.key,
    required this.activeTab,
  });

  void _navigate(BuildContext context, BottomNavTab tab) {
    if (tab == activeTab) return;
    context.go(tab.route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.panelPurpleDark.withAlpha(200),
            GameColors.panelPurpleDark,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: GameColors.goldFrameMid.withAlpha(160),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BottomNavTab.values.map((tab) {
              return _NavItem(
                tab: tab,
                isActive: tab == activeTab,
                onTap: () => _navigate(context, tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: isActive
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameColors.buttonBlue,
                      GameColors.buttonBlueDark,
                    ],
                  ),
                  border: Border.all(
                    color: GameColors.goldFrameMid,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.buttonBlue.withAlpha(140),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 24,
                color: isActive
                    ? Colors.white
                    : Colors.white.withAlpha(160),
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(160),
                    blurRadius: 4,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withAlpha(180),
                  letterSpacing: 0.2,
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
        ),
      ),
    );
  }
}
