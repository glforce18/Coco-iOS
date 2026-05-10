import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Small badge chip — used for level number, region label, status badges.
class IslandChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? bg;
  final Color? fg;
  final double fontSize;
  final EdgeInsets padding;

  const IslandChip({
    super.key,
    required this.text,
    this.icon,
    this.bg,
    this.fg,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final actualBg = bg ?? TT.gold;
    final actualFg = fg ?? TT.sandLight;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(actualBg, Colors.white, 0.25) ?? actualBg,
            actualBg,
            Color.lerp(actualBg, Colors.black, 0.25) ?? actualBg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: TT.goldDeep.withAlpha(180), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: actualFg, size: fontSize + 2, shadows: [
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 3, offset: const Offset(0, 1)),
            ]),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: actualFg,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black.withAlpha(190), blurRadius: 3, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ribbon banner — sash with sharp angled tail, used for "Yeni!", "Premium!", etc.
class IslandRibbon extends StatelessWidget {
  final String text;
  final Color color;
  const IslandRibbon({super.key, required this.text, this.color = TT.coral});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 22, 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, 0.25) ?? color,
              color,
              Color.lerp(color, Colors.black, 0.3) ?? color,
            ],
          ),
        ),
        child: Text(
          text,
          style: TT.labelChip.copyWith(fontSize: 12),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width - 10, 0)
      ..lineTo(s.width, s.height / 2)
      ..lineTo(s.width - 10, s.height)
      ..lineTo(0, s.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
