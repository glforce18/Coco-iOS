import 'package:flutter/material.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Color variants for [GoldButton]. Each variant defines a base + dark shade
/// used for the inner gradient. The gold border + highlights are constant.
enum GoldButtonColor {
  green,
  blue,
  purple,
  gold,
  red,
}

/// Size variants for [GoldButton] — controls padding, font size, height.
enum GoldButtonSize {
  small, // booster pills, secondary actions
  medium, // dialog buttons
  large, // primary CTA (OYNA, Giriş Yap)
}

/// Royal Match-style 3D button with gold border, gradient fill, press feedback.
///
/// Visual layers:
/// - Outer drop shadow (depth)
/// - Gold metallic border (4-stop gradient)
/// - Inner color fill (top-light → bottom-dark gradient)
/// - Top highlight stroke (1px white-ish, simulates light reflection)
/// - Centered label (+ optional leading icon/widget)
///
/// Pressed state: scales to 0.95, removes drop shadow, slight darken.
class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final GoldButtonColor color;
  final GoldButtonSize size;
  final IconData? icon;
  final Widget? leading;
  final double? width;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = GoldButtonColor.green,
    this.size = GoldButtonSize.medium,
    this.icon,
    this.leading,
    this.width,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color light, Color dark}) _colors() {
    switch (widget.color) {
      case GoldButtonColor.green:
        return (light: GameColors.buttonGreen, dark: GameColors.buttonGreenDark);
      case GoldButtonColor.blue:
        return (light: GameColors.buttonBlue, dark: GameColors.buttonBlueDark);
      case GoldButtonColor.purple:
        return (
          light: GameColors.buttonPurple,
          dark: GameColors.buttonPurpleDark
        );
      case GoldButtonColor.gold:
        return (
          light: GameColors.goldFrameBright,
          dark: GameColors.goldFrameDeep
        );
      case GoldButtonColor.red:
        return (light: GameColors.cherryRed, dark: GameColors.cherryRedDark);
    }
  }

  ({double height, double fontSize, EdgeInsets pad, double radius, double border})
      _metrics() {
    switch (widget.size) {
      case GoldButtonSize.small:
        return (
          height: 44,
          fontSize: 14,
          pad: const EdgeInsets.symmetric(horizontal: 14),
          radius: 22,
          border: 2.5,
        );
      case GoldButtonSize.medium:
        return (
          height: 56,
          fontSize: 18,
          pad: const EdgeInsets.symmetric(horizontal: 24),
          radius: 28,
          border: 3,
        );
      case GoldButtonSize.large:
        return (
          height: 64,
          fontSize: 22,
          pad: const EdgeInsets.symmetric(horizontal: 32),
          radius: 32,
          border: 3.5,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final m = _metrics();
    final disabled = widget.onPressed == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled ? null : (_) => _ctrl.reverse(),
      onTapCancel: disabled ? null : () => _ctrl.reverse(),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, _) {
          final isPressed = _ctrl.value > 0;
          return Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: disabled ? 0.5 : 1.0,
              child: Container(
                width: widget.width,
                height: m.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(m.radius),
                  boxShadow: isPressed
                      ? []
                      : [
                          // Drop shadow under button
                          BoxShadow(
                            color: Colors.black.withAlpha(180),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          // Color glow halo
                          BoxShadow(
                            color: colors.dark.withAlpha(180),
                            blurRadius: 24,
                            spreadRadius: -2,
                          ),
                          // Outer gold sheen
                          BoxShadow(
                            color: GameColors.goldFrameMid.withAlpha(100),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameColors.goldHighlight,
                      GameColors.goldFrameBright,
                      GameColors.goldFrameMid,
                      GameColors.goldFrameDeep,
                      GameColors.goldFrameMid,
                      GameColors.goldFrameBright,
                      GameColors.goldHighlight,
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
                        Color.lerp(colors.light, Colors.white, 0.25) ??
                            colors.light,
                        colors.light,
                        colors.dark,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                    // Top highlight stroke (simulates light hitting top edge)
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withAlpha(180),
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
                          size: m.fontSize + 4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(180),
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
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(200),
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
      ),
    );
  }
}
