import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patpat_game/ads/ad_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

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
  late final AnimationController _heartbeatCtrl;
  late final Animation<double> _heartbeatAnim;
  Timer? _timer;
  String _timeText = '--:--';

  @override
  void initState() {
    super.initState();
    _heartbeatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _heartbeatAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _heartbeatCtrl, curve: Curves.easeInOut),
    );
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
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
    final m = remaining ~/ 60000;
    final s = (remaining % 60000) ~/ 1000;
    setState(() {
      _timeText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeatCtrl.dispose();
    super.dispose();
  }

  Future<void> _onWatchAd() async {
    final shown = await AdManager.instance.showRewardedAd(onRewarded: widget.onLifeGranted);
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
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: IslandPanel(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MascotView(pose: MascotPose.sleeping, height: 100, bobbing: false),
                    const SizedBox(height: 6),
                    Text(
                      'CANIN KALMADI!',
                      style: TT.titleLarge.copyWith(color: TT.coralDark, fontSize: 22, letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _heartbeatAnim,
                      builder: (_, child) => Transform.scale(scale: _heartbeatAnim.value, child: child),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 28,
                            color: TT.coral.withAlpha(180),
                            shadows: [
                              Shadow(color: TT.coralDark.withAlpha(160), blurRadius: 6),
                            ],
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: TT.driftPanelGradient,
                        border: Border.all(color: TT.gold, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded, color: TT.goldShine, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sonraki can: $_timeText',
                            style: const TextStyle(
                              color: TT.sandLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!widget.removeAdsPurchased) ...[
                      IslandButton(
                        text: 'Reklam İzle +1 Can',
                        icon: Icons.play_circle_filled_rounded,
                        color: IslandButtonColor.palm,
                        size: IslandButtonSize.medium,
                        fullWidth: true,
                        onPressed: _onWatchAd,
                      ),
                      const SizedBox(height: 8),
                    ],
                    IslandButton(
                      text: 'Kapat',
                      color: IslandButtonColor.bamboo,
                      size: IslandButtonSize.small,
                      fullWidth: true,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
