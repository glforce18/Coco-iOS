import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/theme/game_colors.dart';

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
          content: Text('Reklam hazir degil, biraz sonra tekrar dene.'),
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
          child: Container(
            width: 310,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D0B80), Color(0xFF1A0660)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: GameColors.hotPink, width: 2),
              boxShadow: [
                BoxShadow(
                  color: GameColors.hotPink.withAlpha(60),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'CANIN KALMADI!',
                  style: TextStyle(
                    color: GameColors.hotPink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Color(0xFFC01050), blurRadius: 12),
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
                          color: GameColors.hotPink.withAlpha(120),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Timer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        color: GameColors.neonCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sonraki can: $_timeText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Watch ad button (only if ads not removed)
                if (!widget.removeAdsPurchased)
                  GestureDetector(
                    onTap: _onWatchAd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [GameColors.neonGreen, Color(0xFF1A7030)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.neonGreen.withAlpha(80),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\uD83D\uDCFA',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reklam Izle +1 \u2764\uFE0F',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!widget.removeAdsPurchased) const SizedBox(height: 12),

                // Close button
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: const Text(
                      'Kapat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
