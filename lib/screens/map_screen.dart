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
          // Background image or gradient fallback
          _RegionBackground(region: _selectedRegion),

          // Soft overlay for depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(50),
                  Colors.black.withAlpha(10),
                  Colors.black.withAlpha(70),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Decorative sparkle particles
          _SparkleParticles(animation: _sparkleController),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Fixed top header
                _MapHeader(
                  coins: progress.coins,
                  lives: progress.lives,
                  totalStars: progress.totalStars,
                  currentLevel: progress.currentLevel,
                  onBack: () => context.go('/menu'),
                  onSpin: () => context.go('/spin'),
                  onProfile: () => context.go('/profile'),
                ),

                const SizedBox(height: 4),

                // Region selector tabs
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

                // Bottom milestone + nav bar
                _BottomBar(
                  totalStars: progress.totalStars,
                  region: _selectedRegion,
                ),
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
// MapHeader — mascot, stars, coins, lives, settings
// ---------------------------------------------------------------------------
class _MapHeader extends StatelessWidget {
  final int coins;
  final int lives;
  final int totalStars;
  final int currentLevel;
  final VoidCallback onBack;
  final VoidCallback onSpin;
  final VoidCallback onProfile;

  const _MapHeader({
    required this.coins,
    required this.lives,
    required this.totalStars,
    required this.currentLevel,
    required this.onBack,
    required this.onSpin,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.goldFrame.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(160),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Mascot icon / back button
            GestureDetector(
              onTap: () {
                onBack();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCC80FF), Color(0xFF8B24DB)],
                  ),
                  border: Border.all(
                    color: GameColors.goldFrame.withAlpha(120),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.neonPurple.withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/sprites/jelly_purple.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Stars
            _HeaderCapsule(
              emoji: '\u2B50',
              value: '$totalStars',
              bgColor: GameColors.goldDark.withAlpha(80),
              textColor: GameColors.goldLight,
            ),

            const SizedBox(width: 5),

            // Coins
            _HeaderCapsule(
              emoji: '\uD83E\uDE99',
              value: '$coins',
              bgColor: GameColors.goldDark.withAlpha(80),
              textColor: GameColors.goldLight,
            ),

            const SizedBox(width: 5),

            // Lives
            _HeaderCapsule(
              emoji: '\u2764\uFE0F',
              value: '$lives',
              bgColor: GameColors.pinkDark.withAlpha(80),
              textColor: GameColors.pinkLight,
            ),

            const Spacer(),

            // Spin wheel
            GestureDetector(
              onTap: () {
                onSpin();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE44D), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.goldFrame.withAlpha(60),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('\uD83C\uDFA1', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Settings gear
            GestureDetector(
              onTap: () {
                onProfile();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCapsule extends StatelessWidget {
  final String emoji;
  final String value;
  final Color bgColor;
  final Color textColor;

  const _HeaderCapsule({
    required this.emoji,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _RegionSelector old) {
    super.didUpdateWidget(old);
    if (old.selectedRegion != widget.selectedRegion) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = GameRegion.values.indexOf(widget.selectedRegion);
    final target = (index * 138.0) - 60;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: GameRegion.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final region = GameRegion.values[index];
          final isSelected = region == widget.selectedRegion;
          final isUnlocked = widget.totalStars >= region.starsRequired;

          return _RegionChip(
            region: region,
            isSelected: isSelected,
            isUnlocked: isUnlocked,
            onTap: isUnlocked
                ? () => widget.onRegionSelected(region)
                : null,
          );
        },
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final GameRegion region;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _RegionChip({
    required this.region,
    required this.isSelected,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? GameColors.goldDark.withAlpha(120)
        : isUnlocked
            ? GameColors.bgLight.withAlpha(160)
            : GameColors.bgDeep.withAlpha(180);

    final borderColor = isSelected
        ? GameColors.goldFrame
        : isUnlocked
            ? GameColors.purpleLight.withAlpha(60)
            : Colors.grey.withAlpha(40);

    final textColor = isSelected
        ? GameColors.goldLight
        : isUnlocked
            ? Colors.white
            : Colors.white38;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GameColors.goldDark.withAlpha(60),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUnlocked) ...[
              const Icon(Icons.lock, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
            ],
            Text(
              region.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(width: 4),
              Text(
                '\u2B50${region.starsRequired}',
                style: TextStyle(
                  fontSize: 10,
                  color: GameColors.yellowDark.withAlpha(160),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: reversedRows.length,
      itemBuilder: (context, index) {
        final row = reversedRows[index];
        // Determine if this row connects downward (toward higher levels)
        final isLastRow = index == reversedRows.length - 1;
        // Connection direction: the reversed row above connects to the row below
        final hasConnectionBelow = index < reversedRows.length - 1;
        // The connecting edge is at the side where the last element of the
        // upper reversed row meets the first element of the lower reversed row.
        return _PathRowWidget(
          row: row,
          progress: progress,
          pulseAnimation: pulseAnimation,
          sparkleAnimation: sparkleAnimation,
          onLevelTap: onLevelTap,
          isLastRow: isLastRow,
          hasConnectionBelow: hasConnectionBelow,
          nextRowIndex:
              isLastRow ? null : reversedRows[index + 1].rowIndex,
        );
      },
    );
  }
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
      height: 110,
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
            mainAxisAlignment: row.levels.length == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceEvenly,
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
    final pathPaint = Paint()
      ..color = const Color(0xFFB8860B).withAlpha(150)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(40)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final midY = size.height / 2;
    final padding = 16.0;
    final usableWidth = size.width - padding * 2;

    if (levelCount >= 2) {
      // Horizontal curved line connecting nodes
      final spacing = usableWidth / (levelCount + 1);
      for (int i = 0; i < levelCount - 1; i++) {
        final x1 = padding + spacing * (i + 1) + 32;
        final x2 = padding + spacing * (i + 2) - 32;
        final midX = (x1 + x2) / 2;

        // Slight curve for natural path feel
        final path = Path()
          ..moveTo(x1, midY)
          ..quadraticBezierTo(midX, midY - 8, x2, midY);

        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, pathPaint);
      }
    }

    // Vertical connecting line to next row (below in scroll)
    if (hasConnectionBelow) {
      // The connection comes from the end of this row direction
      final isReversed = rowIndex.isOdd;
      final spacing = usableWidth / (levelCount + 1);
      final connectX = isReversed
          ? padding + spacing * 1 // left side (first drawn element of reversed)
          : padding + spacing * levelCount; // right side

      // Curved vertical path going down
      final path = Path()
        ..moveTo(connectX, midY + 34)
        ..quadraticBezierTo(
          connectX + (isReversed ? -12 : 12),
          size.height - 8,
          connectX,
          size.height + 16,
        );

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, pathPaint);

      // Small decorative dot at connection point
      final dotPaint = Paint()
        ..color = const Color(0xFFFFD700).withAlpha(100);
      canvas.drawCircle(Offset(connectX, size.height + 8), 3.5, dotPaint);
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
      child: AnimatedBuilder(
        animation: isCurrent ? pulseAnimation : const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          final pulseVal = isCurrent ? pulseAnimation.value : 0.0;
          final nodeSize = isCurrent ? 68.0 + pulseVal * 4 : 60.0;
          final glowAlpha = isCurrent ? (120 + (100 * pulseVal)).toInt() : 0;

          return SizedBox(
            width: 84,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The circular node
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _nodeGradient(state),
                    border: Border.all(
                      color: _borderColor(state),
                      width: isCurrent ? 3.5 : isLocked ? 1.5 : 3,
                    ),
                    boxShadow: [
                      if (isCurrent) ...[
                        BoxShadow(
                          color: GameColors.goldFrame.withAlpha(glowAlpha),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: GameColors.goldLight.withAlpha(
                              (glowAlpha * 0.4).toInt()),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                      if (!isLocked)
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Top highlight (glass reflection)
                      Positioned(
                        top: 3,
                        left: nodeSize * 0.18,
                        right: nodeSize * 0.18,
                        child: Container(
                          height: nodeSize * 0.28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withAlpha(isLocked ? 8 : 50),
                                Colors.white.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Level number or lock
                      if (isLocked)
                        Container(
                          width: nodeSize,
                          height: nodeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withAlpha(80),
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white.withAlpha(60),
                            size: 20,
                          ),
                        )
                      else
                        Text(
                          '$level',
                          style: TextStyle(
                            fontSize: isCurrent ? 24 : 20,
                            fontWeight: FontWeight.w900,
                            color: isCurrent
                                ? GameColors.goldLight
                                : state == _LevelState.completed
                                    ? Colors.white
                                    : Colors.white.withAlpha(220),
                            shadows: [
                              Shadow(
                                color: isCurrent
                                    ? GameColors.goldDark.withAlpha(200)
                                    : Colors.black.withAlpha(150),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 3),

                // Stars below the node
                SizedBox(
                  height: 16,
                  child: state == _LevelState.completed
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final filled = i < stars;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0.5),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 15,
                                color: filled
                                    ? GameColors.goldFrame
                                    : Colors.white.withAlpha(30),
                                shadows: filled
                                    ? [
                                        BoxShadow(
                                          color:
                                              GameColors.goldFrame.withAlpha(80),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
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
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade700.withAlpha(140),
            Colors.grey.shade900.withAlpha(200),
          ],
        );
      case _LevelState.current:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1A70), Color(0xFF1A0A40)],
        );
      case _LevelState.unlocked:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2060C0), Color(0xFF103880)],
        );
      case _LevelState.completed:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF208040), Color(0xFF105030)],
        );
    }
  }

  Color _borderColor(_LevelState state) {
    switch (state) {
      case _LevelState.locked:
        return Colors.grey.withAlpha(40);
      case _LevelState.current:
        return GameColors.goldFrame;
      case _LevelState.unlocked:
        return GameColors.blueLight.withAlpha(180);
      case _LevelState.completed:
        return GameColors.goldFrame.withAlpha(200);
    }
  }
}

// ---------------------------------------------------------------------------
// DailyChallengeButton — floating on the left side
// ---------------------------------------------------------------------------
class _DailyChallengeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyChallengeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6820), Color(0xFFFF4080)],
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.orange.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\uD83C\uDFC6', style: TextStyle(fontSize: 18)),
              SizedBox(height: 2),
              RotatedBox(
                quarterTurns: 1,
                child: Text(
                  'Gunluk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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

// ---------------------------------------------------------------------------
// BottomBar — Star milestones + nav
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final int totalStars;
  final GameRegion region;

  const _BottomBar({
    required this.totalStars,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    // Star milestones: max stars for this region
    final milestoneMax = ((region.endLevel) * 3);
    final regionStars = totalStars.clamp(0, milestoneMax);
    final progress = milestoneMax > 0 ? regionStars / milestoneMax : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(220),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GameColors.purpleLight.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(160),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star milestone bar
            Row(
              children: [
                const Text('\u2B50', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yildiz Odulleri $totalStars/$milestoneMax',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withAlpha(20)),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        GameColors.goldFrame,
                                        GameColors.goldLight,
                                      ],
                                    ),
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
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GameColors.goldDark.withAlpha(60),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: GameColors.goldFrame.withAlpha(60)),
                  ),
                  child: Text(
                    'Seviye ${region.startLevel}-${region.endLevel}',
                    style: const TextStyle(
                      color: GameColors.goldLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Navigation row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavButton(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  isActive: false,
                  onTap: () {
                    context.go('/menu');
                  },
                ),
                _NavButton(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Market',
                  isActive: false,
                  onTap: () {
                    context.go('/shop');
                  },
                ),
                _NavButton(
                  icon: Icons.map_rounded,
                  label: 'Harita',
                  isActive: true,
                  onTap: () {},
                ),
                _NavButton(
                  icon: Icons.emoji_events_rounded,
                  label: 'Basarimlar',
                  isActive: false,
                  onTap: () {
                    context.go('/achievements');
                  },
                ),
                _NavButton(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: false,
                  onTap: () {
                    context.go('/profile');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: isActive
            ? BoxDecoration(
                color: GameColors.neonCyan.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? GameColors.neonCyan : Colors.white60,
              size: 20,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? GameColors.neonCyan : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
