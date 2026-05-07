import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/shared/gold_button.dart';
import 'package:patpat_game/widgets/shared/gold_panel.dart';

/// Full-screen popup shown when the player has 0 lives and tries to play.
class NoLivesPopup extends StatefulWidget {
  final int lastLifeLostTime;
  final bool vipActive;
  final bool removeAdsPurchased;
  final VoidCallback onLifeGranted;
  final VoidCallback onClose;

  const NoLivesPopup({
    super.key,
    required this.lastLifeLostTime,
    required this.vipActive,
    required this.removeAdsPurchased,
    required this.onLifeGranted,
    required this.onClose,
  });

  @override
  State<NoLivesPopup> createState() => _NoLivesPopupState();
}

class _NoLivesPopupState extends State<NoLivesPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartbeatController;
  late final Animation<double> _heartbeatAnimation;
  Timer? _countdownTimer;
  String _timeText = '';

  @override
  void initState() {
    super.initState();

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _heartbeatAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    if (widget.lastLifeLostTime == 0) {
      setState(() => _timeText = '--:--');
      return;
    }
    final regenMs = widget.vipActive ? 20 * 60 * 1000 : 30 * 60 * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - widget.lastLifeLostTime;
    final remaining = regenMs - (elapsed % regenMs);
    final minutes = (remaining ~/ 60000);
    final seconds = ((remaining % 60000) ~/ 1000);
    setState(() {
      _timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartbeatController.dispose();
    super.dispose();
  }

  void _onWatchAd() async {
    final shown = await AdManager.instance.showRewardedAd(
      onRewarded: widget.onLifeGranted,
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam hazır değil, biraz sonra tekrar dene.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: GoldPanel(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'CANIN KALMADI!',
                    style: TextStyle(
                      color: GameColors.cherryRed,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(220),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        const Shadow(
                          color: GameColors.cherryRedDark,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hearts row with heartbeat animation
                  AnimatedBuilder(
                    animation: _heartbeatAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartbeatAnimation.value,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 32,
                            color: GameColors.cherryRed.withAlpha(160),
                            shadows: [
                              Shadow(
                                color: GameColors.cherryRedDark.withAlpha(160),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: GameColors.panelPurpleDark.withAlpha(180),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: GameColors.goldFrameMid.withAlpha(160),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: GameColors.goldFrameBright,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sonraki can: $_timeText',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(180),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Watch ad button (only if ads not removed)
                  if (!widget.removeAdsPurchased) ...[
                    GoldButton(
                      text: 'Reklam İzle +1 Can',
                      color: GoldButtonColor.green,
                      size: GoldButtonSize.medium,
                      width: double.infinity,
                      icon: Icons.play_circle_filled_rounded,
                      onPressed: _onWatchAd,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Close button
                  GoldButton(
                    text: 'Kapat',
                    color: GoldButtonColor.red,
                    size: GoldButtonSize.small,
                    width: double.infinity,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
