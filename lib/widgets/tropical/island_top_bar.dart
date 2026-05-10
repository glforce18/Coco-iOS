import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Top stats bar — tropical "driftwood plank" with gold-trim chips for stars,
/// coins, hearts. Optional leading + trailing widgets (avatar, settings cog).
class IslandTopBar extends StatelessWidget {
  final int stars;
  final int coins;
  final int hearts;
  final int maxHearts;
  final String? heartTimer;
  final Widget? leading; // typically avatar
  final List<Widget> trailing; // typically settings, notifications

  const IslandTopBar({
    super.key,
    required this.stars,
    required this.coins,
    required this.hearts,
    this.maxHearts = 5,
    this.heartTimer,
    this.leading,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: _StatPlank(
                items: [
                  _StatItem(
                    icon: Icons.star_rounded,
                    iconColor: TT.starFilled,
                    value: _fmt(stars),
                  ),
                  _StatItem(
                    icon: Icons.monetization_on_rounded,
                    iconColor: TT.goldBright,
                    value: _fmt(coins),
                  ),
                  _StatItem(
                    icon: Icons.favorite_rounded,
                    iconColor: TT.coral,
                    value: heartTimer ?? '$hearts/$maxHearts',
                    showPlus: hearts < maxHearts && heartTimer == null,
                  ),
                ],
              ),
            ),
            for (final t in trailing) ...[const SizedBox(width: 8), t],
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    if (v < 1000) return '$v';
    if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}K';
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
}

class _StatItem {
  final IconData icon;
  final Color iconColor;
  final String value;
  final bool showPlus;
  _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.showPlus = false,
  });
}

class _StatPlank extends StatelessWidget {
  final List<_StatItem> items;
  const _StatPlank({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: TT.gold.withAlpha(100),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: TT.driftPanelGradient,
          border: Border(top: BorderSide(color: Colors.white.withAlpha(80), width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [for (final it in items) _StatChip(item: it)],
        ),
      ),
    );
  }
}

class _StatChip extends StatefulWidget {
  final _StatItem item;
  const _StatChip({required this.item});

  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int? _lastNumeric;
  // -1 floating label data (heart loss only).
  int _floatSeq = 0;

  int? _parseLeadingInt(String v) {
    final m = RegExp(r'^-?\d+').firstMatch(v);
    if (m == null) return null;
    return int.tryParse(m.group(0)!);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lastNumeric = _parseLeadingInt(widget.item.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _StatChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newN = _parseLeadingInt(widget.item.value);
    final oldN = _lastNumeric;
    _lastNumeric = newN;
    if (newN != null && oldN != null && newN < oldN) {
      _floatSeq++;
      _ctrl.forward(from: 0);
    }
  }

  bool get _isHeart => widget.item.icon == Icons.favorite_rounded;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Pulse: punch down to 0.82 in first 12%, spring back via elastic.
        double scale = 1.0;
        if (_ctrl.isAnimating || t > 0) {
          if (t < 0.12) {
            scale = 1.0 - (t / 0.12) * 0.18;
          } else {
            final k = (t - 0.12) / 0.88;
            scale = 0.82 + Curves.elasticOut.transform(k.clamp(0, 1)) * 0.18;
          }
        }
        // Red flash overlay alpha (heart-only).
        final flashAlpha = _isHeart && t > 0
            ? ((1 - (t * 1.4).clamp(0, 1)) * 200).toInt()
            : 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: scale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.item.iconColor.withAlpha(220),
                              widget.item.iconColor.withAlpha(140),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.iconColor.withAlpha(160),
                              blurRadius: 8,
                              spreadRadius: -1,
                            ),
                            if (flashAlpha > 0)
                              BoxShadow(
                                color: const Color(0xFFFF3B30).withAlpha(flashAlpha),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: Colors.white,
                          size: 18,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(180),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      // Red flash overlay on the icon itself.
                      if (flashAlpha > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF3B30)
                                  .withAlpha((flashAlpha * 0.6).toInt()),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.item.value,
                    style: TT.numberStat.copyWith(fontSize: 15, color: TT.sandLight),
                  ),
                  if (widget.item.showPlus) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: TT.palmButtonGradient,
                        boxShadow: [
                          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ],
                ],
              ),
            ),
            // Floating "-1" label for heart loss.
            if (_isHeart && _ctrl.isAnimating)
              Positioned(
                left: 4,
                top: -6 - (24 * Curves.easeOutCubic.transform(t)),
                child: Opacity(
                  opacity: t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3).clamp(0, 1),
                  child: Text(
                    '-1',
                    key: ValueKey('hloss-$_floatSeq'),
                    style: TextStyle(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                        const Shadow(color: Color(0xFFFF3B30), blurRadius: 8, offset: Offset.zero),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Circular icon button for top corners (settings, profile, notifications).
class IslandCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final double size;

  const IslandCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: TT.gold.withAlpha(100),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: bg != null
                ? LinearGradient(
                    colors: [
                      Color.lerp(bg!, Colors.white, 0.25) ?? bg!,
                      bg!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : TT.driftPanelGradient,
            border: Border.all(color: Colors.white.withAlpha(80), width: 1.2),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(190),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
