import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
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
// MapScreen — main entry widget
// ---------------------------------------------------------------------------
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late GameRegion _selectedRegion;
  bool _showNoLivesPopup = false;
  int? _showLevelStartPopupFor;

  @override
  void initState() {
    super.initState();
    final currentLevel = ref.read(playerProgressProvider).currentLevel;
    _selectedRegion = GameRegion.forLevel(currentLevel);

    // Auto-show daily reward popup if not claimed today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(playerProgressProvider.notifier);
      if (notifier.isDailyRewardAvailable) {
        showDailyRewardPopup(context, ref);
      }
    });
  }

  void _selectRegion(GameRegion region) {
    setState(() => _selectedRegion = region);
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

          // Dark overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.bgDeep.withAlpha(100),
                  GameColors.bgDeep.withAlpha(180),
                  GameColors.bgDeep.withAlpha(230),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _MapHeader(
                  coins: progress.coins,
                  lives: progress.lives,
                  onBack: () => context.go('/menu'),
                ),

                const SizedBox(height: 8),

                // Region selector
                _RegionSelector(
                  selectedRegion: _selectedRegion,
                  totalStars: progress.totalStars,
                  onRegionSelected: _selectRegion,
                ),

                const SizedBox(height: 8),

                // Level grid
                Expanded(
                  child: _LevelGrid(
                    region: _selectedRegion,
                    progress: progress,
                    onLevelTap: (level) {
                      // Show level start popup instead of navigating directly
                      setState(() => _showLevelStartPopupFor = level);
                    },
                  ),
                ),

                // Bottom nav bar
                const _BottomNavBar(),
              ],
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
                // Regenerate lives before checking
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
                // Grant 1 life from rewarded ad
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
    // Pick a unique gradient per region index
    final index = GameRegion.values.indexOf(region);
    final hue = (index * 30.0) % 360;
    final topColor =
        HSLColor.fromAHSL(1, hue, 0.6, 0.25).toColor();
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
// MapHeader — back button, title, coins, lives
// ---------------------------------------------------------------------------
class _MapHeader extends StatelessWidget {
  final int coins;
  final int lives;
  final VoidCallback onBack;

  const _MapHeader({
    required this.coins,
    required this.lives,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.purpleLight.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(140),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                onBack();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Title
            Expanded(
              child: Text(
                'PatPat Harita',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GameColors.goldLight,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: GameColors.goldDark.withAlpha(160),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Spin wheel button
            GestureDetector(
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/spin');
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE44D), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.goldFrame.withAlpha(80),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('\uD83C\uDFA1', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Coins capsule
            _HeaderCapsule(
              emoji: '\uD83E\uDE99', // coin
              value: '$coins',
              bgColor: GameColors.goldDark.withAlpha(100),
              textColor: GameColors.goldLight,
            ),

            const SizedBox(width: 8),

            // Lives capsule
            _HeaderCapsule(
              emoji: '\u2764\uFE0F', // heart
              value: '$lives',
              bgColor: GameColors.pinkDark.withAlpha(100),
              textColor: GameColors.pinkLight,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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
    // Each chip is ~130 wide + 8 gap
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
      height: 48,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: GameRegion.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.lock, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
            ],
            Text(
              region.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(width: 4),
              Text(
                '\u2B50${region.starsRequired}',
                style: TextStyle(
                  fontSize: 11,
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
// LevelGrid — 3-column grid of level cards
// ---------------------------------------------------------------------------
class _LevelGrid extends StatelessWidget {
  final GameRegion region;
  final PlayerProgress progress;
  final ValueChanged<int> onLevelTap;

  const _LevelGrid({
    required this.region,
    required this.progress,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelCount = region.endLevel - region.startLevel + 1;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: levelCount,
      itemBuilder: (context, index) {
        final level = region.startLevel + index;
        return _LevelCard(
          level: level,
          progress: progress,
          onLevelTap: onLevelTap,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// LevelCard — individual level cell
// ---------------------------------------------------------------------------
enum _LevelState { locked, current, unlocked, completed }

class _LevelCard extends StatefulWidget {
  final int level;
  final PlayerProgress progress;
  final ValueChanged<int> onLevelTap;

  const _LevelCard({
    required this.level,
    required this.progress,
    required this.onLevelTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  _LevelState get _state {
    if (!widget.progress.isLevelUnlocked(widget.level)) {
      return _LevelState.locked;
    }
    final stars = widget.progress.starsForLevel(widget.level);
    if (stars > 0) return _LevelState.completed;
    if (widget.level == widget.progress.currentLevel) {
      return _LevelState.current;
    }
    return _LevelState.unlocked;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_state == _LevelState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LevelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_state == _LevelState.current && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (_state != _LevelState.current && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_state == _LevelState.locked) return;
    SoundManager.instance.play(SoundType.buttonClick);
    HapticManager.instance.tapLight();
    widget.onLevelTap(widget.level);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final stars = widget.progress.starsForLevel(widget.level);
    final highScore = widget.progress.highScores[widget.level] ?? 0;

    return GestureDetector(
      onTap: state != _LevelState.locked ? _onTap : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseVal = _pulseAnimation.value;
          final isCurrent = state == _LevelState.current;

          // Gold glow intensity for current level
          final glowAlpha = isCurrent ? (80 + (80 * pulseVal)).toInt() : 0;
          final borderWidth = isCurrent ? 2.0 + pulseVal * 1.5 : 1.5;
          final scale = isCurrent ? 1.0 + pulseVal * 0.03 : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _cardGradient(state),
                border: Border.all(
                  color: _borderColor(state),
                  width: borderWidth,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: GameColors.goldFrame.withAlpha(glowAlpha),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Top highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 24,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white
                                  .withAlpha(state == _LevelState.locked ? 10 : 30),
                              Colors.white.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Level number or lock icon
                        if (state == _LevelState.locked)
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white.withAlpha(60),
                            size: 28,
                          )
                        else
                          Text(
                            '${widget.level}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: state == _LevelState.current
                                  ? GameColors.goldLight
                                  : Colors.white,
                              shadows: [
                                if (state == _LevelState.current)
                                  Shadow(
                                    color: GameColors.goldDark.withAlpha(180),
                                    blurRadius: 10,
                                  )
                                else
                                  Shadow(
                                    color: Colors.black.withAlpha(80),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                              ],
                            ),
                          ),

                        const Spacer(),

                        // High score for completed levels
                        if (state == _LevelState.completed && highScore > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '$highScore',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(140),
                              ),
                            ),
                          ),

                        // Stars row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StarsRow(
                            earnedStars: stars,
                            isLocked: state == _LevelState.locked,
                          ),
                        ),
                      ],
                    ),

                    // Locked overlay dim
                    if (state == _LevelState.locked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withAlpha(80),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _cardGradient(_LevelState state) {
    switch (state) {
      case _LevelState.locked:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade800.withAlpha(180),
            Colors.grey.shade900.withAlpha(200),
          ],
        );
      case _LevelState.current:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D1A70),
            Color(0xFF1A0A40),
          ],
        );
      case _LevelState.unlocked:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A0E60),
            Color(0xFF150840),
          ],
        );
      case _LevelState.completed:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1050),
            Color(0xFF120838),
          ],
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
        return GameColors.neonCyan.withAlpha(120);
      case _LevelState.completed:
        return GameColors.purpleLight.withAlpha(80);
    }
  }
}

// ---------------------------------------------------------------------------
// StarsRow — 3 small star icons
// ---------------------------------------------------------------------------
class _StarsRow extends StatelessWidget {
  final int earnedStars;
  final bool isLocked;

  const _StarsRow({required this.earnedStars, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < earnedStars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: isLocked
                ? Colors.white.withAlpha(30)
                : filled
                    ? GameColors.goldFrame
                    : Colors.white.withAlpha(50),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// BottomNavBar — 4 placeholder icons
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameColors.purpleLight.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(160),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavButton(
              icon: Icons.home_rounded,
              label: 'Ana Sayfa',
              isActive: false,
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/menu');
              },
            ),
            _NavButton(
              icon: Icons.shopping_cart_rounded,
              label: 'Market',
              isActive: false,
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/shop');
              },
            ),
            _NavButton(
              icon: Icons.emoji_events_rounded,
              label: 'Basarimlar',
              isActive: false,
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/achievements');
              },
            ),
            _NavButton(
              icon: Icons.celebration_rounded,
              label: 'Etkinlik',
              isActive: false,
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/events');
              },
            ),
            _NavButton(
              icon: Icons.person_rounded,
              label: 'Profil',
              isActive: false,
              onTap: () {
                SoundManager.instance.play(SoundType.buttonClick);
                HapticManager.instance.tapLight();
                context.go('/profile');
              },
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: GameColors.neonCyan.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? GameColors.neonCyan : Colors.white60,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
