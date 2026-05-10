import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';
import 'package:patpat_game/widgets/tropical/tropical_frame.dart';

/// Adalar — premium island picker overview. Uses the Leonardo-generated
/// `world_map.png` (ocean + 12 scattered islands + golden path) as the
/// backdrop, and overlays tappable level-range markers at the painted
/// island positions. Locked islands show a padlock; tap-locked → snack
/// "N yıldız daha gerek"; tap-unlocked → `/map` with that region selected.
///
/// Reference SS: /root/foto/yeni/1000129404.png — yapraklar canlı, deniz aksin.
class AdalarScreen extends ConsumerStatefulWidget {
  const AdalarScreen({super.key});

  @override
  ConsumerState<AdalarScreen> createState() => _AdalarScreenState();
}

class _AdalarScreenState extends ConsumerState<AdalarScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _bobCtrl;
  late final AnimationController _pulseCtrl;

  // Tap-zone grid laid out 3 columns × 4 rows across the world_map.png
  // canvas. Coordinates are fractions (0..1) of the rendered map area.
  // Zones are large (110×110) so even if BoxFit.cover crops some painted
  // islands off-screen, the player can still reach every region. Order
  // bottom-left → up, matches the golden path direction in the BG.
  static const List<Offset> _islandPositions = <Offset>[
    Offset(0.18, 0.92), // 1.  Mercan Plajı           (1-20)
    Offset(0.50, 0.88), // 2.  Hindistan Cevizi Adası (21-40)
    Offset(0.82, 0.92), // 3.  Lagün Sarayı           (41-60)
    Offset(0.82, 0.66), // 4.  Palmiye Vadisi         (61-80)
    Offset(0.50, 0.66), // 5.  Yelken Limanı          (81-100)
    Offset(0.18, 0.66), // 6.  Hazine Mağarası        (101-120)
    Offset(0.18, 0.42), // 7.  Volkan Adası           (121-140)
    Offset(0.50, 0.42), // 8.  Buz Adası              (141-160)
    Offset(0.82, 0.42), // 9.  Mercan Resifi          (161-180)
    Offset(0.82, 0.16), // 10. Gizli Tapınak          (181-200)
    Offset(0.50, 0.18), // 11. Çağlayan Cenneti       (201-220)
    Offset(0.18, 0.16), // 12. Kayıp Şehir            (221-240)
  ];

  /// Animated transition state — when user taps an island we play a brief
  /// "fly into island" animation (gold flash + zoom) before navigation.
  GameRegion? _flyingTo;
  late final AnimationController _flyCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _bobCtrl.dispose();
    _pulseCtrl.dispose();
    _flyCtrl.dispose();
    super.dispose();
  }

  Future<void> _onIslandTap(GameRegion region) async {
    // Every island is tappable. Even if the player jumps to a region they
    // haven't unlocked, the underlying levels remain locked by the existing
    // level-gate logic — so they can browse but not play unfinished content.
    if (_flyingTo != null) return; // already navigating
    SoundManager.instance.play(SoundManager.special, volume: 0.65);
    setState(() => _flyingTo = region);
    await _flyCtrl.forward(from: 0);
    if (!mounted) return;
    context.go('/map', extra: region);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    // Reserve space for top stat bar (~64) and bottom nav (~92). Ribbon
    // banner removed by user request — map fills almost the whole screen.
    final topReserve = topInset + 64;
    const bottomReserve = 100.0;
    final mapHeight = size.height - topReserve - bottomReserve;

    return Scaffold(
      extendBody: true,
      backgroundColor: TT.oceanDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // === 1) Deep ocean BG (fills behind world map for letterboxing) ===
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B4D7E), Color(0xFF0E6E8A), Color(0xFF053040)],
              ),
            ),
          ),

          // === 2) World map BG fitted in mid area + 12 island tap markers ===
          Positioned(
            top: topReserve,
            left: 0,
            right: 0,
            height: mapHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Painted world map background
                    Image.asset(
                      'assets/tropical/backgrounds/world_map.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [TT.ocean, TT.oceanDeep],
                          ),
                        ),
                      ),
                    ),
                    // Animated water shimmer overlay
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _OceanShimmerPainter(t: _waveCtrl.value),
                        ),
                      ),
                    ),
                    // 12 tappable island markers
                    for (int i = 0; i < GameRegion.values.length; i++)
                      _markerAt(
                        regions: GameRegion.values,
                        idx: i,
                        progress: progress,
                        w: w,
                        h: h,
                      ),
                  ],
                );
              },
            ),
          ),

          // === 3) Top-edge string lights only — palm leaves removed by
          // user request so the painted islands aren't blocked at L+R edges.
          Positioned.fill(
            child: TropicalFrame(
              topPadding: topInset + 8,
              showLeaves: false,
              showHibiscus: false,
            ),
          ),

          // === 4) Top: stat bar only (ribbon banner removed by user request) ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: IslandTopBar(
                stars: progress.totalStars,
                coins: progress.coins,
                hearts: progress.lives,
                leading: IslandCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go('/map'),
                ),
              ),
            ),
          ),

          // === 5) "YENİ ADA ÖDÜLÜ" floating chip ===
          Positioned(
            top: topInset + 76,
            left: 10,
            child: const _NewIslandRewardChip(),
          ),

          // === 5.5) Fly-to-island transition overlay (above content, below nav) ===
          if (_flyingTo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flyCtrl,
                  builder: (_, __) {
                    final t = _flyCtrl.value;
                    final flashAlpha = (t < 0.4 ? t / 0.4 : 1.0).clamp(0.0, 1.0);
                    final whiteAlpha = (t < 0.4 ? 0.0 : (t - 0.4) / 0.6).clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFFE89C).withValues(alpha: flashAlpha * 0.85),
                                  const Color(0xFFE8A317).withValues(alpha: flashAlpha * 0.55),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                radius: 0.4 + t * 0.8,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(color: Colors.white.withValues(alpha: whiteAlpha)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // === 6) Bottom nav ===
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IslandBottomNav(
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
          ),
        ],
      ),
    );
  }

  Widget _markerAt({
    required List<GameRegion> regions,
    required int idx,
    required dynamic progress,
    required double w,
    required double h,
  }) {
    final region = regions[idx];
    final pos = _islandPositions[idx];
    final cx = pos.dx * w;
    final cy = pos.dy * h;

    final isCurrent = progress.currentLevel >= region.startLevel &&
        progress.currentLevel <= region.endLevel;

    return Positioned(
      left: cx - 55,
      top: cy - 55,
      child: _IslandTapZone(
        isCurrent: isCurrent,
        pulseCtrl: _pulseCtrl,
        onTap: () => _onIslandTap(region),
      ),
    );
  }
}

// ─── Invisible tap zone over a painted island on world_map.png ─────────────
/// Sits on top of an island in the world_map BG. Has no visible disc — the
/// painted island in the BG is the visual. Only the player's CURRENT region
/// gets a soft pulsing gold halo so they know where they are.
class _IslandTapZone extends StatelessWidget {
  final bool isCurrent;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;

  const _IslandTapZone({
    required this.isCurrent,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 110,
        height: 110,
        child: isCurrent
            ? AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) {
                  final pulse = pulseCtrl.value;
                  return Center(
                    child: Transform.scale(
                      scale: 0.85 + pulse * 0.20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TT.goldShine.withValues(alpha: 0.55 + pulse * 0.35),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TT.gold.withValues(alpha: 0.4 + pulse * 0.2),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Outlined yellow subtitle ───────────────────────────────────────────────
class _NewIslandRewardChip extends StatefulWidget {
  const _NewIslandRewardChip();

  @override
  State<_NewIslandRewardChip> createState() => _NewIslandRewardChipState();
}

class _NewIslandRewardChipState extends State<_NewIslandRewardChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobCtrl;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bobCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_bobCtrl.value * math.pi * 2) * 3),
        child: child,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 116),
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6B0), Color(0xFFFFCB3D), Color(0xFFE8A317)],
          ),
          border: Border.all(color: const Color(0xFF6B0B0B), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFE8A317).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YENİ ADA\nÖDÜLÜ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6B0B0B),
                letterSpacing: 0.4,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 3),
            Image.asset(
              TA.decorTreasureChest,
              width: 42,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.card_giftcard_rounded,
                size: 28,
                color: Color(0xFF6B0B0B),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6B0B0B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'HARİKA\nÖDÜLLER!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFF6B0),
                  letterSpacing: 0.2,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated ocean shimmer painter (subtle — BG is rich) ──────────────────
class _OceanShimmerPainter extends CustomPainter {
  final double t;
  _OceanShimmerPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bandPaint = Paint()..blendMode = BlendMode.plus;

    // 6 horizontal shimmer bands drifting across — subtle, BG already rich
    for (int band = 0; band < 6; band++) {
      final bandY = h * (0.18 + band * 0.13);
      final offset = (t + band * 0.16) % 1.0;
      final waveX = w * (offset * 1.5 - 0.25);
      final alpha = 0.08 + 0.04 * math.sin(t * math.pi * 2 + band * 1.5);

      bandPaint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFFB0E8FF).withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha * 1.4),
          const Color(0xFFB0E8FF).withValues(alpha: alpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(waveX - w * 0.4, bandY - 8, w * 0.8, 16));

      final path = Path();
      final yMid = bandY;
      path.moveTo(waveX - w * 0.4, yMid);
      for (double x = -w * 0.4; x <= w * 0.4; x += 12) {
        final y = yMid + math.sin((x / 36) + t * math.pi * 2 + band) * 3.5;
        path.lineTo(waveX + x, y);
      }
      path.lineTo(waveX + w * 0.4, yMid + 7);
      for (double x = w * 0.4; x >= -w * 0.4; x -= 12) {
        final y = yMid + 7 + math.sin((x / 36) + t * math.pi * 2 + band + 0.5) * 3.5;
        path.lineTo(waveX + x, y);
      }
      path.close();
      canvas.drawPath(path, bandPaint);
    }
  }

  @override
  bool shouldRepaint(_OceanShimmerPainter old) => old.t != t;
}
