import 'package:flutter/material.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

class IslandNavTab {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isCenter; // raised play tab
  const IslandNavTab({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCenter = false,
  });
}

/// Tropical bottom nav — driftwood plank with gold-trim, raised center play tab.
class IslandBottomNav extends StatefulWidget {
  final List<IslandNavTab> tabs;
  final int activeIndex;

  const IslandBottomNav({
    super.key,
    required this.tabs,
    required this.activeIndex,
  });

  @override
  State<IslandBottomNav> createState() => _IslandBottomNavState();
}

class _IslandBottomNavState extends State<IslandBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // plank
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.goldShine, TT.gold, TT.goldDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(160),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: TT.gold.withAlpha(100),
                        blurRadius: 26,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(33),
                            gradient: TT.driftPanelGradient,
                            border: Border(
                              top: BorderSide(color: Colors.white.withAlpha(80), width: 1.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              for (int i = 0; i < widget.tabs.length; i++)
                                Expanded(
                                  child: widget.tabs[i].isCenter
                                      ? const SizedBox.shrink()
                                      : _NavTab(
                                          tab: widget.tabs[i],
                                          active: i == widget.activeIndex,
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Continuously sweeping highlight band across the plank
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(33),
                          child: AnimatedBuilder(
                            animation: _shimmerCtrl,
                            builder: (_, __) {
                              final t = _shimmerCtrl.value;
                              return IgnorePointer(
                                child: Align(
                                  alignment: Alignment(-1.4 + 2.8 * t, -1),
                                  child: Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.white.withAlpha(0),
                                          Colors.white.withAlpha(50),
                                          Colors.white.withAlpha(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // raised center play
              for (int i = 0; i < widget.tabs.length; i++)
                if (widget.tabs[i].isCenter)
                  Align(
                    alignment: Alignment(-1.0 + (i + 0.5) * 2 / widget.tabs.length, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: _CenterPlayTab(
                        tab: widget.tabs[i],
                        active: i == widget.activeIndex,
                        shimmerCtrl: _shimmerCtrl,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IslandNavTab tab;
  final bool active;
  const _NavTab({required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? TT.goldShine : TT.sandLight.withAlpha(180);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tab.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tab.icon,
            color: color,
            size: 28,
            shadows: [
              if (active)
                BoxShadow(
                  color: TT.goldShine.withAlpha(180),
                  blurRadius: 14,
                  offset: Offset.zero,
                ),
              Shadow(
                color: Colors.black.withAlpha(190),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
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
      ),
    );
  }
}

class _CenterPlayTab extends StatelessWidget {
  final IslandNavTab tab;
  final bool active;
  final AnimationController shimmerCtrl;
  const _CenterPlayTab({
    required this.tab,
    required this.active,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tab.onTap,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsating outer halo ring — draws eye to primary action
            AnimatedBuilder(
              animation: shimmerCtrl,
              builder: (_, __) {
                final t = shimmerCtrl.value;
                final scale = 0.85 + 0.18 * t;
                final alpha = ((1 - t) * 200).toInt().clamp(0, 200);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: TT.goldShine.withAlpha(alpha), width: 3),
                      boxShadow: [
                        BoxShadow(color: TT.gold.withAlpha((alpha * 0.6).toInt()), blurRadius: 14, spreadRadius: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(180),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: TT.gold.withAlpha(180),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [TT.coralLight, TT.coral, TT.coralDark],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(color: Colors.white.withAlpha(180), width: 2),
                ),
                child: Icon(
                  tab.icon,
                  color: Colors.white,
                  size: 38,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(220),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
