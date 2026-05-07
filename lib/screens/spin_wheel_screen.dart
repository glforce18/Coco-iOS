import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  // Wheel segments: label, emoji, color
  static const _segments = <_WheelSegment>[
    _WheelSegment('50', '\uD83E\uDE99', Color(0xFFFF5A9E), 'coins', 50),
    _WheelSegment('100', '\uD83E\uDE99', Color(0xFF4DA6FF), 'coins', 100),
    _WheelSegment('200', '\uD83E\uDE99', Color(0xFF5CD87A), 'coins', 200),
    _WheelSegment('300', '\uD83E\uDE99', Color(0xFFFFD84D), 'coins', 300),
    _WheelSegment('1', '\uD83D\uDD28', Color(0xFFFF8844), 'hammer', 1),
    _WheelSegment('1', '\uD83C\uDF08', Color(0xFFB366FF), 'colorBlast', 1),
    _WheelSegment('1', '\u27A1\uFE0F', Color(0xFF33E5FF), 'extraMoves', 1),
    _WheelSegment('50', '\uD83E\uDE99', Color(0xFFE08AFF), 'coins', 50),
  ];

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _ledController;
  late AnimationController _prizeController;
  late Animation<double> _prizeScale;

  bool _isSpinning = false;
  int? _wonPrizeIndex;
  double _currentRotation = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _ledController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _prizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _prizeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _prizeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _ledController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  Future<void> _spin({required bool free}) async {
    if (_isSpinning) return;

    final notifier = ref.read(playerProgressProvider.notifier);

    if (!free && ref.read(playerProgressProvider).coins < 100) {
      _showNotEnoughCoins();
      return;
    }

    setState(() {
      _isSpinning = true;
      _wonPrizeIndex = null;
    });


    // Decide which prize to land on
    final targetIndex = _random.nextInt(_segments.length);
    // Each segment is (2*pi / 8) = pi/4 radians
    final segmentAngle = 2 * pi / _segments.length;
    // We want the pointer (at top) to land in the middle of the target segment.
    // Wheel rotates clockwise, pointer is at top (12 o'clock).
    // Segment 0 starts at -pi/8 from the top. To land on segment N,
    // we need to rotate so segment N is at the top.
    final fullSpins = 6 + _random.nextInt(3); // 6-8 full spins
    final targetAngle =
        fullSpins * 2 * pi + targetIndex * segmentAngle + segmentAngle / 2;

    _spinAnimation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: const _DecelerationCurve(),
      ),
    );

    _spinController.reset();
    await _spinController.forward();

    _currentRotation = targetAngle % (2 * pi);

    // Award prize
    final success = await notifier.spinWheel(targetIndex, free: free);
    if (success) {

      setState(() {
        _wonPrizeIndex = targetIndex;
        _isSpinning = false;
      });
      _prizeController.reset();
      _prizeController.forward();

      // Check achievements
      await notifier.checkAchievements();
    } else {
      setState(() => _isSpinning = false);
    }
  }

  void _showNotEnoughCoins() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Yeterli coin yok!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: GameColors.cherryRedDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final notifier = ref.read(playerProgressProvider.notifier);
    final isFree = notifier.isFreeSpinAvailable;
    final canAfford = progress.coins >= 100;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0660),
              Color(0xFF0D0235),
              Color(0xFF050120),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Colorful bubble decorations
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _BubbleDecorationPainter(),
            ),
            SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, progress.coins),
              const Spacer(flex: 1),

              // Title
              const Text(
                '\u015eANS \u00c7ARKI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: GameColors.goldFrameBright,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: GameColors.goldFrameDeep, blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (!isFree && !_isSpinning)
                _buildCooldownTimer(notifier),
              const SizedBox(height: 16),

              // Wheel
              SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // LED ring
                    _buildLedRing(),

                    // Wheel
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        final angle = _isSpinning || _spinController.isAnimating
                            ? _spinAnimation.value
                            : _currentRotation;
                        return Transform.rotate(
                          angle: angle,
                          child: child,
                        );
                      },
                      child: _buildWheel(),
                    ),

                    // Center hub
                    _buildCenterHub(),

                    // Top pointer
                    Positioned(
                      top: 4,
                      child: _buildPointer(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Prize popup
              if (_wonPrizeIndex != null)
                _buildPrizeDisplay(_wonPrizeIndex!),

              const Spacer(flex: 1),

              // Spin button
              if (_wonPrizeIndex == null)
                _buildSpinButton(isFree, canAfford)
              else
                _buildContinueButton(),

              const SizedBox(height: 12),

              // Prize legend
              _buildPrizeLegend(),

              const SizedBox(height: 16),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: _segments.map((seg) {
          final label = seg.type == 'coins'
              ? '${seg.label} Coin'
              : seg.type == 'hammer'
                  ? '\u00c7eki\u00e7'
                  : seg.type == 'colorBlast'
                      ? 'Renk Patlat'
                      : '+3 Hamle';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: seg.color.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: seg.color.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seg.color,
                    boxShadow: [
                      BoxShadow(
                        color: seg.color.withAlpha(60),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.go('/map');
            },
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GameColors.goldFrameDeep.withAlpha(100),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameColors.goldFrameMid.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\uD83E\uDE99', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GameColors.goldFrameBright,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownTimer(PlayerProgressNotifier notifier) {
    final ms = notifier.msUntilFreeSpin;
    final hours = ms ~/ (60 * 60 * 1000);
    final minutes = (ms % (60 * 60 * 1000)) ~/ (60 * 1000);
    return Text(
      '\u00dccretsiz \u00e7evirmede: ${hours}s ${minutes}dk',
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withAlpha(160),
      ),
    );
  }

  Widget _buildLedRing() {
    return AnimatedBuilder(
      animation: _ledController,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(320, 320),
          painter: _LedRingPainter(
            progress: _ledController.value,
          ),
        );
      },
    );
  }

  Widget _buildWheel() {
    return CustomPaint(
      size: const Size(280, 280),
      painter: _WheelPainter(segments: _segments),
    );
  }

  Widget _buildCenterHub() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE44D), Color(0xFFB8860B)],
        ),
        border: Border.all(color: Colors.white.withAlpha(120), width: 2),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrameMid.withAlpha(100),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3E2000),
            letterSpacing: 1,
            shadows: [
              Shadow(color: Color(0x40000000), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointer() {
    return CustomPaint(
      size: const Size(30, 28),
      painter: _PointerPainter(),
    );
  }

  Widget _buildPrizeDisplay(int prizeIndex) {
    final segment = _segments[prizeIndex];
    return ScaleTransition(
      scale: _prizeScale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              segment.color.withAlpha(160),
              segment.color.withAlpha(80),
            ],
          ),
          border: Border.all(color: GameColors.goldFrameMid, width: 2),
          boxShadow: [
            BoxShadow(
              color: segment.color.withAlpha(100),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(segment.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(
              '+${segment.label} ${segment.type == 'coins' ? 'Coin' : segment.type == 'hammer' ? '\u00c7eki\u00e7' : segment.type == 'colorBlast' ? 'Renk Patlat' : 'Hamle'}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinButton(bool isFree, bool canAfford) {
    final Color bgTop;
    final Color bgBottom;
    final String label;

    if (isFree) {
      bgTop = const Color(0xFF30B050);
      bgBottom = const Color(0xFF1A7030);
      label = 'BEDAVA \u00c7EV\u0130R!';
    } else if (canAfford) {
      bgTop = const Color(0xFFFFD700);
      bgBottom = const Color(0xFFB8860B);
      label = '100 \uD83E\uDE99 \u00c7EV\u0130R';
    } else {
      bgTop = Colors.grey.shade600;
      bgBottom = Colors.grey.shade800;
      label = '100 \uD83E\uDE99 \u00c7EV\u0130R';
    }

    final enabled = !_isSpinning && (isFree || canAfford);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: enabled ? () => _spin(free: isFree) : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: bgTop.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isSpinning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isFree ? Colors.white : const Color(0xFF3E2000),
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _wonPrizeIndex = null;
          });
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6040A0), Color(0xFF4020A0)],
            ),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: const Center(
            child: Text(
              'DEVAM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class for wheel segments
// ---------------------------------------------------------------------------
class _WheelSegment {
  final String label;
  final String emoji;
  final Color color;
  final String type; // coins, hammer, colorBlast, extraMoves
  final int value;

  const _WheelSegment(this.label, this.emoji, this.color, this.type, this.value);
}

// ---------------------------------------------------------------------------
// Custom deceleration curve for natural spin feel
// ---------------------------------------------------------------------------
class _DecelerationCurve extends Curve {
  const _DecelerationCurve();

  @override
  double transformInternal(double t) {
    // Cubic bezier-like deceleration: fast start, slow end
    return 1 - pow(1 - t, 3).toDouble();
  }
}

// ---------------------------------------------------------------------------
// Wheel painter — draws 8 colored segments with emoji and label
// ---------------------------------------------------------------------------
class _WheelPainter extends CustomPainter {
  final List<_WheelSegment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2 - segmentAngle / 2;
      final segment = segments[i];

      // Draw segment
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            segment.color,
            segment.color.withAlpha(180),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border between segments
      final borderPaint = Paint()
        ..color = Colors.white.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final x1 = center.dx + radius * cos(startAngle);
      final y1 = center.dy + radius * sin(startAngle);
      canvas.drawLine(center, Offset(x1, y1), borderPaint);

      // Draw text (emoji + label) in the middle of the segment
      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.62;
      final tx = center.dx + textRadius * cos(midAngle);
      final ty = center.dy + textRadius * sin(midAngle);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(midAngle + pi / 2);

      // Emoji
      final emojiPainter = TextPainter(
        text: TextSpan(
          text: segment.emoji,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      emojiPainter.paint(
        canvas,
        Offset(-emojiPainter.width / 2, -emojiPainter.height - 2),
      );

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: segment.type == 'coins' ? segment.label : 'x${segment.label}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(-labelPainter.width / 2, 2),
      );

      canvas.restore();
    }

    // Outer ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFB8860B),
          Color(0xFFFFE44D),
          Color(0xFFB8860B),
          Color(0xFFFFD700),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 2, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// LED ring painter — blinking dots around the wheel
// ---------------------------------------------------------------------------
class _LedRingPainter extends CustomPainter {
  final double progress;

  _LedRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const ledCount = 16;

    for (int i = 0; i < ledCount; i++) {
      final angle = i * 2 * pi / ledCount - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      // Alternate blinking pattern
      final isLit = (i + (progress > 0.5 ? 1 : 0)) % 2 == 0;
      final alpha = isLit ? 255 : 60;

      final paint = Paint()
        ..color = GameColors.goldFrameMid.withAlpha(alpha);

      canvas.drawCircle(Offset(x, y), 4, paint);

      if (isLit) {
        final glowPaint = Paint()
          ..color = GameColors.goldFrameMid.withAlpha(40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(x, y), 6, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LedRingPainter oldDelegate) =>
      (oldDelegate.progress > 0.5) != (progress > 0.5);
}

// ---------------------------------------------------------------------------
// Pointer painter — gold triangle at top
// ---------------------------------------------------------------------------
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE44D), Color(0xFFB8860B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withAlpha(100)
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Bubble decoration painter — colorful circles in the background
// ---------------------------------------------------------------------------
class _BubbleDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(123);
    final bubbles = <(Offset, double, Color)>[
      (Offset(size.width * 0.1, size.height * 0.08), 40, const Color(0xFFFF5A9E)),
      (Offset(size.width * 0.85, size.height * 0.12), 30, const Color(0xFF4DA6FF)),
      (Offset(size.width * 0.15, size.height * 0.35), 25, const Color(0xFF5CD87A)),
      (Offset(size.width * 0.9, size.height * 0.4), 35, const Color(0xFFFFD84D)),
      (Offset(size.width * 0.5, size.height * 0.05), 20, const Color(0xFFB366FF)),
      (Offset(size.width * 0.05, size.height * 0.7), 28, const Color(0xFF33E5FF)),
      (Offset(size.width * 0.92, size.height * 0.75), 22, const Color(0xFFFF8844)),
      (Offset(size.width * 0.4, size.height * 0.88), 32, const Color(0xFFE08AFF)),
      (Offset(size.width * 0.7, size.height * 0.92), 18, const Color(0xFFFF5A9E)),
      (Offset(size.width * 0.25, size.height * 0.55), 15, const Color(0xFF4DA6FF)),
    ];

    for (final (center, radius, color) in bubbles) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withAlpha(35),
            color.withAlpha(12),
            color.withAlpha(0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);

      // Highlight dot
      final hlPaint = Paint()
        ..color = color.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        center + Offset(-radius * 0.25, -radius * 0.25),
        radius * 0.2,
        hlPaint,
      );
    }

    // Extra small random sparkle dots
    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 2.0 + rng.nextDouble() * 3;
      final hue = rng.nextDouble() * 360;
      final c = HSLColor.fromAHSL(1, hue, 0.8, 0.7).toColor().withAlpha(25);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleDecorationPainter old) => false;
}
