import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

/// Profile screen showing mascot, player stats, boosters, and progress.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final AnimationController _sparkleCtrl;
  late final AnimationController _neonCtrl;
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _neonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _sparkleCtrl.dispose();
    _neonCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dream world background
          Image.asset(
            'assets/backgrounds/map_bg_dream_world.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D0235),
                    Color(0xFF1A0660),
                    Color(0xFF2D0B80),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Dark overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(100),
                  Colors.black.withAlpha(140),
                  Colors.black.withAlpha(180),
                ],
              ),
            ),
          ),

          // Animated glow orbs
          _AnimatedOrbs(animation: _orbCtrl),

          SafeArea(
            child: Column(
              children: [
                _ProfileHeader(onBack: () {
                  context.go('/map');
                }),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Mascot display with sprite image
                        _MascotDisplay(
                          bounceAnimation: _bounceCtrl,
                          sparkleAnimation: _sparkleCtrl,
                        ),
                        const SizedBox(height: 8),
                        // Player title
                        const Text(
                          'PatPat Oyuncusu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GameColors.purpleLight,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: GameColors.neonPurple,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats grid with glass-morphism
                        _StatsGrid(
                          level: progress.currentLevel,
                          totalStars: progress.totalStars,
                          totalScore: progress.totalScore,
                          coins: progress.coins,
                          achievementCount: progress.achievements.length,
                          streak: progress.dailyRewardStreak,
                          neonAnimation: _neonCtrl,
                        ),
                        const SizedBox(height: 16),
                        // Booster inventory
                        _BoosterInventory(
                          hammer: progress.hammerCount,
                          colorBlast: progress.colorBlastCount,
                          extraMoves: progress.extraMovesCount,
                        ),
                        const SizedBox(height: 16),
                        // Level progress
                        _LevelProgressBar(
                          currentLevel: progress.currentLevel,
                        ),
                        const SizedBox(height: 12),
                        // Mascot Home button
                        _MascotHomeButton(onTap: () {
                          context.go('/mascot-home');
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated background orbs
// ---------------------------------------------------------------------------

class _AnimatedOrbs extends StatelessWidget {
  final AnimationController animation;
  const _AnimatedOrbs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _OrbPainter(animation.value),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (
        Offset(size.width * 0.2,
            size.height * (0.15 + 0.05 * sin(t * 2 * pi))),
        50.0,
        GameColors.neonPurple.withAlpha(30),
      ),
      (
        Offset(size.width * 0.8,
            size.height * (0.3 + 0.04 * sin(t * 2 * pi + 1))),
        40.0,
        GameColors.neonCyan.withAlpha(25),
      ),
      (
        Offset(size.width * 0.5,
            size.height * (0.7 + 0.06 * sin(t * 2 * pi + 2))),
        60.0,
        GameColors.hotPink.withAlpha(20),
      ),
    ];

    for (final (center, radius, color) in orbs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
                border: Border.all(color: Colors.white.withAlpha(60)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [GameColors.goldLight, GameColors.goldFrame],
            ).createShader(rect),
            child: const Text(
              'PATPAT PROFIL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mascot Display — sprite image with sparkles + bounce
// ---------------------------------------------------------------------------

class _MascotDisplay extends StatelessWidget {
  final AnimationController bounceAnimation;
  final AnimationController sparkleAnimation;

  const _MascotDisplay({
    required this.bounceAnimation,
    required this.sparkleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([bounceAnimation, sparkleAnimation]),
        builder: (context, _) {
          final bounce = -8.0 * sin(bounceAnimation.value * pi);
          return Transform.translate(
            offset: Offset(0, bounce),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sparkle ring
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _SparkleRingPainter(
                    rotation: sparkleAnimation.value * 2 * pi,
                    bouncePhase: bounceAnimation.value,
                  ),
                ),
                // Gold frame circle
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameColors.goldFrame,
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.goldFrame.withAlpha(60),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: GameColors.neonPurple.withAlpha(40),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/sprites/jelly_purple.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => CustomPaint(
                        size: const Size(120, 120),
                        painter: _FallbackMascotPainter(
                          bouncePhase: bounceAnimation.value,
                        ),
                      ),
                    ),
                  ),
                ),
                // Crown on top
                Positioned(
                  top: 12,
                  child: CustomPaint(
                    size: const Size(36, 24),
                    painter: _CrownPainter(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SparkleRingPainter extends CustomPainter {
  final double rotation;
  final double bouncePhase;
  _SparkleRingPainter({required this.rotation, required this.bouncePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const radius = 90.0;

    // 12 sparkle dots
    for (int i = 0; i < 12; i++) {
      final angle = rotation + (i * 2 * pi / 12);
      final sx = cx + cos(angle) * radius;
      final sy = cy + sin(angle) * radius;
      final hue = (i * 30.0 + rotation * 180 / pi) % 360;
      final sparkColor = HSLColor.fromAHSL(1, hue, 0.9, 0.7).toColor();
      final dotPaint = Paint()
        ..color = sparkColor.withAlpha(200)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(sx, sy), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleRingPainter old) => true;
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path()
      ..moveTo(cx - 16, cy + 8)
      ..lineTo(cx - 18, cy - 4)
      ..lineTo(cx - 8, cy + 2)
      ..lineTo(cx, cy - 10)
      ..lineTo(cx + 8, cy + 2)
      ..lineTo(cx + 18, cy - 4)
      ..lineTo(cx + 16, cy + 8)
      ..close();
    final crownPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          GameColors.goldLight,
          GameColors.goldFrame,
          GameColors.goldDark,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, crownPaint);

    // Gem on top
    final gemPaint = Paint()
      ..color = GameColors.goldLight
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(cx, cy - 12), 3, gemPaint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => false;
}

class _FallbackMascotPainter extends CustomPainter {
  final double bouncePhase;
  _FallbackMascotPainter({required this.bouncePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyRect =
        Rect.fromCenter(center: Offset(cx, cy), width: 80, height: 90);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFCC80FF), Color(0xFF8B24DB), Color(0xFF5820A0)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Eyes
    canvas.drawCircle(Offset(cx - 14, cy - 8), 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx - 13, cy - 7), 5, Paint()..color = const Color(0xFF1A0040));
    canvas.drawCircle(
        Offset(cx - 15, cy - 10), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 14, cy - 8), 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx + 15, cy - 7), 5, Paint()..color = const Color(0xFF1A0040));
    canvas.drawCircle(
        Offset(cx + 13, cy - 10), 2.5, Paint()..color = Colors.white);

    // Smile
    final smilePath = Path()
      ..moveTo(cx - 12, cy + 8)
      ..quadraticBezierTo(cx, cy + 20, cx + 12, cy + 8);
    canvas.drawPath(
      smilePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3D0080),
    );

    // Blush
    final blushAlpha = (80 + 40 * sin(bouncePhase * 2 * pi)).toInt();
    final blushPaint = Paint()
      ..color = const Color(0xFFFF80A8).withAlpha(blushAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx - 24, cy + 4), 6, blushPaint);
    canvas.drawCircle(Offset(cx + 24, cy + 4), 6, blushPaint);
  }

  @override
  bool shouldRepaint(covariant _FallbackMascotPainter old) => true;
}

// ---------------------------------------------------------------------------
// Stats Grid (2 cols x 3 rows) with glass-morphism
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final int level;
  final int totalStars;
  final int totalScore;
  final int coins;
  final int achievementCount;
  final int streak;
  final AnimationController neonAnimation;

  const _StatsGrid({
    required this.level,
    required this.totalStars,
    required this.totalScore,
    required this.coins,
    required this.achievementCount,
    required this.streak,
    required this.neonAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
          Icons.trending_up_rounded, 'Seviye', '$level', GameColors.neonGreen),
      _StatData(Icons.star_rounded, 'Toplam Y\u0131ld\u0131z', '$totalStars',
          GameColors.goldFrame),
      _StatData(Icons.score_rounded, 'Toplam Skor',
          _formatNumber(totalScore), GameColors.hotPink),
      _StatData(Icons.monetization_on_rounded, 'Toplam Coin', '$coins',
          GameColors.goldLight),
      _StatData(Icons.emoji_events_rounded, 'Kazan\u0131lan Ba\u015far\u0131m',
          '$achievementCount', GameColors.orange),
      _StatData(Icons.local_fire_department_rounded, 'G\u00fcnl\u00fck Seri',
          '$streak', const Color(0xFFFF4444)),
    ];

    return AnimatedBuilder(
      animation: neonAnimation,
      builder: (context, _) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: stats
              .map((s) =>
                  _GlassStatCard(data: s, neonValue: neonAnimation.value))
              .toList(),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatData(this.icon, this.label, this.value, this.color);
}

// Glass-morphism stat card
class _GlassStatCard extends StatelessWidget {
  final _StatData data;
  final double neonValue;

  const _GlassStatCard({required this.data, required this.neonValue});

  @override
  Widget build(BuildContext context) {
    final borderAlpha = (40 + 80 * neonValue).toInt();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(18),
                data.color.withAlpha(12),
                Colors.white.withAlpha(8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: data.color.withAlpha(borderAlpha),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: data.color.withAlpha(15 + (20 * neonValue).toInt()),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color.withAlpha(30),
                  border: Border.all(
                    color: data.color.withAlpha(60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withAlpha(20),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(data.icon, color: data.color, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      data.label,
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
}

// ---------------------------------------------------------------------------
// Booster Inventory
// ---------------------------------------------------------------------------

class _BoosterInventory extends StatelessWidget {
  final int hammer;
  final int colorBlast;
  final int extraMoves;

  const _BoosterInventory({
    required this.hammer,
    required this.colorBlast,
    required this.extraMoves,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BoosterCard(
            icon: Icons.gavel_rounded,
            name: '\u00c7eki\u00e7',
            count: hammer,
            color: GameColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BoosterCard(
            icon: Icons.auto_awesome_rounded,
            name: 'Renk Patlat',
            count: colorBlast,
            color: GameColors.neonPurple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BoosterCard(
            icon: Icons.add_circle_rounded,
            name: '+3 Hamle',
            count: extraMoves,
            color: GameColors.blueLight,
          ),
        ),
      ],
    );
  }
}

class _BoosterCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final Color color;

  const _BoosterCard({
    required this.icon,
    required this.name,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(30),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GameColors.goldDark,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.goldDark.withAlpha(120),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
// Level Progress Bar
// ---------------------------------------------------------------------------

class _LevelProgressBar extends StatelessWidget {
  final int currentLevel;
  static const int _maxLevel = 240;

  const _LevelProgressBar({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final completed = (currentLevel - 1).clamp(0, _maxLevel);
    final pct = completed / _maxLevel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameColors.purpleLight.withAlpha(40)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '$completed/$_maxLevel seviye tamamland\u0131',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: GameColors.goldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withAlpha(15)),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                GameColors.neonPurple,
                                GameColors.hotPink,
                                GameColors.goldFrame,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Milestone dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1, 20, 40, 60, 80, 100, 120].map((m) {
                  final reached = currentLevel > m;
                  return Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reached
                              ? GameColors.goldFrame
                              : Colors.white.withAlpha(30),
                          border: Border.all(
                            color: reached
                                ? GameColors.goldLight
                                : Colors.white.withAlpha(50),
                            width: 1.5,
                          ),
                          boxShadow: reached
                              ? [
                                  BoxShadow(
                                    color: GameColors.goldDark.withAlpha(80),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$m',
                        style: TextStyle(
                          color: reached
                              ? GameColors.goldLight
                              : Colors.white.withAlpha(60),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mascot Home button
// ---------------------------------------------------------------------------

class _MascotHomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MascotHomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [GameColors.neonPurple, GameColors.purple],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GameColors.neonPurple.withAlpha(60),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Maskot Evine Git',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
