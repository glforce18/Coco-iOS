import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

enum IslandButtonColor {
  palm, // green — primary play CTA
  coral, // red — danger / strong CTA
  bamboo, // wood — secondary
  lagoon, // turquoise — info / accent
  gold, // premium / shop
}

enum IslandButtonSize { small, medium, large, xlarge }

/// Tropical 3D button — gold metallic border + tropical-colored fill.
/// Layers:
/// - Outer drop shadow + warm halo
/// - Treasure-gold metallic border (7-stop highlight gradient)
/// - Inner colored fill (top-light → bottom-dark)
/// - Top white sheen (1.5px highlight)
/// - Optional leading icon/widget
/// - Centered label with embossed shadow
///
/// Pressed state: scale 0.94, drop shadow removed, slight darken.
class IslandButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IslandButtonColor color;
  final IslandButtonSize size;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final bool fullWidth;

  const IslandButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = IslandButtonColor.palm,
    this.size = IslandButtonSize.medium,
    this.icon,
    this.leading,
    this.width,
    this.fullWidth = false,
  });

  @override
  State<IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<IslandButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color light, Color mid, Color dark, Color glow}) _colors() {
    switch (widget.color) {
      case IslandButtonColor.palm:
        return (
          light: TT.palmLight,
          mid: TT.palm,
          dark: TT.palmDark,
          glow: TT.palm,
        );
      case IslandButtonColor.coral:
        return (
          light: TT.coralLight,
          mid: TT.coral,
          dark: TT.coralDark,
          glow: TT.coral,
        );
      case IslandButtonColor.bamboo:
        return (
          light: TT.bambooLight,
          mid: TT.bamboo,
          dark: TT.bambooDark,
          glow: TT.bamboo,
        );
      case IslandButtonColor.lagoon:
        return (
          light: TT.lagoonLight,
          mid: TT.lagoon,
          dark: TT.lagoonDark,
          glow: TT.lagoon,
        );
      case IslandButtonColor.gold:
        return (
          light: TT.goldShine,
          mid: TT.goldBright,
          dark: TT.goldDeep,
          glow: TT.gold,
        );
    }
  }

  ({double height, double fontSize, EdgeInsets pad, double radius, double border, double iconSize}) _metrics() {
    switch (widget.size) {
      case IslandButtonSize.small:
        return (
          height: 42,
          fontSize: 13,
          pad: const EdgeInsets.symmetric(horizontal: 14),
          radius: 21,
          border: 2.5,
          iconSize: 16,
        );
      case IslandButtonSize.medium:
        return (
          height: 56,
          fontSize: 17,
          pad: const EdgeInsets.symmetric(horizontal: 24),
          radius: 28,
          border: 3,
          iconSize: 22,
        );
      case IslandButtonSize.large:
        return (
          height: 68,
          fontSize: 22,
          pad: const EdgeInsets.symmetric(horizontal: 32),
          radius: 34,
          border: 3.5,
          iconSize: 26,
        );
      case IslandButtonSize.xlarge:
        return (
          height: 84,
          fontSize: 28,
          pad: const EdgeInsets.symmetric(horizontal: 40),
          radius: 42,
          border: 4,
          iconSize: 32,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final m = _metrics();
    final disabled = widget.onPressed == null;

    final btn = AnimatedBuilder(
      animation: _scale,
      builder: (context, _) {
        final isPressed = _ctrl.value > 0;
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: Container(
              width: widget.width ?? (widget.fullWidth ? double.infinity : null),
              height: m.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(m.radius),
                boxShadow: isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(170),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: colors.glow.withAlpha(140),
                          blurRadius: 28,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: TT.gold.withAlpha(90),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TT.goldShine,
                    TT.goldBright,
                    TT.gold,
                    TT.goldDeep,
                    TT.gold,
                    TT.goldBright,
                    TT.goldShine,
                  ],
                  stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
                ),
              ),
              padding: EdgeInsets.all(m.border),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(m.radius - m.border),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(colors.light, Colors.white, 0.3) ?? colors.light,
                      colors.light,
                      colors.mid,
                      colors.dark,
                    ],
                    stops: const [0.0, 0.25, 0.6, 1.0],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withAlpha(200),
                      width: 2,
                    ),
                  ),
                ),
                padding: m.pad,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 8),
                    ] else if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: m.iconSize,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(190),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: m.fontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(210),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            Shadow(
                              color: colors.dark,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled ? null : (_) => _ctrl.reverse(),
      onTapCancel: disabled ? null : () => _ctrl.reverse(),
      onTap: disabled ? null : widget.onPressed,
      child: btn,
    );
  }
}
