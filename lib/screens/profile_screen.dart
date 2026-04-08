import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0235), Color(0xFF1A0660), Color(0xFF2D0B80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Animated glow orbs
            _AnimatedOrbs(animation: _orbCtrl),

            SafeArea(
              child: Column(
                children: [
                  _ProfileHeader(onBack: () {
                    SoundManager.instance.play(SoundType.buttonClick);
                    HapticManager.instance.tapLight();
                    context.go('/map');
                  }),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Mascot display
                          _MascotDisplay(
                            bounceAnimation: _bounceCtrl,
                            sparkleAnimation: _sparkleCtrl,
                          ),
                          const SizedBox(height: 16),
                          // Stats grid
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
                            SoundManager.instance.play(SoundType.buttonClick);
                            HapticManager.instance.tapLight();
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
        Offset(size.width * 0.2, size.height * (0.15 + 0.05 * sin(t * 2 * pi))),
        50.0,
        GameColors.neonPurple.withAlpha(30),
      ),
      (
        Offset(size.width * 0.8, size.height * (0.3 + 0.04 * sin(t * 2 * pi + 1))),
        40.0,
        GameColors.neonCyan.withAlpha(25),
      ),
      (
        Offset(size.width * 0.5, size.height * (0.7 + 0.06 * sin(t * 2 * pi + 2))),
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
// Mascot Display — CustomPainter jelly mascot with sparkles + bounce
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
      height: 180,
      width: 180,
      child: AnimatedBuilder(
        animation: Listenable.merge([bounceAnimation, sparkleAnimation]),
        builder: (context, _) {
          final bounce = -8.0 * sin(bounceAnimation.value * pi);
          return Transform.translate(
            offset: Offset(0, bounce),
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _MascotPainter(
                sparkleRotation: sparkleAnimation.value * 2 * pi,
                bouncePhase: bounceAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double sparkleRotation;
  final double bouncePhase;

  _MascotPainter({required this.sparkleRotation, required this.bouncePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;

    // Gold circular frame
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const SweepGradient(
        colors: [
          GameColors.goldFrame,
          GameColors.goldLight,
          GameColors.goldDark,
          GameColors.goldFrame,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 80));
    canvas.drawCircle(Offset(cx, cy), 80, framePaint);

    // Spinning sparkle ring (12 dots)
    for (int i = 0; i < 12; i++) {
      final angle = sparkleRotation + (i * 2 * pi / 12);
      final sx = cx + cos(angle) * 78;
      final sy = cy + sin(angle) * 78;
      final hue = (i * 30.0 + sparkleRotation * 180 / pi) % 360;
      final sparkColor = HSLColor.fromAHSL(1, hue, 0.9, 0.7).toColor();
      final dotPaint = Paint()
        ..color = sparkColor.withAlpha(200)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(sx, sy), 3, dotPaint);
    }

    // Body — purple gradient blob
    final bodyRect =
        Rect.fromCenter(center: Offset(cx, cy), width: 100, height: 110);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFCC80FF), Color(0xFF8B24DB), Color(0xFF5820A0)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Body shine
    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.6,
        colors: [Colors.white.withAlpha(60), Colors.white.withAlpha(0)],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, shinePaint);

    // Eyes
    _drawEye(canvas, Offset(cx - 16, cy - 12));
    _drawEye(canvas, Offset(cx + 16, cy - 12));

    // Smile
    final smilePath = Path()
      ..moveTo(cx - 14, cy + 10)
      ..quadraticBezierTo(cx, cy + 24, cx + 14, cy + 10);
    final smilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3D0080);
    canvas.drawPath(smilePath, smilePaint);

    // Cheek blush (pulsing)
    final blushAlpha = (80 + 40 * sin(bouncePhase * 2 * pi)).toInt();
    final blushPaint = Paint()
      ..color = const Color(0xFFFF80A8).withAlpha(blushAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx - 30, cy + 6), 8, blushPaint);
    canvas.drawCircle(Offset(cx + 30, cy + 6), 8, blushPaint);

    // Crown / star on top
    _drawCrown(canvas, Offset(cx, cy - 58));
  }

  void _drawEye(Canvas canvas, Offset center) {
    // White eye
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    // Pupil
    canvas.drawCircle(
        Offset(center.dx + 1, center.dy + 1), 6, Paint()..color = const Color(0xFF1A0040));
    // Shine dot
    canvas.drawCircle(
        Offset(center.dx - 2, center.dy - 3), 3, Paint()..color = Colors.white);
  }

  void _drawCrown(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx - 12, center.dy + 6)
      ..lineTo(center.dx - 14, center.dy - 4)
      ..lineTo(center.dx - 6, center.dy + 1)
      ..lineTo(center.dx, center.dy - 8)
      ..lineTo(center.dx + 6, center.dy + 1)
      ..lineTo(center.dx + 14, center.dy - 4)
      ..lineTo(center.dx + 12, center.dy + 6)
      ..close();
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [GameColors.goldLight, GameColors.goldFrame, GameColors.goldDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: center, width: 28, height: 16));
    canvas.drawPath(path, crownPaint);

    // Small star on top
    final starPaint = Paint()
      ..color = GameColors.goldLight
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(center.dx, center.dy - 10), 3, starPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => true;
}

// ---------------------------------------------------------------------------
// Stats Grid (2 cols x 3 rows)
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
      _StatData(Icons.trending_up_rounded, 'Seviye', '$level', GameColors.neonGreen),
      _StatData(Icons.star_rounded, 'Toplam Yildiz', '$totalStars', GameColors.goldFrame),
      _StatData(Icons.score_rounded, 'Toplam Skor', _formatNumber(totalScore), GameColors.hotPink),
      _StatData(Icons.monetization_on_rounded, 'Toplam Altin', '$coins', GameColors.goldLight),
      _StatData(Icons.emoji_events_rounded, 'Basarimlar', '$achievementCount', GameColors.orange),
      _StatData(Icons.local_fire_department_rounded, 'Gunluk Seri', '$streak', const Color(0xFFFF4444)),
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
              .map((s) => _StatCard(data: s, neonValue: neonAnimation.value))
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

class _StatCard extends StatelessWidget {
  final _StatData data;
  final double neonValue;

  const _StatCard({required this.data, required this.neonValue});

  @override
  Widget build(BuildContext context) {
    final borderAlpha = (60 + 60 * neonValue).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0660), Color(0xFF0D0235)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withAlpha(borderAlpha),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withAlpha(20 + (20 * neonValue).toInt()),
            blurRadius: 12,
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
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
            name: 'Cekic',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0660),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0660),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.purpleLight.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$completed/$_maxLevel seviye tamamlandi',
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
                  // Background
                  Container(color: Colors.white.withAlpha(15)),
                  // Fill
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
