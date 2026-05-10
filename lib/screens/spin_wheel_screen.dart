import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

/// Tropical spin wheel — a wooden wheel framed in golden rope, with
/// tropical-coded prize segments, a swinging mallet pointer, and a Coco
/// hub at the center. Big "stop reveal" burst on win.
class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _burstCtrl;
  late final AnimationController _malletCtrl;
  bool _spinning = false;
  int? _resultIdx;
  Map<String, int>? _resultPrize;

  static const _segments = <_Segment>[
    _Segment(label: '50',    sub: '',       icon: Icons.monetization_on_rounded, color: TT.lagoon),
    _Segment(label: '100',   sub: '',       icon: Icons.monetization_on_rounded, color: TT.coral),
    _Segment(label: '200',   sub: '',       icon: Icons.monetization_on_rounded, color: TT.palm),
    _Segment(label: '300',   sub: 'JACKPOT',icon: Icons.diamond_rounded,           color: TT.gold),
    _Segment(label: 'Çekiç', sub: '',       icon: Icons.gavel_rounded,            color: TT.bamboo),
    _Segment(label: 'Renk',  sub: '',       icon: Icons.auto_awesome_rounded,     color: TT.lagoonDark),
    _Segment(label: '+3',    sub: '',       icon: Icons.skip_next_rounded,        color: TT.coralDark),
    _Segment(label: '50',    sub: '',       icon: Icons.monetization_on_rounded, color: TT.lagoon),
  ];

  static const prizes = <Map<String, int>>[
    {'coins': 50},
    {'coins': 100},
    {'coins': 200},
    {'coins': 300},
    {'hammer': 1},
    {'colorBlast': 1},
    {'extraMoves': 1},
    {'coins': 50},
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4500));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    // Mallet pointer "tick" — driven manually as the wheel rotates past
    // each segment boundary.
    _malletCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0,
      upperBound: 1,
    );
    _spinCtrl.addListener(_onSpinTick);
  }

  @override
  void dispose() {
    _spinCtrl.removeListener(_onSpinTick);
    _spinCtrl.dispose();
    _glowCtrl.dispose();
    _burstCtrl.dispose();
    _malletCtrl.dispose();
    super.dispose();
  }

  // Track the previous "segment under pointer" so we can fire the mallet
  // animation when the boundary passes.
  int _lastSegUnderPointer = -1;
  void _onSpinTick() {
    if (!_spinning) return;
    // Final wheel angle = (12 full revolutions) + (target offset).
    // Segment[i] centroid initially at -π/2 + i*step; after rotation `-angle`,
    // it lands at -π/2 + i*step - angle. Solving for centroid = -π/2 gives
    // i = (angle / step) mod N → that's the segment under the top pointer.
    final step = 2 * math.pi / _segments.length;
    final target = (_resultIdx ?? 0) * step;
    final angle = _spinCtrl.value * (12 * 2 * math.pi + target);
    final segIdx = (angle / step).floor() % _segments.length;
    if (segIdx != _lastSegUnderPointer) {
      _lastSegUnderPointer = segIdx;
      // Fire only if we're not already mid-animation, so quick spins
      // don't queue up endless animations.
      if (!_malletCtrl.isAnimating) _malletCtrl.forward(from: 0);
    }
  }

  Future<void> _doSpin({required bool free}) async {
    if (_spinning) return;
    final notifier = ref.read(playerProgressProvider.notifier);
    final progress = ref.read(playerProgressProvider);
    if (!free && progress.coins < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: TT.coral,
          content: Text('Yeterli altının yok!', textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _spinning = true;
      _resultIdx = null;
      _resultPrize = null;
    });
    final target = math.Random().nextInt(_segments.length);
    _resultIdx = target;
    _spinCtrl.reset();
    _spinCtrl.animateTo(1.0, curve: const _DecelCurve());
    await Future.delayed(const Duration(milliseconds: 4500));
    final ok = await notifier.spinWheel(target, free: free);
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _resultPrize = ok ? prizes[target] : null;
    });
    if (ok) _burstCtrl.forward(from: 0);
    await notifier.checkAchievements();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final notifier = ref.read(playerProgressProvider.notifier);
    final isFree = notifier.isFreeSpinAvailable;
    final msLeft = notifier.msUntilFreeSpin;

    return IslandScaffold(
      backgroundAsset: TA.spinWheelBg,
      overlayOpacity: 0.45,
      child: Stack(
        children: [
          Column(
            children: [
              IslandTopBar(
                stars: progress.totalStars,
                coins: progress.coins,
                hearts: progress.lives,
                leading: IslandCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go('/map'),
                ),
              ),
              const SizedBox(height: 10),
              _Headline(),
              const Spacer(flex: 1),
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _AmbientGlow(controller: _glowCtrl),
                          _RopeFrame(),
                          _WheelDisc(
                            segments: _segments,
                            spinCtrl: _spinCtrl,
                            resultIdx: _resultIdx,
                            spinning: _spinning,
                            burstCtrl: _burstCtrl,
                          ),
                          _CenterHub(glowCtrl: _glowCtrl),
                          _MalletPointer(controller: _malletCtrl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                child: _resultPrize != null
                    ? _PrizePanel(
                        prize: _resultPrize!,
                        onClose: () => setState(() {
                          _resultPrize = null;
                          _resultIdx = null;
                        }),
                      )
                    : Column(
                        children: [
                          IslandButton(
                            text: isFree ? 'Bedava Çevir' : '4 Saat Sonra Bedava',
                            icon: isFree
                                ? Icons.bolt_rounded
                                : Icons.access_time_rounded,
                            color: isFree
                                ? IslandButtonColor.palm
                                : IslandButtonColor.bamboo,
                            size: IslandButtonSize.large,
                            fullWidth: true,
                            onPressed:
                                isFree && !_spinning ? () => _doSpin(free: true) : null,
                          ),
                          if (!isFree) ...[
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(msLeft),
                              style: TT.bodySmall.copyWith(
                                color: TT.sandLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          IslandButton(
                            text: 'Çevir (100 altın)',
                            leading: const Icon(Icons.monetization_on_rounded,
                                color: Colors.white, size: 22),
                            color: IslandButtonColor.coral,
                            size: IslandButtonSize.medium,
                            fullWidth: true,
                            onPressed: !_spinning && progress.coins >= 100
                                ? () => _doSpin(free: false)
                                : null,
                          ),
                          if (AdManager.instance.isRewardedAdReady) ...[
                            const SizedBox(height: 8),
                            IslandButton(
                              text: 'Reklam İzle Bedava Çevir',
                              leading: const Icon(Icons.play_circle_filled_rounded,
                                  color: Colors.white, size: 22),
                              color: IslandButtonColor.lagoon,
                              size: IslandButtonSize.medium,
                              fullWidth: true,
                              onPressed: !_spinning
                                  ? () {
                                      AdManager.instance.showRewardedAd(
                                        onRewarded: () {
                                          if (mounted) _doSpin(free: true);
                                        },
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          // Stop reveal overlay — confetti + flash above all UI when prize lands.
          if (_resultPrize != null && _burstCtrl.value > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burstCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _StopBurstPainter(progress: _burstCtrl.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final h = ms ~/ (1000 * 60 * 60);
    final m = (ms ~/ (1000 * 60)) % 60;
    return 'Sonraki bedava: ${h}s ${m}d';
  }
}

// ─── Headline plaque ────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: TT.gold.withAlpha(140), blurRadius: 18, spreadRadius: -2),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.coralLight, TT.coral, TT.coralDark],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, color: TT.goldShine, size: 22),
              const SizedBox(width: 8),
              Text(
                'COCO\'NUN ÇARKI',
                style: TT.titleLarge.copyWith(
                  color: TT.sandLight,
                  letterSpacing: 1.6,
                  fontSize: 18,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
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

// ─── Pulsing gold halo behind the wheel ──────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  final AnimationController controller;
  const _AmbientGlow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TT.gold.withAlpha((90 + 100 * t).toInt()),
                blurRadius: 60,
                spreadRadius: 16 + 8 * t,
              ),
              BoxShadow(
                color: TT.coralLight.withAlpha((40 + 60 * t).toInt()),
                blurRadius: 80,
                spreadRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Rope-wrapped outer frame ───────────────────────────────────────────────

class _RopeFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RopePainter(),
      size: const Size.square(380),
    );
  }
}

class _RopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;

    // Outer dark wood ring (the wheel's edge shadow).
    final shadow = Paint()
      ..color = Colors.black.withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(c.translate(0, 6), outerR * 0.93, shadow);

    // Rope band — alternating gold/dark twist look.
    final ropeR = outerR * 0.92;
    const segs = 36;
    for (int i = 0; i < segs; i++) {
      final a1 = i * (math.pi * 2 / segs);
      final a2 = (i + 1) * (math.pi * 2 / segs);
      final p = Path()
        ..moveTo(c.dx + math.cos(a1) * (ropeR - 14), c.dy + math.sin(a1) * (ropeR - 14))
        ..lineTo(c.dx + math.cos(a1) * (ropeR + 4), c.dy + math.sin(a1) * (ropeR + 4))
        ..arcToPoint(
          Offset(c.dx + math.cos(a2) * (ropeR + 4), c.dy + math.sin(a2) * (ropeR + 4)),
          radius: Radius.circular(ropeR + 4),
          clockwise: true,
        )
        ..lineTo(c.dx + math.cos(a2) * (ropeR - 14), c.dy + math.sin(a2) * (ropeR - 14))
        ..arcToPoint(
          Offset(c.dx + math.cos(a1) * (ropeR - 14), c.dy + math.sin(a1) * (ropeR - 14)),
          radius: Radius.circular(ropeR - 14),
          clockwise: false,
        )
        ..close();

      final paint = Paint()
        ..shader = (i.isEven
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [TT.goldShine, TT.gold, TT.goldDeep],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [TT.driftWood, TT.driftWoodDark],
                  ))
            .createShader(Rect.fromCircle(center: c, radius: ropeR + 4));
      canvas.drawPath(p, paint);
    }

    // 8 nail studs around the rope.
    const studs = 8;
    for (int i = 0; i < studs; i++) {
      final ang = i * (math.pi * 2 / studs) - math.pi / 2;
      final pos = Offset(c.dx + math.cos(ang) * ropeR, c.dy + math.sin(ang) * ropeR);
      canvas.drawCircle(
        pos,
        7,
        Paint()
          ..shader = const RadialGradient(
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ).createShader(Rect.fromCircle(center: pos, radius: 7)),
      );
      canvas.drawCircle(
        pos,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = TT.goldDeep,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RopePainter old) => false;
}

// ─── Spinnable wheel disc — colored prize segments ──────────────────────────

class _WheelDisc extends StatelessWidget {
  final List<_Segment> segments;
  final AnimationController spinCtrl;
  final AnimationController burstCtrl;
  final int? resultIdx;
  final bool spinning;

  const _WheelDisc({
    required this.segments,
    required this.spinCtrl,
    required this.burstCtrl,
    required this.resultIdx,
    required this.spinning,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([spinCtrl, burstCtrl]),
      builder: (_, __) {
        // Wheel rotates `angle` radians (negative direction visually).
        // Segment[i] centroid sits at -π/2 + i*step before rotation. To land
        // segment[resultIdx] under the top pointer (-π/2) after spin, the
        // rotation must equal `+i*step`. We add 12 full revolutions for flair.
        final step = 2 * math.pi / segments.length;
        final target = (resultIdx ?? 0) * step;
        final angle = spinCtrl.value * (12 * 2 * math.pi + target);
        return SizedBox(
          width: 320,
          height: 320,
          child: Transform.rotate(
            angle: -angle,
            child: CustomPaint(
              // Single source of truth — clean disc with colored segments
              // and one big label per slice. No Leonardo asset overlay
              // (it had pre-painted numbers that doubled with our labels).
              painter: _DiscPainter(
                segments: segments,
                winnerIdx: !spinning && burstCtrl.value > 0 ? resultIdx : null,
                winnerPulse: burstCtrl.value,
              ),
              size: const Size.square(320),
            ),
          ),
        );
      },
    );
  }
}

class _DiscPainter extends CustomPainter {
  final List<_Segment> segments;
  final int? winnerIdx;
  final double winnerPulse;

  _DiscPainter({
    required this.segments,
    required this.winnerIdx,
    required this.winnerPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Dark wooden disc base.
    final wood = Paint()
      ..shader = const RadialGradient(
        colors: [TT.driftWood, TT.driftWoodDark, Color(0xFF2A1A0A)],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, wood);

    final segR = r - 6;
    final n = segments.length;
    final step = 2 * math.pi / n;
    for (int i = 0; i < n; i++) {
      final start = -math.pi / 2 - step / 2 + i * step;
      final seg = segments[i];
      final isWinner = winnerIdx == i;
      final base = isWinner
          ? Color.lerp(seg.color, TT.goldShine, 0.3 + winnerPulse * 0.5)!
          : seg.color;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, Colors.white, 0.32)!,
            base,
            Color.lerp(base, Colors.black, 0.35)!,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: segR));
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: segR), start, step, false)
        ..close();
      canvas.drawPath(path, paint);

      // Segment divider — gold edge.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..color = TT.goldDeep,
      );

      // Winner pulse outline.
      if (isWinner) {
        final pulseR = segR * (1 + 0.02 * (1 - winnerPulse));
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: pulseR - 4),
          start,
          step,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = TT.goldShine.withAlpha((220 * (1 - winnerPulse)).toInt().clamp(0, 220)),
        );
      }

      // Segment content — ONE big label, dead-centre, tangent. No icon, no
      // sub-label. The previous icon+label+sub stack overlapped on narrow
      // 45° segments; minimal text is the only thing that actually fits.
      final labelAngle = start + step / 2;
      canvas.save();
      canvas.translate(
        c.dx + math.cos(labelAngle) * segR * 0.58,
        c.dy + math.sin(labelAngle) * segR * 0.58,
      );
      canvas.rotate(labelAngle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: seg.label.length > 5 ? 17 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            height: 1.0,
            shadows: [
              Shadow(color: Colors.black.withAlpha(230), blurRadius: 5, offset: const Offset(0, 2)),
              Shadow(color: Colors.black.withAlpha(180), blurRadius: 1, offset: const Offset(0, 0)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Thin gold rim around the disc.
    canvas.drawCircle(
      c,
      segR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = TT.goldDeep,
    );
  }

  @override
  bool shouldRepaint(covariant _DiscPainter old) =>
      old.winnerIdx != winnerIdx || old.winnerPulse != winnerPulse;
}

// ─── Coco-faced center hub ─────────────────────────────────────────────────

class _CenterHub extends StatelessWidget {
  final AnimationController glowCtrl;
  const _CenterHub({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, __) {
        final t = glowCtrl.value;
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TT.goldShine, TT.gold, TT.goldDeep],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 14, offset: const Offset(0, 4)),
              BoxShadow(color: TT.gold.withAlpha((140 + 80 * t).toInt()), blurRadius: 24, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.lagoon, TT.lagoonDark],
              ),
              border: Border.all(color: TT.goldShine, width: 2),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: const MascotView(
                  pose: MascotPose.victory,
                  height: 86,
                  bobbing: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Wooden mallet pointer at top — wobbles each segment tick ──────────────

class _MalletPointer extends StatelessWidget {
  final AnimationController controller;
  const _MalletPointer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // Wobble: lean to +18° at t=0.4, ease back to 0°.
        final t = controller.value;
        final lean = t < 0.4
            ? (t / 0.4) * 0.32
            : 0.32 * (1 - (t - 0.4) / 0.6);
        return Align(
          alignment: const Alignment(0, -0.94),
          child: Transform.rotate(
            angle: lean,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size(54, 84),
              painter: _MalletPainter(),
            ),
          ),
        );
      },
    );
  }
}

class _MalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drop shadow.
    final shadow = Paint()
      ..color = Colors.black.withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final body = Path()
      ..moveTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2 + 8, 0)
      ..lineTo(size.width / 2 + 22, size.height * 0.4)
      ..lineTo(size.width / 2 + 4, size.height * 0.55)
      ..lineTo(size.width / 2 + 4, size.height)
      ..lineTo(size.width / 2 - 4, size.height)
      ..lineTo(size.width / 2 - 4, size.height * 0.55)
      ..lineTo(size.width / 2 - 22, size.height * 0.4)
      ..close();
    canvas.drawPath(body.shift(const Offset(0, 3)), shadow);

    // Mallet head (gold).
    final headRect = Rect.fromLTWH(
      size.width / 2 - 24,
      size.height * 0.05,
      48,
      size.height * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ).createShader(headRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = TT.goldDeep,
    );

    // Wood handle (driftwood).
    final handleRect = Rect.fromLTWH(
      size.width / 2 - 5,
      size.height * 0.55,
      10,
      size.height * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.driftWood, TT.driftWoodDark],
        ).createShader(handleRect),
    );

    // Tip — pointing downward into the wheel rim.
    final tip = Path()
      ..moveTo(size.width / 2 - 8, size.height * 0.95)
      ..lineTo(size.width / 2 + 8, size.height * 0.95)
      ..lineTo(size.width / 2, size.height + 4)
      ..close();
    canvas.drawPath(
      tip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ).createShader(Rect.fromLTWH(0, size.height * 0.9, size.width, 14)),
    );
  }

  @override
  bool shouldRepaint(covariant _MalletPainter old) => false;
}

// ─── Prize panel + screen-wide stop burst ──────────────────────────────────

class _PrizePanel extends StatelessWidget {
  final Map<String, int> prize;
  final VoidCallback onClose;
  const _PrizePanel({required this.prize, required this.onClose});

  String _format(Map<String, int> p) {
    final parts = <String>[];
    if ((p['coins'] ?? 0) > 0) parts.add('${p['coins']} altın');
    if ((p['hammer'] ?? 0) > 0) parts.add('${p['hammer']} Çekiç');
    if ((p['colorBlast'] ?? 0) > 0) parts.add('${p['colorBlast']} Renk Patlatma');
    if ((p['extraMoves'] ?? 0) > 0) parts.add('${p['extraMoves']} +3 Hamle');
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: IslandPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded, color: TT.coral, size: 26),
                const SizedBox(width: 8),
                Text('TEBRİKLER!',
                    style: TT.titleLarge.copyWith(color: TT.goldDeep, letterSpacing: 1.4)),
                const SizedBox(width: 8),
                const Icon(Icons.celebration_rounded, color: TT.coral, size: 26),
              ],
            ),
            const SizedBox(height: 6),
            Text(_format(prize),
                style: TT.titleMedium.copyWith(color: TT.driftWoodDark)),
            const SizedBox(height: 12),
            IslandButton(
              text: 'Tamam',
              icon: Icons.check_rounded,
              color: IslandButtonColor.palm,
              size: IslandButtonSize.medium,
              fullWidth: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopBurstPainter extends CustomPainter {
  final double progress;
  _StopBurstPainter({required this.progress});

  static const _confetti = [
    Color(0xFFFFD91A),
    Color(0xFF338CFF),
    Color(0xFF33D973),
    Color(0xFFFF4D80),
    Color(0xFFFF801A),
    Color(0xFFE63946),
    Color(0xFFFFE89C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // Initial flash on the wheel (top-half of screen).
    final flashAlpha = ((1 - (progress * 2.5).clamp(0, 1)) * 130).toInt();
    if (flashAlpha > 0) {
      final c = Offset(size.width / 2, size.height * 0.42);
      canvas.drawCircle(
        c,
        size.width * 0.7 * (0.4 + progress * 0.6),
        Paint()
          ..color = const Color(0xFFFFE89C).withAlpha(flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
    // Confetti rain.
    final rng = math.Random(31);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final yStart = -30 - rng.nextDouble() * 200;
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final y = yStart + progress * size.height * 1.2 * speed;
      if (y < -30 || y > size.height + 50) continue;
      final color = _confetti[i % _confetti.length];
      final s = 4.5 + rng.nextDouble() * 5;
      final rot = rng.nextDouble() * math.pi * 2 + progress * math.pi * 4;
      final swayX = math.sin(progress * math.pi * 2.5 + i.toDouble()) * 16;
      canvas.save();
      canvas.translate(x + swayX, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 1.4),
        Paint()..color = color.withAlpha(((1 - progress) * 230).toInt().clamp(0, 230)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StopBurstPainter old) => old.progress != progress;
}

// ─── Models ─────────────────────────────────────────────────────────────────

class _Segment {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  const _Segment({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
  });
}

/// Decel curve for the spin — fast start, smooth tail.
class _DecelCurve extends Curve {
  const _DecelCurve();
  @override
  double transformInternal(double t) {
    return 1 - math.pow(1 - t, 3).toDouble();
  }
}
