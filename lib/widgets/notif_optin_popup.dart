import 'package:flutter/material.dart';

import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';

/// One-shot opt-in popup shown the first time the player loses a life.
/// "Canların yenilenince haber verelim mi?" — declines are remembered so
/// we never re-show.
class NotifOptInPopup extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const NotifOptInPopup({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: IslandPanel(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [TT.goldShine, TT.gold, TT.goldDeep],
                      ),
                      boxShadow: [
                        BoxShadow(color: TT.gold.withAlpha(140), blurRadius: 18, spreadRadius: 1),
                      ],
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Bildirim alalım mı?',
                    textAlign: TextAlign.center,
                    style: TT.titleLarge.copyWith(color: TT.driftWoodDark, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Canların dolduğunda, yumurtan çatlamak üzereyken ve günlük ödülün hazır olduğunda Coco sana haber versin. (09:00–21:00 arası)',
                    textAlign: TextAlign.center,
                    style: TT.bodyMedium.copyWith(color: TT.driftWoodDark.withAlpha(220)),
                  ),
                  const SizedBox(height: 20),
                  IslandButton(
                    text: 'Evet, haber ver',
                    icon: Icons.notifications_rounded,
                    color: IslandButtonColor.palm,
                    size: IslandButtonSize.large,
                    fullWidth: true,
                    onPressed: onAccept,
                  ),
                  const SizedBox(height: 8),
                  IslandButton(
                    text: 'Şimdi olmasın',
                    icon: Icons.notifications_off_rounded,
                    color: IslandButtonColor.coral,
                    size: IslandButtonSize.medium,
                    fullWidth: true,
                    onPressed: onDecline,
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
