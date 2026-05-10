import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Animated splash — sky gradient + tropical sunset hero BG + Coco fly-in
/// + PatPat logo shine reveal + loading dots. After ~2.6s, routes to /menu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _shine;
  late final AnimationController _mascotFloat;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _mascotFloat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Chirp at 600ms (after BG fully visible)
    Future.delayed(const Duration(milliseconds: 600), () {
      SoundManager.instance.play(SoundManager.chirp, volume: 0.85);
    });
    // Second chirp at 1.8s (mascot bobbing)
    Future.delayed(const Duration(milliseconds: 1800), () {
      SoundManager.instance.play(SoundManager.chirp, volume: 0.7);
    });
    // Success fanfare just before navigation
    Future.delayed(const Duration(milliseconds: 4200), () {
      SoundManager.instance.play(SoundManager.success, volume: 0.55);
    });
    // Navigate after full reveal + lingering moment
    Future.delayed(const Duration(milliseconds: 4600), () {
      if (mounted) context.go('/menu');
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _shine.dispose();
    _mascotFloat.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TT.oceanDeep,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final t = _master.value;
          // Phase 0..0.2 — BG fade in (0..840ms)
          final bgOp = (t / 0.2).clamp(0.0, 1.0);
          // Phase 0.1..0.4 — mascot fly in from bottom (420..1680ms)
          final mascotT = ((t - 0.1) / 0.3).clamp(0.0, 1.0);
          final mascotEase = Curves.easeOutBack.transform(mascotT);
          // Phase 0.3..0.55 — logo scale in (1260..2310ms)
          final logoT = ((t - 0.3) / 0.25).clamp(0.0, 1.0);
          final logoEase = Curves.elasticOut.transform(logoT);
          // Phase 0.92..1.0 — fade everything for transition (3860..4200ms)
          final outOp = ((t - 0.92) / 0.08).clamp(0.0, 1.0);

          final bobble = math.sin(_mascotFloat.value * math.pi) * 6;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Hero BG
              Opacity(
                opacity: bgOp,
                child: Image.asset(
                  TA.splashHero,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    TA.mainMenuHero,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(gradient: TT.skyOceanGradient),
                    ),
                  ),
                ),
              ),
              // Soft warm overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(60),
                      Colors.transparent,
                      TT.oceanNight.withAlpha(140),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Logo
              Positioned(
                top: size.height * 0.18,
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * logoEase,
                  child: Opacity(
                    opacity: logoT,
                    child: _ShinyLogo(shine: _shine.value),
                  ),
                ),
              ),
              // Mascot fly in from bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.22 -
                    (1 - mascotEase) * size.height * 0.6 +
                    bobble,
                child: Center(
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * mascotEase,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TT.goldShine.withAlpha(120),
                            TT.gold.withAlpha(60),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                      child: Image.asset(
                        TA.mascotHero,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          TA.mascotIdle,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Loading dots
              Positioned(
                bottom: size.height * 0.08,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: (mascotT * (1 - outOp)).clamp(0.0, 1.0),
                  child: AnimatedBuilder(
                    animation: _dots,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final phase = (_dots.value + i * 0.18) % 1.0;
                        final dotOp = (math.sin(phase * math.pi).clamp(0.0, 1.0));
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: TT.goldShine.withAlpha((180 * dotOp).toInt()),
                              boxShadow: [
                                BoxShadow(
                                  color: TT.gold.withAlpha((140 * dotOp).toInt()),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // Outgoing fade overlay
              if (outOp > 0)
                Container(color: Colors.black.withAlpha((outOp * 220).toInt())),
            ],
          );
        },
      ),
    );
  }
}

/// PatPat wordmark with sweeping shine highlight that loops.
class _ShinyLogo extends StatelessWidget {
  final double shine; // 0..1 cycle
  const _ShinyLogo({required this.shine});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base gold-gradient text
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
            stops: [0.0, 0.4, 0.8, 1.0],
          ).createShader(rect),
          child: Text(
            'Coco',
            style: TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1,
              shadows: [
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 16, offset: const Offset(0, 8)),
                Shadow(color: TT.coralDark, blurRadius: 6, offset: const Offset(0, 4)),
              ],
            ),
          ),
        ),
        // Sweeping white shine band
        ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              final pos = shine * 1.5 - 0.25;
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [
                  (pos - 0.12).clamp(0.0, 1.0),
                  pos.clamp(0.0, 1.0),
                  (pos + 0.12).clamp(0.0, 1.0),
                ],
              ).createShader(rect);
            },
            child: const Text(
              'Coco',
              style: TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
