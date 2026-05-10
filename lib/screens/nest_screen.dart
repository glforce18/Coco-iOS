import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/models/player_progress.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';
import 'package:patpat_game/widgets/tropical/tropical_frame.dart';
import 'package:patpat_game/widgets/tropical/red_ribbon_banner.dart';

/// Yuva (Nest) — egg incubator screen. Three slots accumulate heat after
/// each completed level; ready eggs hatch into common or rare birds.
class NestScreen extends ConsumerStatefulWidget {
  const NestScreen({super.key});

  @override
  ConsumerState<NestScreen> createState() => _NestScreenState();
}

class _NestScreenState extends ConsumerState<NestScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wobbleCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _sparkleCtrl;
  String? _hatchingBirdId; // when not null, hatch overlay is showing

  @override
  void initState() {
    super.initState();
    _wobbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    _glowCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onHatchTapped(int slotIndex) async {
    final birdId = await ref.read(playerProgressProvider.notifier).hatchEgg(slotIndex);
    if (birdId == null || !mounted) return;
    SoundManager.instance.play(SoundManager.special, volume: 0.85);
    setState(() => _hatchingBirdId = birdId);
  }

  void _dismissHatchOverlay() {
    setState(() => _hatchingBirdId = null);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    return IslandScaffold(
      backgroundAsset: TA.nestSceneBg,
      overlayOpacity: 0.30,
      child: Stack(
        children: [
          // Animated tropical frame — palm leaves sway + string lights pulse
          const Positioned.fill(child: TropicalFrame()),
          Column(
            children: [
              IslandTopBar(
                stars: progress.totalStars,
                coins: progress.coins,
                hearts: progress.lives,
                leading: IslandCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.go('/profile'),
                ),
              ),
              const SizedBox(height: 14),
              // YUVA red ribbon banner
              const Center(child: RedRibbonBanner(text: 'YUVA')),
              const SizedBox(height: 6),
              // Big yellow headline "BÖLÜMLERİ TAMAMLA, YENİ KUŞLARI AÇ!"
              const _BigYellowHeadline(),
              const SizedBox(height: 14),
              // 3-step infographic: 1.Bölüm → 10.Bölüm → 25.Bölüm
              const _ProgressionInfographic(),
              const SizedBox(height: 16),
              // 3 egg slots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(progress.eggSlots.length, (i) {
                    return Expanded(
                      child: _EggSlotView(
                        eggState: ref.read(playerProgressProvider.notifier).eggStateFor(i),
                        currentLevel: progress.currentLevel,
                        wobble: _wobbleCtrl,
                        glow: _glowCtrl,
                        sparkle: _sparkleCtrl,
                        slotIndex: i,
                        onHatchTap: () => _onHatchTapped(i),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              // Helper text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withAlpha(140),
                  border: Border.all(color: TT.gold.withAlpha(180), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: TT.goldShine, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bölümleri ilerledikçe yumurtalar çatlar ve açılır. 1. yumurta 25. bölüm, 2. yumurta 75. bölüm, 3. yumurta 175. bölüm!',
                        style: TT.bodySmall.copyWith(color: TT.sandLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Collection counter
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.goldShine, TT.gold, TT.goldDeep],
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: TT.driftPanelGradient,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.collections_bookmark_rounded, color: TT.goldShine, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${progress.hatchedBirds.length} / ${PlayerProgressNotifier.allBirds.length} kuş',
                          style: TT.titleSmall.copyWith(
                            color: TT.sandLight,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Vitrine
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _Vitrine(hatched: progress.hatchedBirds),
                ),
              ),
            ],
          ),
          // Hatch overlay
          if (_hatchingBirdId != null)
            _HatchOverlay(
              birdId: _hatchingBirdId!,
              onDismiss: _dismissHatchOverlay,
            ),
        ],
      ),
    );
  }
}

// ─── Egg slot view ────────────────────────────────────────────────────────
class _EggSlotView extends StatelessWidget {
  final EggDisplayState eggState;
  final int currentLevel;
  final AnimationController wobble;
  final AnimationController glow;
  final AnimationController sparkle;
  final int slotIndex;
  final VoidCallback onHatchTap;

  const _EggSlotView({
    required this.eggState,
    required this.currentLevel,
    required this.wobble,
    required this.glow,
    required this.sparkle,
    required this.slotIndex,
    required this.onHatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final ready = eggState == EggDisplayState.open;
    final cracked = eggState == EggDisplayState.cracked;
    final hatched = eggState == EggDisplayState.hatched;
    // Progress toward this slot's next milestone (for the small label).
    final completed = currentLevel - 1;
    final crackLvl = EggSlot.crackLevels[slotIndex];
    final openLvl = EggSlot.openLevels[slotIndex];

    return AnimatedBuilder(
      animation: Listenable.merge([wobble, glow, sparkle]),
      builder: (context, _) {
        // Wobble: only for cracked + ready eggs; intact is calm.
        final wobbleAngle = (cracked || ready)
            ? math.sin(wobble.value * math.pi * 2 + slotIndex) * (cracked ? 0.06 : 0.12)
            : 0.0;
        final glowAlpha = ready
            ? (200 + math.sin(glow.value * math.pi) * 55).toInt().clamp(0, 255)
            : cracked
                ? (90 + math.sin(glow.value * math.pi) * 35).toInt().clamp(0, 255)
                : 60;
        final crackLevel = ready ? 1.0 : (cracked ? 0.55 : 0.0);

        return GestureDetector(
          onTap: ready ? onHatchTap : null,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow halo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (ready ? TT.goldShine : TT.coral).withAlpha(glowAlpha),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                    // Sparkles around ready egg
                    if (ready)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SparklePainter(t: sparkle.value),
                        ),
                      ),
                    // Egg or hatched bird
                    Transform.rotate(
                      angle: wobbleAngle,
                      child: hatched
                          ? const _HatchedBirdSprite()
                          : _EggSprite(crackLevel: crackLevel, ready: ready),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Status label
              if (ready)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: TT.coralButtonGradient,
                    border: Border.all(color: TT.goldShine, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: TT.coral.withAlpha(140), blurRadius: 10),
                    ],
                  ),
                  child: const Text(
                    'AÇMAK İÇİN DOKUN!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(0, 1))],
                    ),
                  ),
                )
              else if (hatched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: TT.palmButtonGradient,
                    border: Border.all(color: TT.goldShine, width: 1.5),
                  ),
                  child: const Text(
                    'AÇILDI ✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(0, 1))],
                    ),
                  ),
                )
              else
                _EggMilestoneLabel(
                  completed: completed,
                  crackLvl: crackLvl,
                  openLvl: openLvl,
                  cracked: cracked,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom label under each egg: "10. bölümde çatlar / 25. bölümde açılır"
/// or progress toward next milestone.
class _EggMilestoneLabel extends StatelessWidget {
  final int completed;
  final int crackLvl;
  final int openLvl;
  final bool cracked;
  const _EggMilestoneLabel({
    required this.completed,
    required this.crackLvl,
    required this.openLvl,
    required this.cracked,
  });

  @override
  Widget build(BuildContext context) {
    // While intact: show "10. bölümde çatlar"
    // While cracked: show "25. bölümde açılır"
    final target = cracked ? openLvl : crackLvl;
    final verb = cracked ? 'açılır' : 'çatlar';
    final progress = ((completed / target).clamp(0.0, 1.0)).toDouble();
    return SizedBox(
      width: 86,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: Colors.black.withAlpha(180)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TT.coralLight, TT.coral, TT.goldShine],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$target. bölümde $verb',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TT.sandLight,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny chibi parrot shown when an egg has been hatched.
class _HatchedBirdSprite extends StatelessWidget {
  const _HatchedBirdSprite();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 80,
      child: CustomPaint(painter: _ChibiBirdPainter()),
    );
  }
}

class _ChibiBirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 4;
    final r = size.width * 0.36;

    // Body — blue
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF4A8FE7), const Color(0xFF1E5BB8)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFF0A2A5C).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Yellow chest
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.3), width: r * 1.1, height: r * 0.9),
      Paint()..color = const Color(0xFFFFCB3D),
    );
    // Eyes
    final eyeWhite = Paint()..color = Colors.white;
    final eyeBlack = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.1), r * 0.2, eyeWhite);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.1), r * 0.2, eyeWhite);
    canvas.drawCircle(Offset(cx - r * 0.26, cy - r * 0.1), r * 0.12, eyeBlack);
    canvas.drawCircle(Offset(cx + r * 0.34, cy - r * 0.1), r * 0.12, eyeBlack);
    // Beak
    final beakPath = Path()
      ..moveTo(cx - r * 0.1, cy + r * 0.1)
      ..lineTo(cx + r * 0.1, cy + r * 0.1)
      ..lineTo(cx, cy + r * 0.3)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFF8E2E));
    canvas.drawPath(
      beakPath,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _EggSprite extends StatelessWidget {
  final double crackLevel; // 0..1
  final bool ready;
  const _EggSprite({required this.crackLevel, required this.ready});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: CustomPaint(
        painter: _EggPainter(crackLevel: crackLevel, ready: ready),
      ),
    );
  }
}

class _EggPainter extends CustomPainter {
  final double crackLevel;
  final bool ready;
  _EggPainter({required this.crackLevel, required this.ready});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Egg body shape (drop-like ellipse)
    final eggRect = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.95, height: h * 0.95);
    // Shadow
    canvas.drawOval(
      eggRect.translate(0, 3),
      Paint()..color = Colors.black.withAlpha(120)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Egg base — cream gradient
    canvas.drawOval(
      eggRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF1D9), Color(0xFFE6C58F), Color(0xFFB8893B)],
        ).createShader(eggRect),
    );
    // Speckles
    final rng = math.Random(42);
    for (int i = 0; i < 14; i++) {
      final x = w * 0.2 + rng.nextDouble() * w * 0.6;
      final y = h * 0.15 + rng.nextDouble() * h * 0.7;
      canvas.drawCircle(
        Offset(x, y),
        1.2 + rng.nextDouble() * 1.4,
        Paint()..color = const Color(0xFF6B4226).withAlpha(180),
      );
    }
    // Top highlight (white sheen)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.4, h * 0.25), width: w * 0.4, height: h * 0.18),
      Paint()..color = Colors.white.withAlpha(140)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Cracks appear progressively (>=30% heat)
    if (crackLevel > 0.3) {
      final crackPaint = Paint()
        ..color = Colors.black.withAlpha((180 * (crackLevel - 0.3) / 0.7).toInt().clamp(0, 220))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      // Zigzag crack 1
      final p1 = Path()
        ..moveTo(w * 0.5, h * 0.2)
        ..lineTo(w * 0.55, h * 0.32)
        ..lineTo(w * 0.45, h * 0.45)
        ..lineTo(w * 0.6, h * 0.55);
      canvas.drawPath(p1, crackPaint);
      if (crackLevel > 0.6) {
        // Crack 2 — branch
        final p2 = Path()
          ..moveTo(w * 0.45, h * 0.45)
          ..lineTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.4, h * 0.65);
        canvas.drawPath(p2, crackPaint);
      }
      if (ready) {
        // Crack 3 — almost broken
        final p3 = Path()
          ..moveTo(w * 0.6, h * 0.55)
          ..lineTo(w * 0.7, h * 0.65)
          ..lineTo(w * 0.55, h * 0.75);
        canvas.drawPath(p3, crackPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EggPainter old) => old.crackLevel != crackLevel || old.ready != ready;
}

class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rng = math.Random(11);
    for (int i = 0; i < 8; i++) {
      final phase = rng.nextDouble() * math.pi * 2;
      final r = 35 + rng.nextDouble() * 12;
      final angle = i * math.pi / 4 + t * math.pi * 2;
      final x = c.dx + math.cos(angle + phase) * r;
      final y = c.dy + math.sin(angle + phase) * r;
      final pulse = (math.sin(t * math.pi * 4 + phase) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        2.4 * pulse,
        Paint()
          ..color = const Color(0xFFFFE89C).withAlpha((180 * pulse).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => true;
}

// ─── Vitrine (collection grid) ────────────────────────────────────────────
class _Vitrine extends StatelessWidget {
  final Set<String> hatched;
  const _Vitrine({required this.hatched});

  @override
  Widget build(BuildContext context) {
    final all = PlayerProgressNotifier.allBirds;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(170), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC0F3A52), Color(0xDD052035)],
          ),
          border: Border.all(color: TT.goldShine.withAlpha(140), width: 1),
        ),
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: all.length,
          itemBuilder: (_, i) {
            final id = all[i];
            final unlocked = hatched.contains(id);
            final isRare = id.startsWith('rare_');
            return _BirdSlot(birdId: id, unlocked: unlocked, isRare: isRare);
          },
        ),
      ),
    );
  }
}

class _BirdSlot extends StatelessWidget {
  final String birdId;
  final bool unlocked;
  final bool isRare;
  const _BirdSlot({required this.birdId, required this.unlocked, required this.isRare});

  String get _assetPath => isRare
      ? 'assets/sprites/rare/$birdId.png'
      : 'assets/sprites/$birdId.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withAlpha(140),
        border: Border.all(
          color: unlocked
              ? (isRare ? TT.coralLight : TT.gold)
              : Colors.black.withAlpha(180),
          width: isRare && unlocked ? 2 : 1.2,
        ),
        boxShadow: [
          if (unlocked && isRare)
            BoxShadow(color: TT.coral.withAlpha(120), blurRadius: 8, spreadRadius: -1),
          if (unlocked && !isRare)
            BoxShadow(color: TT.gold.withAlpha(100), blurRadius: 6, spreadRadius: -1),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ColorFiltered(
        colorFilter: unlocked
            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
            : const ColorFilter.matrix(<double>[
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0.85, 0,
              ]),
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.help_outline,
            color: unlocked ? TT.goldShine : Colors.white24,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ─── Hatch overlay — dramatic reveal ──────────────────────────────────────
class _HatchOverlay extends StatefulWidget {
  final String birdId;
  final VoidCallback onDismiss;
  const _HatchOverlay({required this.birdId, required this.onDismiss});

  @override
  State<_HatchOverlay> createState() => _HatchOverlayState();
}

class _HatchOverlayState extends State<_HatchOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRare = widget.birdId.startsWith('rare_');
    final assetPath = isRare
        ? 'assets/sprites/rare/${widget.birdId}.png'
        : 'assets/sprites/${widget.birdId}.png';

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withAlpha(200),
        child: AnimatedBuilder(
          animation: Listenable.merge([_master, _shimmer]),
          builder: (context, _) {
            final t = _master.value;
            // Phase 0..0.3 — egg crack BG flash
            final flashOp = (1 - (t / 0.3).clamp(0.0, 1.0));
            // Phase 0.2..0.6 — bird scale up from 0
            final birdT = ((t - 0.2) / 0.4).clamp(0.0, 1.0);
            final birdScale = Curves.elasticOut.transform(birdT) * 1.0;
            // Phase 0.5..1.0 — text fade in
            final textOp = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Sun rays rotating
                Center(
                  child: Transform.rotate(
                    angle: _shimmer.value * math.pi * 2,
                    child: CustomPaint(
                      size: const Size(800, 800),
                      painter: _RaysPainter(opacity: 0.7, color: isRare ? TT.coral : TT.goldShine),
                    ),
                  ),
                ),
                // White flash on crack
                if (flashOp > 0)
                  Container(color: Colors.white.withAlpha((flashOp * 240).toInt())),
                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bird
                      Transform.scale(
                        scale: birdScale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isRare ? TT.coralLight : TT.goldShine).withAlpha(180),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 100, color: TT.goldShine),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Title
                      Opacity(
                        opacity: textOp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isRare ? TT.coralButtonGradient : TT.goldButtonGradient,
                            border: Border.all(color: TT.goldShine, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(220), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Text(
                            isRare ? 'NADİR KUŞ ÇATLADI! 🌟' : 'YENİ KUŞ! 🥚',
                            style: TT.titleLarge.copyWith(
                              color: TT.sandLight,
                              fontSize: 18,
                              letterSpacing: 1.4,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: textOp,
                        child: IslandButton(
                          text: 'Devam',
                          icon: Icons.check_rounded,
                          color: IslandButtonColor.palm,
                          size: IslandButtonSize.medium,
                          onPressed: widget.onDismiss,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final double opacity;
  final Color color;
  _RaysPainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.max(size.width, size.height);
    canvas.translate(c.dx, c.dy);
    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi * 2 / 12);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha((100 * opacity).toInt()), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, r * 1.2, 60));
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(angle - 0.04) * r, math.sin(angle - 0.04) * r)
        ..lineTo(math.cos(angle + 0.04) * r, math.sin(angle + 0.04) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.opacity != opacity;
}

// ─── Big yellow "BÖLÜMLERİ TAMAMLA, YENİ KUŞLARI AÇ!" headline ──────────────
class _BigYellowHeadline extends StatelessWidget {
  const _BigYellowHeadline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _outlinedYellow('BÖLÜMLERİ TAMAMLA,', 20),
          const SizedBox(height: 2),
          _outlinedYellow('YENİ KUŞLARI AÇ!', 26),
        ],
      ),
    );
  }

  Widget _outlinedYellow(String text, double size) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = const Color(0xFF3A1A0A),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6B0), Color(0xFFFFCB3D), Color(0xFFC9890A)],
          ).createShader(rect),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1.0,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 3-step progression infographic ────────────────────────────────────────
class _ProgressionInfographic extends StatefulWidget {
  const _ProgressionInfographic();

  @override
  State<_ProgressionInfographic> createState() => _ProgressionInfographicState();
}

class _ProgressionInfographicState extends State<_ProgressionInfographic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF1D9), Color(0xFFF0D29B)],
        ),
        border: Border.all(color: const Color(0xFFFFCB3D), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFE8A317).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StepCard(
              label: '1. BÖLÜM',
              caption: 'BAŞLA',
              eggState: _EggState.intact,
              glowCtrl: _glowCtrl,
            ),
          ),
          const _Arrow(),
          Expanded(
            child: _StepCard(
              label: '10. BÖLÜM',
              caption: 'ÇATLA',
              eggState: _EggState.cracked,
              glowCtrl: _glowCtrl,
            ),
          ),
          const _Arrow(),
          Expanded(
            child: _StepCard(
              label: '25. BÖLÜM',
              caption: "YENİ KUŞU\nYUVA'NA KAT!",
              eggState: _EggState.hatched,
              glowCtrl: _glowCtrl,
            ),
          ),
        ],
      ),
    );
  }
}

enum _EggState { intact, cracked, hatched }

class _StepCard extends StatelessWidget {
  final String label;
  final String caption;
  final _EggState eggState;
  final AnimationController glowCtrl;

  const _StepCard({
    required this.label,
    required this.caption,
    required this.eggState,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB8860B),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5C3A1A),
            height: 1.1,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          height: 70,
          child: AnimatedBuilder(
            animation: glowCtrl,
            builder: (context, _) => CustomPaint(
              painter: _ProgressionEggPainter(
                state: eggState,
                glow: glowCtrl.value,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: const Color(0xFFE8A317),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _ProgressionEggPainter extends CustomPainter {
  final _EggState state;
  final double glow;
  _ProgressionEggPainter({required this.state, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Nest at bottom (dark brown woven)
    final nestPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6B4A1A), Color(0xFF3A2410)],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4));
    final nestPath = Path()
      ..moveTo(w * 0.1, h * 0.95)
      ..quadraticBezierTo(cx, h * 0.7, w * 0.9, h * 0.95)
      ..close();
    canvas.drawPath(nestPath, nestPaint);

    // Nest texture twigs
    final twigPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (int i = 0; i < 7; i++) {
      final t = i / 7;
      final y = h * (0.78 + t * 0.18);
      canvas.drawLine(
        Offset(w * (0.1 + t * 0.08), y - 1),
        Offset(w * (0.9 - t * 0.08), y - 1),
        twigPaint,
      );
    }

    // Egg or parrot based on state
    final eggCx = cx;
    final eggCy = h * 0.5;
    final eggW = w * 0.55;
    final eggH = h * 0.65;

    if (state == _EggState.hatched) {
      // Glow halo
      canvas.drawCircle(
        Offset(eggCx, eggCy),
        eggW * 0.85,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE89C).withValues(alpha: 0.7 + glow * 0.2),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(eggCx, eggCy), radius: eggW * 0.85)),
      );
      // Light rays
      _drawRays(canvas, Offset(eggCx, eggCy), eggW * 0.9, glow);

      // Baby blue parrot (chibi)
      _drawChibiParrot(canvas, Offset(eggCx, eggCy * 0.95), eggW * 0.55);

      // Broken shell pieces around
      final shellPaint = Paint()..color = const Color(0xFFFFFAF0);
      final shellOutline = Paint()
        ..color = const Color(0xFF8B6F4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      // Left shell piece
      canvas.drawPath(
        Path()
          ..moveTo(eggCx - eggW * 0.5, eggCy + eggH * 0.2)
          ..lineTo(eggCx - eggW * 0.35, eggCy + eggH * 0.1)
          ..lineTo(eggCx - eggW * 0.42, eggCy + eggH * 0.25)
          ..close(),
        shellPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(eggCx - eggW * 0.5, eggCy + eggH * 0.2)
          ..lineTo(eggCx - eggW * 0.35, eggCy + eggH * 0.1)
          ..lineTo(eggCx - eggW * 0.42, eggCy + eggH * 0.25)
          ..close(),
        shellOutline,
      );
      // Right shell piece
      canvas.drawPath(
        Path()
          ..moveTo(eggCx + eggW * 0.5, eggCy + eggH * 0.2)
          ..lineTo(eggCx + eggW * 0.32, eggCy + eggH * 0.15)
          ..lineTo(eggCx + eggW * 0.44, eggCy + eggH * 0.28)
          ..close(),
        shellPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(eggCx + eggW * 0.5, eggCy + eggH * 0.2)
          ..lineTo(eggCx + eggW * 0.32, eggCy + eggH * 0.15)
          ..lineTo(eggCx + eggW * 0.44, eggCy + eggH * 0.28)
          ..close(),
        shellOutline,
      );
    } else {
      // Egg body
      final eggPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAF0), Color(0xFFE6CC9A)],
        ).createShader(Rect.fromCenter(center: Offset(eggCx, eggCy), width: eggW, height: eggH));
      final eggPath = Path()..addOval(Rect.fromCenter(center: Offset(eggCx, eggCy), width: eggW, height: eggH));
      canvas.drawPath(eggPath, eggPaint);

      // Speckles
      final speckPaint = Paint()..color = const Color(0xFF8B6F4A).withValues(alpha: 0.55);
      final rnd = math.Random(42);
      for (int i = 0; i < 10; i++) {
        final x = eggCx + (rnd.nextDouble() - 0.5) * eggW * 0.7;
        final y = eggCy + (rnd.nextDouble() - 0.5) * eggH * 0.7;
        canvas.drawCircle(Offset(x, y), 1 + rnd.nextDouble() * 1.5, speckPaint);
      }

      // Highlight
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(eggCx - eggW * 0.15, eggCy - eggH * 0.2),
          width: eggW * 0.32,
          height: eggH * 0.18,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );

      if (state == _EggState.cracked) {
        // Crack with gold glow
        final glowPaint = Paint()
          ..color = const Color(0xFFFFE89C).withValues(alpha: 0.5 + glow * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(eggCx, eggCy), eggW * 0.4, glowPaint);

        final crackPaint = Paint()
          ..color = const Color(0xFFFFB80F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        final crackPath = Path()
          ..moveTo(eggCx - eggW * 0.32, eggCy - eggH * 0.05)
          ..lineTo(eggCx - eggW * 0.1, eggCy + eggH * 0.05)
          ..lineTo(eggCx + eggW * 0.05, eggCy - eggH * 0.08)
          ..lineTo(eggCx + eggW * 0.2, eggCy + eggH * 0.08)
          ..lineTo(eggCx + eggW * 0.32, eggCy);
        canvas.drawPath(crackPath, crackPaint);

        // Sparkles around crack
        final sparkPaint = Paint()..color = const Color(0xFFFFF6B0);
        for (int i = 0; i < 4; i++) {
          final a = (i / 4) * math.pi * 2 + glow * math.pi;
          final r = eggW * 0.45;
          canvas.drawCircle(
            Offset(eggCx + math.cos(a) * r, eggCy + math.sin(a) * r),
            1.6,
            sparkPaint,
          );
        }
      }
    }
  }

  void _drawRays(Canvas canvas, Offset c, double r, double t) {
    final paint = Paint()..color = const Color(0xFFFFE89C).withValues(alpha: 0.45);
    for (int i = 0; i < 10; i++) {
      final angle = (i / 10) * math.pi * 2 + t * math.pi / 4;
      final p1 = Offset(c.dx + math.cos(angle) * r * 0.6, c.dy + math.sin(angle) * r * 0.6);
      final p2 = Offset(c.dx + math.cos(angle) * r, c.dy + math.sin(angle) * r);
      canvas.drawLine(p1, p2, paint..strokeWidth = 2);
    }
  }

  void _drawChibiParrot(Canvas canvas, Offset c, double size) {
    // Body — round blue
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF4A8FE7), const Color(0xFF1E5BB8)],
      ).createShader(Rect.fromCenter(center: c, width: size, height: size));
    canvas.drawCircle(c, size * 0.5, bodyPaint);
    canvas.drawCircle(c, size * 0.5, Paint()..color = const Color(0xFF0A2A5C).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Yellow chest
    final chestPaint = Paint()..color = const Color(0xFFFFCB3D);
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, size * 0.15), width: size * 0.55, height: size * 0.4),
      chestPaint,
    );

    // Eyes
    final eyeWhite = Paint()..color = Colors.white;
    final eyeBlack = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(c.translate(-size * 0.15, -size * 0.05), size * 0.1, eyeWhite);
    canvas.drawCircle(c.translate(size * 0.15, -size * 0.05), size * 0.1, eyeWhite);
    canvas.drawCircle(c.translate(-size * 0.13, -size * 0.05), size * 0.06, eyeBlack);
    canvas.drawCircle(c.translate(size * 0.17, -size * 0.05), size * 0.06, eyeBlack);
    canvas.drawCircle(c.translate(-size * 0.11, -size * 0.07), size * 0.02, eyeWhite);
    canvas.drawCircle(c.translate(size * 0.19, -size * 0.07), size * 0.02, eyeWhite);

    // Beak (small orange triangle)
    final beakPath = Path()
      ..moveTo(c.dx - size * 0.05, c.dy + size * 0.05)
      ..lineTo(c.dx + size * 0.05, c.dy + size * 0.05)
      ..lineTo(c.dx, c.dy + size * 0.15)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFF8E2E));
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFF8B4513)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_ProgressionEggPainter old) => old.glow != glow || old.state != state;
}
