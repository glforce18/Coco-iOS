import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/screens/daily_reward_screen.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/notifications/notification_manager.dart';
import 'package:patpat_game/widgets/level_start_popup.dart';
import 'package:patpat_game/widgets/no_lives_popup.dart';
import 'package:patpat_game/widgets/notif_optin_popup.dart';
import 'package:patpat_game/widgets/premium_promo_modal.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';

/// Tropical Treasure Trail — winding sine-wave path through region scenery,
/// mascot Coco accompanying the player at the current level, scattered decor
/// (palms, shells, crabs), and a treasure chest at the region's end.
class MapScreen extends ConsumerStatefulWidget {
  /// Optional region to start on — set when user picked an island from /adalar.
  /// When null, falls back to the region matching the player's current level.
  final GameRegion? initialRegion;
  const MapScreen({super.key, this.initialRegion});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late GameRegion _selectedRegion;
  bool _showNoLivesPopup = false;
  int? _showLevelStartPopupFor;
  bool _showNotifOptIn = false;
  bool _premiumPromoQueued = false;
  late final ScrollController _scrollCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _sparkleCtrl;
  late final AnimationController _waveCtrl;

  // Path layout constants
  static const double _topPad = 200; // space at top for treasure chest
  static const double _bottomPad = 80;
  static const double _levelSpacing = 130; // vertical px between levels
  static const double _amplitude = 110; // path sway amplitude
  static const double _frequency = 0.62; // sine frequency

  @override
  void initState() {
    super.initState();
    final cur = ref.read(playerProgressProvider).currentLevel;
    _selectedRegion = widget.initialRegion ?? GameRegion.forLevel(cur);
    _scrollCtrl = ScrollController();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(playerProgressProvider.notifier);
      if (notifier.isDailyRewardAvailable) {
        showDailyRewardPopup(context, ref);
      }
      _scrollToCurrentLevel();
      // Tropical beach ambience loop while on map.
      SoundManager.instance.playLoop(SoundManager.ambienceBeach, volume: 0.28);
    });
  }

  void _scrollToCurrentLevel() {
    final progress = ref.read(playerProgressProvider);
    final cur = progress.currentLevel.clamp(_selectedRegion.startLevel, _selectedRegion.endLevel);
    final lvlInRegion = cur - _selectedRegion.startLevel;
    // Path is reversed (level 1 at bottom). Scroll from bottom to current.
    final levelCount = _selectedRegion.endLevel - _selectedRegion.startLevel + 1;
    final totalHeight = _topPad + levelCount * _levelSpacing + _bottomPad;
    final yOfLevel = totalHeight - _bottomPad - (lvlInRegion + 1) * _levelSpacing;
    final viewportHeight = MediaQuery.of(context).size.height;
    final target = (yOfLevel - viewportHeight / 2 + 80).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectRegion(GameRegion r) {
    setState(() => _selectedRegion = r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    _sparkleCtrl.dispose();
    _waveCtrl.dispose();
    SoundManager.instance.stopLoop();
    super.dispose();
  }

  // Sine-wave path: returns center-x of level [i] (0-indexed inside region).
  double _xForLevel(int levelInRegion, double width) {
    final cx = width / 2;
    return cx + _amplitude * math.sin(levelInRegion * _frequency);
  }

  // Path y-coord (top-down). totalHeight - bottomPad - (level+1)*spacing.
  double _yForLevel(int levelInRegion, double totalHeight) {
    return totalHeight - _bottomPad - (levelInRegion + 1) * _levelSpacing;
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final size = MediaQuery.of(context).size;
    final levelCount = _selectedRegion.endLevel - _selectedRegion.startLevel + 1;
    final totalHeight = _topPad + levelCount * _levelSpacing + _bottomPad;

    // Premium upsell — once per ~10 levels, 24h cooldown. Schedule
    // post-frame so we don't fight any other modal racing to mount.
    final notifier = ref.read(playerProgressProvider.notifier);
    final completedLevel = progress.currentLevel - 1;
    if (!_premiumPromoQueued &&
        notifier.shouldShowPremiumPromo(completedLevel)) {
      _premiumPromoQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await notifier.markPremiumPromoShown();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        await showPremiumPromoModal(context, ref);
      });
    }

    return Scaffold(
      backgroundColor: TT.oceanDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Region wallpaper — tiles vertically as user scrolls
          _RegionBackground(region: _selectedRegion, scroll: _scrollCtrl),

          // Subtle vignette top + bottom
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(140),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(170),
                  ],
                  stops: const [0.0, 0.16, 0.78, 1.0],
                ),
              ),
            ),
          ),

          // Sparkle particles
          IgnorePointer(child: _SparkleLayer(animation: _sparkleCtrl)),

          // Scrollable trail
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 142, // below top bar + region pill
            bottom: 156, // above milestone + nav
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: size.width,
                height: totalHeight,
                child: Stack(
                  children: [
                    // 1) Decoration sprites (palms, shells, crabs)
                    ..._buildDecorations(size, totalHeight, levelCount),

                    // 2) Curving golden path
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _TrailPainter(
                            count: levelCount,
                            xFor: (i) => _xForLevel(i, size.width),
                            yFor: (i) => _yForLevel(i, totalHeight),
                            shimmer: _waveCtrl.value,
                          ),
                        ),
                      ),
                    ),

                    // 3) Next region preview (above the chest, "what comes next")
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(child: _NextRegionPreview(current: _selectedRegion)),
                    ),
                    // 3b) Treasure chest at top of region
                    Positioned(
                      top: _topPad - 180,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _TreasureChestHeader(
                          sparkleAnimation: _sparkleCtrl,
                          unlocked: progress.starsForLevel(_selectedRegion.endLevel) > 0,
                        ),
                      ),
                    ),

                    // 4) Level nodes
                    for (int i = 0; i < levelCount; i++)
                      Positioned(
                        left: _xForLevel(i, size.width) - 44,
                        top: _yForLevel(i, totalHeight) - 44,
                        child: _LevelNode(
                          level: _selectedRegion.startLevel + i,
                          progress: progress,
                          pulseAnimation: _pulseCtrl,
                          onTap: () {
                            final lvl = _selectedRegion.startLevel + i;
                            if (progress.isLevelUnlocked(lvl)) {
                              setState(() => _showLevelStartPopupFor = lvl);
                            }
                          },
                        ),
                      ),

                    // 5) Mascot Coco at current level
                    if (progress.currentLevel >= _selectedRegion.startLevel &&
                        progress.currentLevel <= _selectedRegion.endLevel)
                      _MascotMarker(
                        x: _xForLevel(progress.currentLevel - _selectedRegion.startLevel, size.width),
                        y: _yForLevel(progress.currentLevel - _selectedRegion.startLevel, totalHeight),
                        pulse: _pulseCtrl,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Top: stats bar + region pill ───
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  IslandTopBar(
                    stars: progress.totalStars,
                    coins: progress.coins,
                    hearts: progress.lives,
                    leading: IslandCircleButton(
                      icon: Icons.home_rounded,
                      onTap: () => context.go('/menu'),
                    ),
                    trailing: [
                      IslandCircleButton(
                        icon: Icons.casino_rounded,
                        onTap: () => context.push('/spin'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _RegionBanner(
                    region: _selectedRegion,
                    totalStars: progress.totalStars,
                    onSelect: _selectRegion,
                  ),
                ],
              ),
            ),
          ),

          // ─── Bottom: milestone bar + nav ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AdalarBar(
                  current: _selectedRegion,
                  onTapAll: () => context.push('/adalar'),
                  onSelect: _selectRegion,
                ),
                _StarMilestone(totalStars: progress.totalStars, region: _selectedRegion),
                IslandBottomNav(
                  activeIndex: -1,
                  tabs: [
                    IslandNavTab(icon: Icons.home_rounded, label: 'Ana Sayfa', onTap: () => context.go('/menu')),
                    IslandNavTab(icon: Icons.shopping_bag_rounded, label: 'Mağaza', onTap: () => context.push('/shop')),
                    IslandNavTab(
                      icon: Icons.casino_rounded,
                      label: 'Çark',
                      onTap: () => context.push('/spin'),
                      isCenter: true,
                    ),
                    IslandNavTab(icon: Icons.egg_rounded, label: 'Yuva', onTap: () => context.push('/nest')),
                    IslandNavTab(icon: Icons.person_rounded, label: 'Profil', onTap: () => context.push('/profile')),
                  ],
                ),
              ],
            ),
          ),

          // ─── Daily ribbon (left) ───
          SafeArea(
            child: Align(
              alignment: Alignment(-1.0, -0.05),
              child: _DailyRibbon(
                onTap: () {
                  final n = ref.read(playerProgressProvider.notifier);
                  if (n.isDailyRewardAvailable) {
                    showDailyRewardPopup(context, ref);
                  } else {
                    context.push('/spin');
                  }
                },
              ),
            ),
          ),

          if (_showLevelStartPopupFor != null)
            LevelStartPopup(
              level: _showLevelStartPopupFor!,
              earnedStars: progress.starsForLevel(_showLevelStartPopupFor!),
              highScore: progress.highScores[_showLevelStartPopupFor!] ?? 0,
              onPlay: () {
                final lvl = _showLevelStartPopupFor!;
                setState(() => _showLevelStartPopupFor = null);
                progress.regenerateLives();
                if (progress.lives <= 0) {
                  setState(() => _showNoLivesPopup = true);
                } else {
                  ref.read(playerProgressProvider.notifier).useLife();
                  context.go('/game/$lvl');
                }
              },
              onClose: () => setState(() => _showLevelStartPopupFor = null),
            ),
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
              onClose: () => setState(() => _showNoLivesPopup = false),
            ),
          if (_shouldShowOptIn(progress) || _showNotifOptIn)
            NotifOptInPopup(
              onAccept: () async {
                await ref.read(playerProgressProvider.notifier).markNotifsAsked();
                final granted = await NotificationManager.instance.requestPermission();
                if (!granted) {
                  await ref.read(playerProgressProvider.notifier)
                      .updateNotifPrefs(master: false);
                }
                if (mounted) setState(() => _showNotifOptIn = false);
              },
              onDecline: () async {
                await ref.read(playerProgressProvider.notifier).markNotifsAsked();
                await ref.read(playerProgressProvider.notifier)
                    .updateNotifPrefs(master: false);
                if (mounted) setState(() => _showNotifOptIn = false);
              },
            ),
        ],
      ),
    );
  }

  /// Show opt-in popup once: never asked, user lost ≥1 life, no other
  /// popup is currently visible (avoid stacking modals).
  bool _shouldShowOptIn(dynamic progress) {
    if (progress.notifsAskedAt != 0) return false;
    final hasLostLife = progress.lives < 5 || progress.lastLifeLostTime > 0;
    if (!hasLostLife) return false;
    if (_showLevelStartPopupFor != null) return false;
    if (_showNoLivesPopup) return false;
    return true;
  }

  /// Build decorative scenery sprites alongside the path.
  /// Each level row gets ~1 decoration on the opposite side from the level.
  List<Widget> _buildDecorations(Size size, double totalHeight, int levelCount) {
    final widgets = <Widget>[];
    final rng = math.Random(_selectedRegion.index * 41);
    const decorAssets = <String>[
      'assets/tropical/decor/decor_palm_leaves.png',
      'assets/tropical/decor/decor_coconut.png',
      'assets/tropical/decor/decor_starfish.png',
      'assets/tropical/decor/decor_seashell.png',
      'assets/tropical/decor/decor_crab.png',
      'assets/tropical/decor/decor_pearl.png',
      'assets/tropical/decor/decor_compass.png',
      'assets/tropical/decor/decor_gold_coin.png',
      'assets/tropical/decor/decor_pirate_flag.png',
      'assets/tropical/decor/decor_map_scroll.png',
    ];

    for (int i = 0; i < levelCount; i++) {
      // 1 large decoration every 2 levels
      if (i % 2 != 0) continue;
      final asset = decorAssets[rng.nextInt(decorAssets.length)];
      final levelX = _xForLevel(i, size.width);
      final y = _yForLevel(i, totalHeight) + rng.nextDouble() * 40 - 20;
      // place opposite side of level
      final cx = size.width / 2;
      final onLeft = levelX > cx;
      final offsetX = onLeft
          ? rng.nextDouble() * 60 + 20
          : size.width - rng.nextDouble() * 80 - 80;
      final s = 60.0 + rng.nextDouble() * 26;
      widgets.add(Positioned(
        left: offsetX,
        top: y,
        child: Opacity(
          opacity: 0.85,
          child: Image.asset(asset, width: s, height: s, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        ),
      ));
    }
    return widgets;
  }
}

// ─── Region Background (fixed viewport) ───────────────────────────────────
// No parallax — simply fills the entire screen with BoxFit.cover. Path
// scrolls over a static BG so there's never an empty band at the bottom.
class _RegionBackground extends StatelessWidget {
  final GameRegion region;
  final ScrollController scroll; // unused but kept for API compatibility
  const _RegionBackground({required this.region, required this.scroll});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: TT.oceanDepthGradient),
      child: Image.asset(
        region.backgroundAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(gradient: TT.oceanDepthGradient),
        ),
      ),
    );
  }
}

// ─── Sparkle layer ────────────────────────────────────────────────────────
class _SparkleLayer extends StatelessWidget {
  final AnimationController animation;
  const _SparkleLayer({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _SparklePainter(animation.value),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(13);
    for (int i = 0; i < 18; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * 2 * math.pi;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final r = 1.4 + rng.nextDouble() * 2.0;
      final x = bx + math.sin(t * 2 * math.pi * speed + phase) * 8;
      final y = by + math.cos(t * 2 * math.pi * speed + phase * 0.7) * 6;
      final a = (60 + 80 * math.sin(t * 2 * math.pi * speed + phase)).toInt();
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = TT.goldShine.withAlpha(a.clamp(0, 220))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => true;
}

// ─── Curving Trail Painter ────────────────────────────────────────────────
class _TrailPainter extends CustomPainter {
  final int count;
  final double Function(int) xFor;
  final double Function(int) yFor;
  final double shimmer;

  _TrailPainter({
    required this.count,
    required this.xFor,
    required this.yFor,
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final path = Path();
    path.moveTo(xFor(0), yFor(0));
    for (int i = 1; i < count; i++) {
      final prev = Offset(xFor(i - 1), yFor(i - 1));
      final curr = Offset(xFor(i), yFor(i));
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      // Smooth quadratic toward each midpoint, then line — gives organic curve
      path.quadraticBezierTo(prev.dx, mid.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(curr.dx, mid.dy, curr.dx, curr.dy);
    }

    // Layer 1 — outer dark shadow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withAlpha(110)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Layer 2 — wood/sand path body
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [TT.driftWoodDark, TT.driftWood, TT.driftWoodDark],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Layer 3 — gold dotted overlay on top of path
    final dotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = TT.goldShine;
    final dashLen = 8.0;
    final gapLen = 14.0;
    final pm = path.computeMetrics();
    for (final metric in pm) {
      double dist = (shimmer * (dashLen + gapLen));
      while (dist < metric.length) {
        final extract = metric.extractPath(dist, dist + dashLen);
        canvas.drawPath(extract, dotPaint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) => old.shimmer != shimmer || old.count != count;
}

// ─── Next Region Preview — appears ABOVE the treasure chest at top of map.
// Shows the next region the player will unlock after completing this one.
class _NextRegionPreview extends StatelessWidget {
  final GameRegion current;
  const _NextRegionPreview({required this.current});

  @override
  Widget build(BuildContext context) {
    final regions = GameRegion.values;
    final idx = regions.indexOf(current);
    final isLast = idx >= regions.length - 1;
    final next = isLast ? null : regions[idx + 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: TT.gold.withAlpha(120), blurRadius: 14, spreadRadius: -2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: TT.driftPanelGradient,
          border: Border.all(color: Colors.white.withAlpha(60), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, color: TT.goldShine, size: 16),
            const SizedBox(width: 6),
            Text(
              'Sonraki:',
              style: TT.bodySmall.copyWith(
                color: TT.sandLight.withAlpha(220),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            if (next != null) ...[
              ClipOval(
                child: Image.asset(
                  next.pillAsset,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Icon(Icons.terrain, color: TT.goldShine, size: 18),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                next.displayName,
                style: TT.titleSmall.copyWith(
                  color: TT.goldShine,
                  fontSize: 13,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
              ),
            ] else
              Text(
                'Tamamlandı! 🎉',
                style: TT.titleSmall.copyWith(
                  color: TT.goldShine,
                  fontSize: 13,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Treasure Chest Header ────────────────────────────────────────────────
class _TreasureChestHeader extends StatelessWidget {
  final AnimationController sparkleAnimation;
  final bool unlocked;
  const _TreasureChestHeader({required this.sparkleAnimation, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sparkleAnimation,
      builder: (_, __) {
        final t = sparkleAnimation.value;
        final glow = unlocked ? (140 + (60 * math.sin(t * 2 * math.pi)).toInt()) : 60;
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // glow halo
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: unlocked
                      ? [
                          BoxShadow(color: TT.gold.withAlpha(glow), blurRadius: 60, spreadRadius: 14),
                          BoxShadow(color: TT.goldShine.withAlpha(glow ~/ 2), blurRadius: 100, spreadRadius: 30),
                        ]
                      : [
                          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 16),
                        ],
                ),
              ),
              ColorFiltered(
                colorFilter: unlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                child: Image.asset(
                  TA.decorTreasureChest,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.lock_rounded, size: 80, color: TT.gold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Level Node ───────────────────────────────────────────────────────────
enum _LevelState { locked, unlocked, current, completed }

class _LevelNode extends StatelessWidget {
  final int level;
  final PlayerProgress progress;
  final AnimationController pulseAnimation;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.progress,
    required this.pulseAnimation,
    required this.onTap,
  });

  _LevelState get _state {
    if (!progress.isLevelUnlocked(level)) return _LevelState.locked;
    final s = progress.starsForLevel(level);
    if (s > 0) return _LevelState.completed;
    if (level == progress.currentLevel) return _LevelState.current;
    return _LevelState.unlocked;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final stars = progress.starsForLevel(level);
    final isCurrent = state == _LevelState.current;
    final isLocked = state == _LevelState.locked;
    final isBoss = level % 20 == 0;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 88,
        height: 88,
        child: AnimatedBuilder(
          animation: isCurrent ? pulseAnimation : const AlwaysStoppedAnimation(0),
          builder: (_, __) {
            final pv = isCurrent ? pulseAnimation.value : 0.0;
            final size = isCurrent ? 78.0 + pv * 4 : 68.0;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Main gold-bordered jewel
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep, TT.gold, TT.goldShine],
                      stops: [0.0, 0.18, 0.4, 0.55, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 12, offset: const Offset(0, 5)),
                      if (isCurrent) ...[
                        BoxShadow(
                          color: TT.goldShine.withAlpha((140 + 100 * pv).toInt()),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: TT.gold.withAlpha((90 + 60 * pv).toInt()),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                      ],
                      BoxShadow(color: TT.gold.withAlpha(70), blurRadius: 12),
                    ],
                  ),
                  padding: EdgeInsets.all(isCurrent ? 4 : 3.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _stateGradient(state),
                      border: Border.all(color: Colors.black.withAlpha(140), width: 1),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: size * 0.08,
                          left: size * 0.18,
                          right: size * 0.18,
                          child: Container(
                            height: size * 0.32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(size * 0.4),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withAlpha(isLocked ? 18 : 110),
                                  Colors.white.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isLocked)
                          Icon(Icons.lock_rounded,
                              color: Colors.white.withAlpha(180),
                              size: size * 0.34,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                              ])
                        else if (isBoss)
                          Icon(
                            Icons.castle_rounded,
                            color: Colors.white,
                            size: size * 0.5,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          )
                        else
                          Text(
                            '$level',
                            style: TextStyle(
                              fontSize: isCurrent ? 26 : 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                                Shadow(color: isCurrent ? TT.goldDeep : Colors.black.withAlpha(160), blurRadius: 10),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Stars below for completed
                if (state == _LevelState.completed)
                  Positioned(
                    bottom: -10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: i < stars ? TT.starFilled : Colors.white.withAlpha(120),
                          shadows: i < stars
                              ? [
                                  Shadow(color: TT.goldDeep, blurRadius: 4),
                                  const Shadow(color: Colors.black54, blurRadius: 3),
                                ]
                              : [Shadow(color: Colors.black.withAlpha(180), blurRadius: 2)],
                        ),
                      )),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  LinearGradient _stateGradient(_LevelState s) {
    switch (s) {
      case _LevelState.locked:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2A1F), Color(0xFF1F1410)],
        );
      case _LevelState.current:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TT.coralLight, TT.coral, TT.coralDark],
        );
      case _LevelState.unlocked:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.lagoonLight, TT.lagoon, TT.lagoonDark],
        );
      case _LevelState.completed:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TT.palmLight, TT.palm, TT.palmDark],
        );
    }
  }
}

// ─── Mascot marker on path (next to current level) ────────────────────────
class _MascotMarker extends StatelessWidget {
  final double x;
  final double y;
  final AnimationController pulse;
  const _MascotMarker({required this.x, required this.y, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    // Position to opposite side of level to not overlap node
    final isLeft = x > cx;
    final left = isLeft ? x - 110 : x + 60;

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final dy = math.sin(pulse.value * math.pi) * 4;
        return Positioned(
          left: left,
          top: y - 30 + dy,
          child: SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        TT.goldShine.withAlpha(140),
                        TT.gold.withAlpha(40),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Image.asset(
                  TA.mascotHappy,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Region Banner (replaces region selector) ─────────────────────────────
class _RegionBanner extends StatelessWidget {
  final GameRegion region;
  final int totalStars;
  final ValueChanged<GameRegion> onSelect;

  const _RegionBanner({
    required this.region,
    required this.totalStars,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final regions = GameRegion.values;
    final idx = regions.indexOf(region);
    final hasPrev = idx > 0;
    final hasNext = idx < regions.length - 1;
    final next = hasNext ? regions[idx + 1] : null;
    final nextUnlocked = next != null && totalStars >= next.starsRequired;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev,
            onTap: hasPrev ? () => onSelect(regions[idx - 1]) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 12, offset: const Offset(0, 4)),
                  BoxShadow(color: TT.gold.withAlpha(140), blurRadius: 18, spreadRadius: 1),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: TT.driftPanelGradient,
                  border: Border(top: BorderSide(color: Colors.white.withAlpha(80), width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        region.pillAsset,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.terrain, color: TT.goldShine, size: 30),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.displayName,
                            style: TT.titleLarge.copyWith(
                              color: TT.sandLight,
                              fontSize: 17,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Bölüm ${region.startLevel}-${region.endLevel}',
                            style: TT.bodySmall.copyWith(
                              color: TT.sandLight.withAlpha(200),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            enabled: nextUnlocked,
            locked: hasNext && !nextUnlocked,
            starsReq: hasNext && !nextUnlocked ? next!.starsRequired : null,
            onTap: nextUnlocked ? () => onSelect(regions[idx + 1]) : null,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool locked;
  final int? starsReq;
  final VoidCallback? onTap;
  const _NavBtn({
    required this.icon,
    required this.enabled,
    this.locked = false,
    this.starsReq,
    this.onTap,
  });

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
          boxShadow: enabled
              ? [BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: TT.driftPanelGradient,
            border: Border.all(color: Colors.white.withAlpha(60), width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                locked ? Icons.lock_rounded : icon,
                color: enabled ? TT.sandLight : TT.sandLight.withAlpha(120),
                size: 24,
              ),
              if (locked && starsReq != null)
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: TT.coral,
                      border: Border.all(color: TT.goldShine, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 9, color: TT.goldShine),
                        const SizedBox(width: 1),
                        Text('$starsReq',
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
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

// ─── Daily ribbon ─────────────────────────────────────────────────────────
class _DailyRibbon extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyRibbon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ),
          boxShadow: [
            BoxShadow(color: TT.coral.withAlpha(160), blurRadius: 22, offset: const Offset(4, 0)),
            BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 14, offset: const Offset(3, 6)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(0, 3, 3, 3),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.coralLight, TT.coral, TT.coralDark],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_activity_rounded,
                color: TT.goldShine,
                size: 26,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              const SizedBox(height: 6),
              const RotatedBox(
                quarterTurns: 1,
                child: Text(
                  'Günlük',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2))],
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

// ─── Star milestone bar ───────────────────────────────────────────────────
class _StarMilestone extends StatelessWidget {
  final int totalStars;
  final GameRegion region;
  const _StarMilestone({required this.totalStars, required this.region});

  @override
  Widget build(BuildContext context) {
    final required = region.starsRequired;
    final next = _nextRegion(region);
    final nextRequired = next?.starsRequired ?? 999;
    final progress = ((totalStars - required) / (nextRequired - required)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: TT.driftPanelGradient,
            border: Border(top: BorderSide(color: Colors.white.withAlpha(80), width: 1.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: TT.starFilled, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Yıldız Ödülü',
                          style: TT.bodySmall.copyWith(
                            color: TT.sandLight,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalStars / $nextRequired',
                          style: TT.bodySmall.copyWith(
                            color: TT.goldShine,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            Container(color: TT.driftWoodDark.withAlpha(180)),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [TT.goldShine, TT.gold],
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
            ],
          ),
        ),
      ),
    );
  }

  GameRegion? _nextRegion(GameRegion r) {
    final i = GameRegion.values.indexOf(r);
    if (i < GameRegion.values.length - 1) return GameRegion.values[i + 1];
    return null;
  }
}


// ─── "Adalar" full-width button at bottom of map ───────────────────────────
/// Bottom strip with ← prev island button, central "ADALAR" pill, → next.
/// Lets the player jump back/forward without going through the Adalar
/// picker screen.
class _AdalarBar extends StatelessWidget {
  final GameRegion current;
  final VoidCallback onTapAll;
  final ValueChanged<GameRegion> onSelect;
  const _AdalarBar({
    required this.current,
    required this.onTapAll,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final values = GameRegion.values;
    final idx = values.indexOf(current);
    final prev = idx > 0 ? values[idx - 1] : null;
    final next = idx < values.length - 1 ? values[idx + 1] : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          _RegionArrow(
            icon: Icons.chevron_left_rounded,
            enabled: prev != null,
            onTap: prev == null ? null : () => onSelect(prev),
          ),
          const SizedBox(width: 6),
          Expanded(child: _AdalarButton(onTap: onTapAll)),
          const SizedBox(width: 6),
          _RegionArrow(
            icon: Icons.chevron_right_rounded,
            enabled: next != null,
            onTap: next == null ? null : () => onSelect(next),
          ),
        ],
      ),
    );
  }
}

class _RegionArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _RegionArrow({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.goldShine, TT.gold, TT.goldDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: TT.driftPanelGradient,
            ),
            child: Icon(
              icon,
              color: TT.goldShine,
              size: 24,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdalarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AdalarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.goldShine, TT.gold, TT.goldDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: TT.gold.withAlpha(120),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: TT.driftPanelGradient,
              border: Border.all(color: Colors.white.withAlpha(50), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.terrain_rounded,
                  color: TT.goldShine,
                  size: 22,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  'ADALAR',
                  style: TextStyle(
                    color: TT.goldShine,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(220),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: TT.goldShine.withAlpha(220),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
    );
  }
}
