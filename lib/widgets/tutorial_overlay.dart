import 'dart:math';

import 'package:flutter/material.dart';

import 'package:patpat_game/game/tutorial_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';

/// Full-screen overlay that dims the background and shows tutorial messages.
///
/// If the current step highlights specific board cells, a pulsing gold cutout
/// is drawn around them so the player can still interact with those cells.
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  /// Size of each board cell in logical pixels — used for cutout positioning.
  final double cellSize;

  /// Offset of the game board within the screen.
  final Offset boardOffset;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onContinue,
    required this.onSkip,
    this.cellSize = 44,
    this.boardOffset = Offset.zero,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasHighlight =
        widget.step.highlightFrom != null && widget.step.highlightTo != null;

    return FadeTransition(
      opacity: _fadeCtrl,
      child: Stack(
        children: [
          // Semi-transparent background with optional cutout
          if (hasHighlight)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _CutoutPainter(
                    from: widget.step.highlightFrom!,
                    to: widget.step.highlightTo!,
                    cellSize: widget.cellSize,
                    boardOffset: widget.boardOffset,
                    pulseValue: _pulseCtrl.value,
                  ),
                );
              },
            )
          else
            IgnorePointer(
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.black.withAlpha(166),
              ),
            ),

          // Message box at bottom
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: _MessageBox(
              step: widget.step,
              onContinue: () {
                widget.onContinue();
              },
              onSkip: () {
                widget.onSkip();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cutout Painter — dims everything except highlighted cells
// ---------------------------------------------------------------------------

class _CutoutPainter extends CustomPainter {
  final dynamic from; // Position
  final dynamic to;
  final double cellSize;
  final Offset boardOffset;
  final double pulseValue;

  _CutoutPainter({
    required this.from,
    required this.to,
    required this.cellSize,
    required this.boardOffset,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dim background
    final bgPaint = Paint()..color = Colors.black.withAlpha(166);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Calculate cutout rect around highlighted cells
    final minRow = min(from.row as int, to.row as int);
    final maxRow = max(from.row as int, to.row as int);
    final minCol = min(from.col as int, to.col as int);
    final maxCol = max(from.col as int, to.col as int);

    final padding = 6.0 + pulseValue * 4;
    final cutout = Rect.fromLTWH(
      boardOffset.dx + minCol * cellSize - padding,
      boardOffset.dy + minRow * cellSize - padding,
      (maxCol - minCol + 1) * cellSize + padding * 2,
      (maxRow - minRow + 1) * cellSize + padding * 2,
    );

    // Clear cutout area
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, bgPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(12)),
      clearPaint,
    );
    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + pulseValue * 1.5
      ..color = TT.goldShine.withAlpha(160 + (95 * pulseValue).toInt());
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter old) =>
      old.pulseValue != pulseValue;
}

// ---------------------------------------------------------------------------
// Message Box
// ---------------------------------------------------------------------------

class _MessageBox extends StatelessWidget {
  final TutorialStep step;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const _MessageBox({
    required this.step,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return IslandPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.title,
            style: TT.titleLarge.copyWith(color: TT.goldDeep, fontSize: 20, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            step.message,
            textAlign: TextAlign.center,
            style: TT.bodyMedium.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IslandButton(
                  text: 'Atla',
                  color: IslandButtonColor.bamboo,
                  size: IslandButtonSize.medium,
                  fullWidth: true,
                  onPressed: onSkip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: IslandButton(
                  text: step.requiresAction ? 'Kaydır...' : 'Devam',
                  icon: step.requiresAction ? Icons.swipe_rounded : Icons.arrow_forward_rounded,
                  color: step.requiresAction ? IslandButtonColor.bamboo : IslandButtonColor.coral,
                  size: IslandButtonSize.medium,
                  fullWidth: true,
                  onPressed: step.requiresAction ? null : onContinue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
