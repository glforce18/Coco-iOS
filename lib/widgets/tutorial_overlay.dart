import 'package:flutter/material.dart';

import 'package:patpat_game/game/tutorial_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';

/// Compact, non-blocking on-boarding chip pinned to the top of the screen.
///
/// • Stays out of the board area so the player can swap birds freely.
/// • The panel itself is the only interactive area — board taps fall
///   through to the game.
/// • Tap anywhere on the panel → advance to the next step.
/// • Small "Atla" link skips the remaining steps.
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      _fadeCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onContinue,
                child: IslandPanel(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: TT.goldShine,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.step.title,
                              style: TT.titleSmall.copyWith(
                                color: TT.goldDeep,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.step.message,
                              style: TT.bodySmall.copyWith(
                                fontSize: 12,
                                height: 1.25,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IslandButton(
                        text: 'Tamam',
                        color: IslandButtonColor.coral,
                        size: IslandButtonSize.small,
                        onPressed: widget.onContinue,
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: const Size(28, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: TT.sandLight.withAlpha(180),
                        ),
                        onPressed: widget.onSkip,
                        child: const Text(
                          'Atla',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
