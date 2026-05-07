import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/screens/daily_reward_screen.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/level_start_popup.dart';
import 'package:patpat_game/widgets/no_lives_popup.dart';
import 'package:patpat_game/widgets/shared/bottom_nav.dart';
import 'package:patpat_game/widgets/shared/top_stats_bar.dart';

// ---------------------------------------------------------------------------
// Region enum -> background asset mapping
// ---------------------------------------------------------------------------
const _regionAssets = <GameRegion, String>{
  GameRegion.candyGarden: 'assets/backgrounds/map_bg_candy_garden.png',
  GameRegion.colorHill: 'assets/backgrounds/map_bg_harvest_hill.png',
  GameRegion.balloonValley: 'assets/backgrounds/map_bg_balloon_valley.png',
  GameRegion.sparkleForest: 'assets/backgrounds/map_bg_sparkle_forest.png',
  GameRegion.funLand: 'assets/backgrounds/map_bg_fun_land.png',
  GameRegion.dreamWorld: 'assets/backgrounds/map_bg_dream_world.png',
};

// ---------------------------------------------------------------------------
// MapScreen — main entry widget (path-based zigzag progression)
// ---------------------------------------------------------------------------
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late GameRegion _selectedRegion;
  bool _showNoLivesPopup = false;
  int? _showLevelStartPopupFor;
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    final currentLevel = ref.read(playerProgressProvider).currentLevel;
    _selectedRegion = GameRegion.forLevel(currentLevel);
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Auto-show daily reward popup if not claimed today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(playerProgressProvider.notifier);
      if (notifier.isDailyRewardAvailable) {
        showDailyRewardPopup(context, ref);
      }
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final progress = ref.read(playerProgressProvider);
    final currentLevel = progress.currentLevel;
    final levelInRegion = currentLevel - _selectedRegion.startLevel;
    if (levelInRegion < 0) return;

    final rowIndex = levelInRegion ~/ 3;
    final levelCount =
        _selectedRegion.endLevel - _selectedRegion.startLevel + 1;
    final totalRows = (levelCount / 3).ceil();
    // The list is bottom-up (reversed), so row 0 of the reversed list is the
    // last game row. We need to scroll to (totalRows - rowIndex - 1) * rowHeight.
    final rowHeight = 110.0;
    final targetOffset = (totalRows - rowIndex - 1) * rowHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxExtent),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _selectRegion(GameRegion region) {
    setState(() => _selectedRegion = region);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient fallback (full opacity, NO heavy overlay)
          _RegionBackground(region: _selectedRegion),

          // Very subtle vignette only at the very top + bottom edges so the
          // status bar / bottom nav stay legible. Body of the map keeps its
          // full color so the waterfall, mushrooms and crystals shine through.
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(60),
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(90),
                  ],
                  stops: const [0.0, 0.12, 0.78, 1.0],
                ),
              ),
            ),
          ),

          // Decorative sparkle particles
          _SparkleParticles(animation: _sparkleController),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Fixed top stats bar (mockup M1/M4 style)
                TopStatsBar(
                  stars: progress.totalStars,
                  coins: progress.coins,
                  lives: progress.lives,
                  onProfileTap: () => context.go('/menu'),
                  onSettingsTap: () => context.go('/profile'),
                  onNotificationTap: () => context.go('/spin'),
                ),

                const SizedBox(height: 4),

                // Region selector tabs (background changes per region)
                _RegionSelector(
                  selectedRegion: _selectedRegion,
                  totalStars: progress.totalStars,
                  onRegionSelected: _selectRegion,
                ),

                const SizedBox(height: 4),

                // Path-based level map (zigzag)
                Expanded(
                  child: _ZigzagPath(
                    scrollController: _scrollController,
                    region: _selectedRegion,
                    progress: progress,
                    pulseAnimation: _pulseController,
                    sparkleAnimation: _sparkleController,
                    onLevelTap: (level) {
                      setState(() => _showLevelStartPopupFor = level);
                    },
                  ),
                ),

                // Star milestone progress + region badge
                _StarMilestoneBar(
                  totalStars: progress.totalStars,
                  region: _selectedRegion,
                ),

                // Bottom nav (Map tab active)
                const PatPatBottomNav(activeTab: BottomNavTab.map),
              ],
            ),
          ),

          // Daily challenge floating button
          SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _DailyChallengeButton(
                onTap: () {
                  final notifier = ref.read(playerProgressProvider.notifier);
                  if (notifier.isDailyRewardAvailable) {
                    showDailyRewardPopup(context, ref);
                  }
                },
              ),
            ),
          ),

          // Level start popup overlay
          if (_showLevelStartPopupFor != null)
            LevelStartPopup(
              level: _showLevelStartPopupFor!,
              earnedStars: progress.starsForLevel(_showLevelStartPopupFor!),
              highScore: progress.highScores[_showLevelStartPopupFor!] ?? 0,
              onPlay: () {
                final level = _showLevelStartPopupFor!;
                setState(() => _showLevelStartPopupFor = null);
                progress.regenerateLives();
                if (progress.lives <= 0) {
                  setState(() => _showNoLivesPopup = true);
                } else {
                  ref.read(playerProgressProvider.notifier).useLife();
                  context.go('/game/$level');
                }
              },
              onClose: () {
                setState(() => _showLevelStartPopupFor = null);
              },
            ),

          // No lives popup overlay
          if (_showNoLivesPopup)
            NoLivesPopup(
              lastLifeLostTime: progress.lastLifeLostTime,
              vipActive: progress.vipActive,
              removeAdsPurchased: progress.removeAdsPurchased,
              onLifeGranted: () {
                final p = ref.read(playerProgressProvider);
                p.lives = (p.lives + 1).clamp(0, 5);
                setState(() => _showNoLivesPopup = false);
              },
              onClose: () {
                setState(() => _showNoLivesPopup = false);
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkle particles — floating background decoration
// ---------------------------------------------------------------------------
class _SparkleParticles extends StatelessWidget {
  final AnimationController animation;
  const _SparkleParticles({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _SparkleParticlePainter(animation.value),
        );
      },
    );
  }
}

class _SparkleParticlePainter extends CustomPainter {
  final double t;
  _SparkleParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * 2 * pi;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final sparkSize = 1.5 + rng.nextDouble() * 2.5;

      final x = baseX + sin(t * 2 * pi * speed + phase) * 8;
      final y = baseY + cos(t * 2 * pi * speed + phase * 0.7) * 6;
      final alpha = (80 + 80 * sin(t * 2 * pi * speed + phase)).toInt();

      final hue = (rng.nextDouble() * 60 + 30) % 360; // warm hues
      final color =
          HSLColor.fromAHSL(1, hue, 0.8, 0.8).toColor().withAlpha(alpha);
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), sparkSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter old) => true;
}

// ---------------------------------------------------------------------------
// Region Background — image with gradient fallback
// ---------------------------------------------------------------------------
class _RegionBackground extends StatelessWidget {
  final GameRegion region;
  const _RegionBackground({required this.region});

  @override
  Widget build(BuildContext context) {
    final assetPath = _regionAssets[region];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _GradientFallback(region: region),
      );
    }
    return _GradientFallback(region: region);
  }
}

class _GradientFallback extends StatelessWidget {
  final GameRegion region;
  const _GradientFallback({required this.region});

  @override
  Widget build(BuildContext context) {
    final index = GameRegion.values.indexOf(region);
    final hue = (index * 30.0) % 360;
    final topColor = HSLColor.fromAHSL(1, hue, 0.6, 0.25).toColor();
    final bottomColor =
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.7, 0.12).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RegionSelector — horizontal scrollable tabs
// ---------------------------------------------------------------------------
class _RegionSelector extends StatefulWidget {
  final GameRegion selectedRegion;
  final int totalStars;
  final ValueChanged<GameRegion> onRegionSelected;

  const _RegionSelector({
    required this.selectedRegion,
    required this.totalStars,
    required this.onRegionSelected,
  });

  @override
  State<_RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<_RegionSelector> {
  @override
  Widget build(BuildContext context) {
    final regions = GameRegion.values;
    final currentIndex = regions.indexOf(widget.selectedRegion);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < regions.length - 1;
    final nextRegion = hasNext ? regions[currentIndex + 1] : null;
    final nextUnlocked =
        nextRegion != null && widget.totalStars >= nextRegion.starsRequired;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous chevron (only if available)
          _RegionChevron(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev
                ? () => widget.onRegionSelected(regions[currentIndex - 1])
                : null,
          ),
          const SizedBox(width: 8),

          // Center BIG gold pill — the active region
          Flexible(
            child: _ActiveRegionPill(region: widget.selectedRegion),
          ),

          const SizedBox(width: 8),

          // Next chevron (locked indicator if next region is locked)
          _RegionChevron(
            icon: Icons.chevron_right_rounded,
            enabled: nextUnlocked,
            locked: hasNext && !nextUnlocked,
            starsRequired: hasNext && !nextUnlocked
                ? nextRegion!.starsRequired
                : null,
            onTap: nextUnlocked
                ? () => widget.onRegionSelected(regions[currentIndex + 1])
                : null,
          ),
        ],
      ),
    );
  }
}

/// Big centered gold-bordered pill showing the active region name (mockup M1).
class _ActiveRegionPill extends StatelessWidget {
  final GameRegion region;
  const _ActiveRegionPill({required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.goldFrameBright,
            GameColors.goldHighlight,
            GameColors.goldFrameMid,
            GameColors.goldFrameDeep,
            GameColors.goldFrameMid,
            GameColors.goldFrameBright,
          ],
          stops: [0.0, 0.18, 0.4, 0.55, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(140),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.panelPurpleLight,
              GameColors.panelPurple,
              GameColors.panelPurpleDark,
            ],
          ),
        ),
        child: Text(
          region.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(220),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              const Shadow(
                color: GameColors.panelPurpleDark,
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round gold-bordered chevron button for region nav (prev/next).
class _RegionChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool locked;
  final int? starsRequired;
  final VoidCallback? onTap;

  const _RegionChevron({
    required this.icon,
    required this.enabled,
    this.locked = false,
    this.starsRequired,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              color: Colors.black.withAlpha(150),
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
                GameColors.panelPurple,
                GameColors.panelPurpleDark,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: locked
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.white.withAlpha(180),
                      size: 16,
                    ),
                    if (starsRequired != null)
                      Positioned(
                        bottom: -2,
                        child: Text(
                          '$starsRequired★',
                          style: const TextStyle(
                            color: GameColors.starGoldFilled,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                )
              : Icon(
                  icon,
                  color: enabled
                      ? Colors.white
                      : Colors.white.withAlpha(80),
                  size: 24,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZigzagPath — the core path-based level progression with CustomPaint lines
// ---------------------------------------------------------------------------
class _ZigzagPath extends StatelessWidget {
  final ScrollController scrollController;
  final GameRegion region;
  final PlayerProgress progress;
  final AnimationController pulseAnimation;
  final AnimationController sparkleAnimation;
  final ValueChanged<int> onLevelTap;

  const _ZigzagPath({
    required this.scrollController,
    required this.region,
    required this.progress,
    required this.pulseAnimation,
    required this.sparkleAnimation,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelCount = region.endLevel - region.startLevel + 1;
    // Build rows: 3 levels per row, snake pattern
    final List<_PathRow> rows = [];
    for (int i = 0; i < levelCount; i += 3) {
      final rowLevels = <int>[];
      for (int j = 0; j < 3 && (i + j) < levelCount; j++) {
        rowLevels.add(region.startLevel + i + j);
      }
      final rowIndex = i ~/ 3;
      final isReversed = rowIndex.isOdd;
      if (isReversed) {
        rows.add(
            _PathRow(levels: rowLevels.reversed.toList(), rowIndex: rowIndex));
      } else {
        rows.add(_PathRow(levels: rowLevels, rowIndex: rowIndex));
      }
    }
    // Reverse so level 1 is at the bottom
    final reversedRows = rows.reversed.toList();

    // +1 for the treasure chest header at index 0 (top of path = boss reward)
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: reversedRows.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Treasure chest at the very top of the path
          return _TreasureChest(
            sparkleAnimation: sparkleAnimation,
            isUnlocked: progress.starsForLevel(region.endLevel) > 0,
          );
        }
        final rowIdx = index - 1;
        final row = reversedRows[rowIdx];
        final isLastRow = rowIdx == reversedRows.length - 1;
        final hasConnectionBelow = rowIdx < reversedRows.length - 1;
        return _PathRowWidget(
          row: row,
          progress: progress,
          pulseAnimation: pulseAnimation,
          sparkleAnimation: sparkleAnimation,
          onLevelTap: onLevelTap,
          isLastRow: isLastRow,
          hasConnectionBelow: hasConnectionBelow,
          nextRowIndex:
              isLastRow ? null : reversedRows[rowIdx + 1].rowIndex,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// TreasureChest — decorative chest at the top of the path (mockup M1)
// Rendered with a custom painter for a clean glowing gold chest look,
// with a pulsing sparkle when the region is complete.
// ---------------------------------------------------------------------------
class _TreasureChest extends StatelessWidget {
  final AnimationController sparkleAnimation;
  final bool isUnlocked;

  const _TreasureChest({
    required this.sparkleAnimation,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: sparkleAnimation,
        builder: (context, _) {
          final t = sparkleAnimation.value;
          final glowAlpha = isUnlocked
              ? (180 + (60 * sin(t * 2 * pi)).toInt())
              : 90;
          // Big glowing chest centered horizontally near the top of the path.
          return Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Inner-most warm glow
                  BoxShadow(
                    color: GameColors.goldHighlight.withAlpha(glowAlpha),
                    blurRadius: 36,
                    spreadRadius: 10,
                  ),
                  // Mid glow
                  BoxShadow(
                    color: GameColors.goldFrameMid.withAlpha(glowAlpha),
                    blurRadius: 60,
                    spreadRadius: 16,
                  ),
                  // Outer wide glow
                  BoxShadow(
                    color: GameColors.goldFrameBright
                        .withAlpha((glowAlpha * 0.5).toInt()),
                    blurRadius: 90,
                    spreadRadius: 24,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _ChestPainter(
                  sparkleT: t,
                  unlocked: isUnlocked,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  final double sparkleT;
  final bool unlocked;

  _ChestPainter({required this.sparkleT, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chest body proportions
    final bodyTop = h * 0.42;
    final bodyBottom = h * 0.85;
    final bodyLeft = w * 0.15;
    final bodyRight = w * 0.85;

    // Chest lid (curved)
    final lidTop = h * 0.18;
    final lidBottom = h * 0.45;

    // Wood (dark purple-brown body)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: unlocked
            ? const [
                GameColors.panelPurple,
                GameColors.panelPurpleDark,
              ]
            : [
                Colors.grey.shade700,
                Colors.grey.shade900,
              ],
      ).createShader(Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom));

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Gold body trim (top + bottom + sides)
    final trimPaint = Paint()
      ..color = GameColors.goldFrameBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(bodyRect, trimPaint);

    // Vertical gold band (center of body)
    final bandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameColors.goldFrameBright,
          GameColors.goldFrameMid,
        ],
      ).createShader(Rect.fromLTRB(w * 0.45, bodyTop, w * 0.55, bodyBottom));
    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, bodyTop, w * 0.55, bodyBottom),
      bandPaint,
    );

    // Lock plate at center of body (gold square)
    final lockSize = w * 0.13;
    final lockRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: lockSize,
      height: lockSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lockRect, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.goldHighlight,
            GameColors.goldFrameMid,
          ],
        ).createShader(lockRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lockRect, const Radius.circular(2)),
      Paint()
        ..color = GameColors.goldFrameDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Lid (curved top)
    final lidPath = Path()
      ..moveTo(bodyLeft, lidBottom)
      ..lineTo(bodyLeft, lidTop + 8)
      ..quadraticBezierTo(
        w * 0.5,
        lidTop - 8,
        bodyRight,
        lidTop + 8,
      )
      ..lineTo(bodyRight, lidBottom)
      ..close();

    final lidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: unlocked
            ? const [
                GameColors.goldHighlight,
                GameColors.goldFrameMid,
                GameColors.goldFrameDeep,
              ]
            : [
                Colors.grey.shade400,
                Colors.grey.shade700,
              ],
      ).createShader(Rect.fromLTRB(bodyLeft, lidTop, bodyRight, lidBottom));
    canvas.drawPath(lidPath, lidPaint);

    // Lid outline
    canvas.drawPath(
      lidPath,
      Paint()
        ..color = GameColors.goldFrameDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Lid trim line at the seam
    canvas.drawLine(
      Offset(bodyLeft, lidBottom),
      Offset(bodyRight, lidBottom),
      Paint()
        ..color = GameColors.goldFrameDeep
        ..strokeWidth = 2,
    );

    // Sparkle stars around the chest (4 corners)
    if (unlocked) {
      final sparkPositions = [
        Offset(w * 0.1, h * 0.15),
        Offset(w * 0.92, h * 0.18),
        Offset(w * 0.08, h * 0.5),
        Offset(w * 0.92, h * 0.55),
      ];
      for (int i = 0; i < sparkPositions.length; i++) {
        final phase = i * 0.25;
        final spark = (sin((sparkleT + phase) * 2 * pi) + 1) / 2;
        final r = 2 + spark * 3;
        canvas.drawCircle(
          sparkPositions[i],
          r,
          Paint()
            ..color = GameColors.goldHighlight
                .withAlpha((180 * spark).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChestPainter old) =>
      old.sparkleT != sparkleT || old.unlocked != unlocked;
}

class _PathRow {
  final List<int> levels;
  final int rowIndex;
  const _PathRow({required this.levels, required this.rowIndex});
}

// ---------------------------------------------------------------------------
// PathRowWidget — a single row of 1-3 level nodes with connecting path
// ---------------------------------------------------------------------------
class _PathRowWidget extends StatelessWidget {
  final _PathRow row;
  final PlayerProgress progress;
  final AnimationController pulseAnimation;
  final AnimationController sparkleAnimation;
  final ValueChanged<int> onLevelTap;
  final bool isLastRow;
  final bool hasConnectionBelow;
  final int? nextRowIndex;

  const _PathRowWidget({
    required this.row,
    required this.progress,
    required this.pulseAnimation,
    required this.sparkleAnimation,
    required this.onLevelTap,
    required this.isLastRow,
    required this.hasConnectionBelow,
    this.nextRowIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _RowPathPainter(
          levelCount: row.levels.length,
          rowIndex: row.rowIndex,
          isLastRow: isLastRow,
          hasConnectionBelow: hasConnectionBelow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.levels.map((level) {
              return _LevelNode(
                level: level,
                progress: progress,
                pulseAnimation: pulseAnimation,
                sparkleAnimation: sparkleAnimation,
                onTap: () {
                  if (progress.isLevelUnlocked(level)) {
                    onLevelTap(level);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RowPathPainter — draws golden connecting path lines between nodes
// ---------------------------------------------------------------------------
class _RowPathPainter extends CustomPainter {
  final int levelCount;
  final int rowIndex;
  final bool isLastRow;
  final bool hasConnectionBelow;

  _RowPathPainter({
    required this.levelCount,
    required this.rowIndex,
    required this.isLastRow,
    required this.hasConnectionBelow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Three-layer path: outer dark shadow, mid gold-deep, top bright gold
    // — gives a thick "stone path" feel that pops on the bg.
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(160)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final outerPaint = Paint()
      ..color = GameColors.goldFrameDeep
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midPaint = Paint()
      ..color = GameColors.goldFrameMid
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = GameColors.goldFrameBright
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = GameColors.goldFrameMid.withAlpha(90)
      ..strokeWidth = 30
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final midY = size.height / 2;
    const padding = 16.0;
    final usableWidth = size.width - padding * 2;

    // Node center positions, matching _LevelNode column layout (110px wide).
    // Row uses spaceEvenly so we approximate centers as equal slots.
    double colCenter(int i) {
      final slotWidth = usableWidth / levelCount;
      return padding + slotWidth * (i + 0.5);
    }

    // Draw 3 layered strokes for each segment
    void drawStroke(Path p) {
      canvas.drawPath(p, glowPaint);
      canvas.drawPath(p, shadowPaint);
      canvas.drawPath(p, outerPaint);
      canvas.drawPath(p, midPaint);
      canvas.drawPath(p, innerPaint);
    }

    // ── Horizontal connecting curve between nodes in this row ──
    if (levelCount >= 2) {
      for (int i = 0; i < levelCount - 1; i++) {
        // Inset by node radius so the path tucks under the node
        final x1 = colCenter(i) + 50;
        final x2 = colCenter(i + 1) - 50;
        final midX = (x1 + x2) / 2;
        // Slight downward sag for organic feel
        final path = Path()
          ..moveTo(x1, midY)
          ..quadraticBezierTo(midX, midY + 14, x2, midY);
        drawStroke(path);
      }
    }

    // ── Vertical connecting curve to the next row (below in scroll order) ──
    if (hasConnectionBelow) {
      // Snake direction: even rows end on the right, odd rows on the left.
      // The next row (which is reversed) will start on the same side, so
      // we draw a downward curve on that side.
      final isReversed = rowIndex.isOdd;
      // The connection point is the *last* element in this row (which is the
      // rightmost on even rows / leftmost on odd rows after reversal).
      final connectIndex = isReversed ? 0 : levelCount - 1;
      final connectX = colCenter(connectIndex);
      final path = Path()
        ..moveTo(connectX, midY + 50)
        ..quadraticBezierTo(
          connectX + (isReversed ? -22 : 22),
          size.height + 4,
          connectX + (isReversed ? -8 : 8),
          size.height + 30,
        );
      drawStroke(path);
    }
  }

  @override
  bool shouldRepaint(covariant _RowPathPainter old) =>
      old.levelCount != levelCount ||
      old.rowIndex != rowIndex ||
      old.isLastRow != isLastRow ||
      old.hasConnectionBelow != hasConnectionBelow;
}

// ---------------------------------------------------------------------------
// LevelNode — circular level node on the path
// ---------------------------------------------------------------------------
enum _LevelState { locked, current, unlocked, completed }

class _LevelNode extends StatelessWidget {
  final int level;
  final PlayerProgress progress;
  final AnimationController pulseAnimation;
  final AnimationController sparkleAnimation;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.progress,
    required this.pulseAnimation,
    required this.sparkleAnimation,
    required this.onTap,
  });

  _LevelState get _state {
    if (!progress.isLevelUnlocked(level)) return _LevelState.locked;
    final stars = progress.starsForLevel(level);
    if (stars > 0) return _LevelState.completed;
    if (level == progress.currentLevel) return _LevelState.current;
    return _LevelState.unlocked;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final stars = progress.starsForLevel(level);
    final isCurrent = state == _LevelState.current;
    final isLocked = state == _LevelState.locked;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: isCurrent ? pulseAnimation : const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          final pulseVal = isCurrent ? pulseAnimation.value : 0.0;
          // BIG jewel sized node, like the reference (~95dp baseline, current pulses)
          final nodeSize = isCurrent ? 100.0 + pulseVal * 4 : 92.0;
          final glowAlpha = isCurrent ? (140 + (100 * pulseVal)).toInt() : 0;

          return SizedBox(
            width: 110,
            height: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── The jewel-like node ──
                // Outer container = thick gold metallic frame (5-stop gradient)
                // Inner container = colored gem center with top highlight
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        GameColors.goldFrameBright,
                        GameColors.goldHighlight,
                        GameColors.goldFrameMid,
                        GameColors.goldFrameDeep,
                        GameColors.goldFrameMid,
                        GameColors.goldFrameBright,
                      ],
                      stops: [0.0, 0.18, 0.4, 0.55, 0.8, 1.0],
                    ),
                    boxShadow: [
                      // Drop shadow under jewel for depth
                      BoxShadow(
                        color: Colors.black.withAlpha(180),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                      // Outer glow when current
                      if (isCurrent) ...[
                        BoxShadow(
                          color: GameColors.goldFrameBright.withAlpha(glowAlpha),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: GameColors.goldFrameMid
                              .withAlpha((glowAlpha * 0.6).toInt()),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                      // Subtle gold ambient glow always
                      BoxShadow(
                        color: GameColors.goldFrameMid.withAlpha(70),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  // Frame thickness — bigger for current
                  padding: EdgeInsets.all(isCurrent ? 5 : 4.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _nodeGradient(state),
                      // Thin dark inner ring for separation
                      border: Border.all(
                        color: Colors.black.withAlpha(140),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glassy top highlight (light reflection)
                        Positioned(
                          top: nodeSize * 0.08,
                          left: nodeSize * 0.18,
                          right: nodeSize * 0.18,
                          child: Container(
                            height: nodeSize * 0.32,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(nodeSize * 0.4),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withAlpha(isLocked ? 18 : 80),
                                  Colors.white.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Level number / lock icon
                        if (isLocked)
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white.withAlpha(180),
                            size: nodeSize * 0.36,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(220),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        else
                          Text(
                            '$level',
                            style: TextStyle(
                              fontSize: isCurrent ? 34 : 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(220),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                Shadow(
                                  color: isCurrent
                                      ? GameColors.goldFrameDeep
                                      : Colors.black.withAlpha(160),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Stars below the node ──
                // Always reserve the row height so node stays vertically aligned;
                // show 3 outline stars by default and gold stars when completed.
                SizedBox(
                  height: 20,
                  child: (state == _LevelState.completed ||
                          state == _LevelState.current)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final filled = i < stars;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 18,
                                color: filled
                                    ? GameColors.starGoldFilled
                                    : Colors.white.withAlpha(120),
                                shadows: filled
                                    ? [
                                        Shadow(
                                          color: GameColors.goldFrameDeep
                                              .withAlpha(200),
                                          blurRadius: 6,
                                        ),
                                        const Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [
                                        Shadow(
                                          color:
                                              Colors.black.withAlpha(180),
                                          blurRadius: 3,
                                        ),
                                      ],
                              ),
                            );
                          }),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _nodeGradient(_LevelState state) {
    switch (state) {
      case _LevelState.locked:
        // Mockup M1: dark circle with brown-purple wash, gold ring outside
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A2A1F),
            Color(0xFF1F1410),
          ],
        );
      case _LevelState.current:
        // Mockup M1 current: deep purple with gold ring
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameColors.panelPurpleLight,
            GameColors.panelPurple,
            GameColors.panelPurpleDark,
          ],
        );
      case _LevelState.unlocked:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.buttonBlue,
            GameColors.buttonBlueDark,
          ],
        );
      case _LevelState.completed:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameColors.buttonGreen,
            GameColors.buttonGreenDark,
          ],
        );
    }
  }

}

// ---------------------------------------------------------------------------
// DailyChallengeButton — vertical red ribbon on left edge (mockup M1)
// ---------------------------------------------------------------------------
class _DailyChallengeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyChallengeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 100),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Outer gold frame wrapper (5-stop gradient)
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.goldFrameBright,
                GameColors.goldHighlight,
                GameColors.goldFrameMid,
                GameColors.goldFrameDeep,
                GameColors.goldFrameMid,
                GameColors.goldFrameBright,
              ],
              stops: [0.0, 0.2, 0.4, 0.55, 0.8, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.cherryRed.withAlpha(160),
                blurRadius: 22,
                offset: const Offset(4, 0),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(180),
                blurRadius: 14,
                offset: const Offset(3, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(0, 3, 3, 3),
          child: Container(
            // Cherry red interior
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.cherryRed,
                  GameColors.cherryRedDark,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: GameColors.goldFrameBright,
                  size: 30,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(220),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    const Shadow(
                      color: GameColors.cherryRedDark,
                      blurRadius: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'Günlük',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 5,
                          offset: Offset(0, 2),
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
  }
}

// ---------------------------------------------------------------------------
// StarMilestoneBar — bottom region progress bar (mockup M1)
// "Yıldız Ödülleri 15/60" + "Seviye 1-20" pill, gold-bordered purple panel
// ---------------------------------------------------------------------------
class _StarMilestoneBar extends StatelessWidget {
  final int totalStars;
  final GameRegion region;

  const _StarMilestoneBar({
    required this.totalStars,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    // Stars within this region only (for the milestone bar)
    final regionLevelCount = region.endLevel - region.startLevel + 1;
    final milestoneMax = regionLevelCount * 3;
    final regionStars = totalStars.clamp(0, milestoneMax);
    final progress = milestoneMax > 0 ? regionStars / milestoneMax : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Container(
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
              color: Colors.black.withAlpha(140),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: GameColors.starGoldFilled,
                size: 22,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Yıldız Ödülleri $regionStars/$milestoneMax',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Container(
                                color: GameColors.panelPurpleDark
                                    .withAlpha(220)),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      GameColors.goldFrameBright,
                                      GameColors.goldFrameMid,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameColors.goldFrameMid,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                      color: GameColors.cherryRed.withAlpha(120),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'Seviye ${region.startLevel}-${region.endLevel}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(color: Colors.black.withAlpha(180), blurRadius: 3),
                    ],
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
