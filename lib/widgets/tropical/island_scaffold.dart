import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Standard tropical scaffold with image background, optional dark overlay,
/// and content area. Used by every meta screen.
class IslandScaffold extends StatelessWidget {
  final String backgroundAsset;
  final Widget child;
  final double overlayOpacity;
  final Widget? bottomBar;
  final Color? overlayTint;
  final bool extendBodyBehindBottom;

  const IslandScaffold({
    super.key,
    required this.backgroundAsset,
    required this.child,
    this.overlayOpacity = 0.32,
    this.bottomBar,
    this.overlayTint,
    this.extendBodyBehindBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: extendBodyBehindBottom,
      backgroundColor: TT.oceanDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BG image
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: TT.skyOceanGradient),
            ),
          ),
          // dark overlay for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (overlayTint ?? Colors.black).withValues(alpha: overlayOpacity * 0.6),
                  (overlayTint ?? Colors.black).withValues(alpha: overlayOpacity),
                  (overlayTint ?? Colors.black).withValues(alpha: overlayOpacity * 1.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // content
          SafeArea(child: child),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Sand-colored translucent card surface used inside scaffolds.
class IslandSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double radius;
  final Color? bg;

  const IslandSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 24,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: bg != null
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCCFFF1D9),
                  Color(0xBBF5DBA8),
                ],
              ),
        color: bg,
        border: Border.all(color: TT.gold.withAlpha(140), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section title — sand surface ribbon with gold trim.
class IslandSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color color;

  const IslandSectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.color = TT.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.driftWood, TT.driftWoodDark],
        ),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: color.withAlpha(100), blurRadius: 14, spreadRadius: -1),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: TT.goldShine, size: 22, shadows: [
              Shadow(color: Colors.black.withAlpha(200), blurRadius: 4, offset: const Offset(0, 1)),
            ]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TT.titleMedium.copyWith(
                color: TT.sandLight,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Hero header — used at top of meta screens (back button, title, optional action).
class IslandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const IslandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          if (onBack != null)
            _HeaderCircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack)
          else
            const SizedBox(width: 48),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TT.displayMedium.copyWith(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TT.bodySmall.copyWith(
                      color: TT.sandLight.withAlpha(220),
                      shadows: [
                        Shadow(color: Colors.black.withAlpha(180), blurRadius: 3, offset: const Offset(0, 1)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 8), a],
        ],
      ),
    );
  }
}

class _HeaderCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HeaderCircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: TT.driftPanelGradient,
            border: Border.all(color: Colors.white.withAlpha(60), width: 1),
          ),
          child: Icon(icon, color: TT.sandLight, size: 22, shadows: [
            Shadow(color: Colors.black.withAlpha(200), blurRadius: 3, offset: const Offset(0, 1)),
          ]),
        ),
      ),
    );
  }
}
