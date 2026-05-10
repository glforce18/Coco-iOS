import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';

/// Combo banner with per-letter stagger + rotation swing.
/// Uses `key: ValueKey(comboCount)` so each new combo restarts the
/// animation from scratch.
class ComboText extends StatefulWidget {
  final int comboCount;
  const ComboText({super.key, required this.comboCount});

  @override
  State<ComboText> createState() => _ComboTextState();
}

class _ComboTextState extends State<ComboText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _label {
    final n = widget.comboCount;
    if (n >= 8) return 'EFSANE! x$n';
    if (n >= 6) return 'MUHTEŞEM! x$n';
    if (n >= 4) return 'HARİKA! x$n';
    if (n >= 3) return 'KOMBO! x$n';
    return 'SÜPER! x$n';
  }

  /// Color tint scales with intensity — bigger combos burn brighter.
  Color get _accent {
    if (widget.comboCount >= 6) return TT.coralLight;
    if (widget.comboCount >= 4) return TT.gold;
    return TT.goldShine;
  }

  @override
  Widget build(BuildContext context) {
    final letters = _label.split('');
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Whole-banner rotation swing: -7° → +5° → 0° (ease in-out).
        final swing = (math.sin(t * math.pi * 1.1) * 0.12) * (1 - t);
        return Transform.rotate(
          angle: swing,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < letters.length; i++)
                _StaggerLetter(
                  char: letters[i],
                  delay: i * 0.04, // 40ms stagger between letters
                  progress: t,
                  accent: _accent,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StaggerLetter extends StatelessWidget {
  final String char;
  final double delay;
  final double progress;
  final Color accent;

  const _StaggerLetter({
    required this.char,
    required this.delay,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Per-letter local progress: shifted by `delay`, then re-scaled into 0..1
    // and gated by elasticOut for a punchy bounce-in.
    final span = (1.0 - delay).clamp(0.05, 1.0);
    final raw = ((progress - delay) / span).clamp(0.0, 1.0);
    final eased = Curves.elasticOut.transform(raw);
    // Each letter pops bigger then settles to 1.0.
    final scale = 0.0 + eased.clamp(0, 1.18);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.4),
      child: Opacity(
        opacity: raw.clamp(0, 1),
        child: Transform.scale(
          scale: scale,
          child: Text(
            char,
            style: TextStyle(
              color: TT.goldShine,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(color: TT.goldDeep.withAlpha(255), blurRadius: 12),
                Shadow(color: accent.withAlpha(255), blurRadius: 24),
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
