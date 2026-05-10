import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

enum MascotPose { idle, happy, victory, sad, sleeping, thinking, shopping, vip, hero }

extension MascotPoseAsset on MascotPose {
  String get asset {
    switch (this) {
      case MascotPose.idle:
        return TA.mascotIdle;
      case MascotPose.happy:
        return TA.mascotHappy;
      case MascotPose.victory:
        return TA.mascotVictory;
      case MascotPose.sad:
        return TA.mascotSad;
      case MascotPose.sleeping:
        return TA.mascotSleeping;
      case MascotPose.thinking:
        return TA.mascotThinking;
      case MascotPose.shopping:
        return TA.mascotShopping;
      case MascotPose.vip:
        return TA.mascotVip;
      case MascotPose.hero:
        return TA.mascotHero;
    }
  }
}

/// Animated mascot. Always playing:
///  • bobbing (sin) — gentle breathing
///  • side sway (cos) — tropical wind tilt
///  • scale pulse — heartbeat
///  • rotating gold halo (optional)
///  • excitement beat every ~5s — small extra bounce
///
/// Tap interaction (when [interactive]=true):
///  • haptic feedback + system click sound
///  • big "happy" reaction animation (3x scale up, wobble rotation, color flash)
///  • cycles through 3 happy poses (happy → victory → thinking → happy)
class MascotView extends StatefulWidget {
  final MascotPose pose;
  final double height;
  final bool showHalo;
  final bool bobbing;
  final bool interactive;

  const MascotView({
    super.key,
    this.pose = MascotPose.idle,
    this.height = 140,
    this.showHalo = false,
    this.bobbing = true,
    this.interactive = false,
  });

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _sway;
  late final AnimationController _pulse;
  late final AnimationController _halo;
  late final AnimationController _beat;
  late final AnimationController _tap;

  MascotPose? _override;
  static const _tapPoses = [MascotPose.happy, MascotPose.victory, MascotPose.thinking];
  int _tapIdx = 0;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _halo = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();
    _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _bob.dispose();
    _sway.dispose();
    _pulse.dispose();
    _halo.dispose();
    _beat.dispose();
    _tap.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.interactive) return;
    HapticFeedback.mediumImpact();
    SoundManager.instance.play(SoundManager.chirp, volume: 0.85);
    setState(() {
      _override = _tapPoses[_tapIdx % _tapPoses.length];
      _tapIdx++;
    });
    _tap.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      // small delay then return to base pose
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _override = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.interactive ? _onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _sway, _pulse, _halo, _beat, _tap]),
        builder: (context, _) {
          final bobY = widget.bobbing ? math.sin(_bob.value * math.pi * 2) * 6.0 : 0.0;
          final swayX = widget.bobbing ? math.sin(_sway.value * math.pi * 2) * 3.0 : 0.0;
          final tilt = widget.bobbing ? math.sin(_sway.value * math.pi * 2) * 0.04 : 0.0;
          final pulse = widget.bobbing ? 1.0 + math.sin(_pulse.value * math.pi * 2) * 0.025 : 1.0;

          double extraBob = 0;
          double extraScale = 1.0;
          if (widget.bobbing) {
            final t = _beat.value;
            if (t < 0.06) {
              final p = t / 0.06;
              final curve = math.sin(p * math.pi);
              extraBob = -curve * 10;
              extraScale = 1.0 + curve * 0.05;
            }
          }

          // Tap reaction (overrides everything during 700ms)
          double tapBob = 0;
          double tapScale = 1.0;
          double tapRot = 0;
          if (_tap.value > 0) {
            final t = _tap.value;
            // big upward jump + scale up + wobble rotation
            final jump = math.sin(t * math.pi);
            tapBob = -jump * 28;
            tapScale = 1.0 + jump * 0.22;
            tapRot = math.sin(t * math.pi * 4) * 0.18;
          }

          final shownPose = _override ?? widget.pose;
          final haloAlpha = (widget.showHalo ? 140 : 0) + (_tap.value * 100).toInt();

          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showHalo) ...[
                Transform.rotate(
                  angle: _halo.value * 2 * math.pi,
                  child: Container(
                    width: widget.height * 1.4,
                    height: widget.height * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          TT.goldShine.withAlpha(haloAlpha.clamp(0, 240)),
                          TT.gold.withAlpha(40),
                          TT.goldShine.withAlpha(haloAlpha.clamp(0, 240)),
                          TT.gold.withAlpha(40),
                          TT.goldShine.withAlpha(haloAlpha.clamp(0, 240)),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: widget.height * 1.3,
                  height: widget.height * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        TT.goldShine.withAlpha(180),
                        TT.gold.withAlpha(80),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
              // Tap burst — quick gold flash ring during tap reaction
              if (_tap.value > 0)
                Container(
                  width: widget.height * (1.0 + _tap.value * 0.6),
                  height: widget.height * (1.0 + _tap.value * 0.6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TT.goldShine.withAlpha(((1 - _tap.value) * 220).toInt().clamp(0, 220)),
                      width: 4,
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(swayX, bobY + extraBob + tapBob),
                child: Transform.rotate(
                  angle: tilt + tapRot,
                  child: Transform.scale(
                    scale: pulse * extraScale * tapScale,
                    child: Image.asset(
                      shownPose.asset,
                      height: widget.height,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.pets,
                        size: widget.height * 0.6,
                        color: TT.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
