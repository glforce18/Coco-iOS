import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';

/// One-shot upsell modal — shown ~every 10 completed levels (24h cooldown)
/// to non-paying users. Surfaces the three premium options in a single
/// hand-off and routes to the shop when the player taps any of them.
///
/// Trigger: see [PlayerProgressNotifier.shouldShowPremiumPromo]; the
/// caller is expected to invoke [PlayerProgressNotifier.markPremiumPromoShown]
/// after this modal opens.
Future<void> showPremiumPromoModal(BuildContext context, WidgetRef ref) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(190),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (_, anim, __, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (_, __, ___) => Center(child: _PremiumPromoBody(ref: ref)),
  );
}

class _PremiumPromoBody extends StatelessWidget {
  // ignore: unused_element_parameter
  final WidgetRef ref;
  const _PremiumPromoBody({required this.ref});

  void _close(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();

  void _goShop(BuildContext context) {
    _close(context);
    context.push('/shop');
  }

  /// Routes to the shop with the relevant card highlighted. Direct buy
  /// from a modal is fragile (in_app_purchase needs the parent route to
  /// stay alive), so we just navigate.
  void _gotoProduct(BuildContext context, String productId) {
    _close(context);
    context.push('/shop');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Premium treasure-themed background — leaks behind the
                // panel through translucent layers so the modal feels
                // luxurious instead of flat cream.
                Positioned.fill(
                  child: Image.asset(
                    'assets/tropical/backgrounds/ui_premium_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: TT.driftWoodDark),
                  ),
                ),
                // Soft dark overlay so foreground text reads.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(60),
                          Colors.black.withAlpha(160),
                        ],
                      ),
                    ),
                  ),
                ),
                IslandPanel(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sparkle header with diamond icon.
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
                      BoxShadow(color: TT.gold.withAlpha(180), blurRadius: 22, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 8),
                // 3D gold-trim coral ribbon banner over the title.
                SizedBox(
                  width: 280,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/tropical/ui/ui_ribbon_banner.png',
                        width: 280,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: [TT.coral, TT.coralDark]),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFFFE89C), Color(0xFFE8A317)],
                          ).createShader(rect),
                          child: Text(
                            'COCO PREMIUM',
                            style: TT.titleLarge.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black.withAlpha(220), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reklamsız + bonus altın + ekstra güçlendirici.\nSeçimini yap, kaldığın yerden devam et.',
                  textAlign: TextAlign.center,
                  style: TT.bodySmall.copyWith(color: TT.driftWoodDark.withAlpha(220)),
                ),
                const SizedBox(height: 16),
                _PromoTile(
                  icon: Icons.block_rounded,
                  iconColor: TT.coral,
                  title: 'Reklamları Kaldır',
                  subtitle: 'Tek seferlik. Tüm reklamlar kapanır.',
                  badge: 'EN POPÜLER',
                  onTap: () => _gotoProduct(context, BillingManager.removeAdsId),
                ),
                const SizedBox(height: 8),
                _PromoTile(
                  icon: Icons.card_giftcard_rounded,
                  iconColor: TT.palm,
                  title: 'Başlangıç Paketi',
                  subtitle: '5 Çekiç + 5 Renk + 5 Hamle + 1000 altın',
                  badge: 'BÜYÜK İNDİRİM',
                  onTap: () => _gotoProduct(context, BillingManager.starterBundleId),
                ),
                const SizedBox(height: 8),
                _PromoTile(
                  icon: Icons.diamond_rounded,
                  iconColor: TT.lagoon,
                  title: 'VIP Üyelik',
                  subtitle: 'Sınırsız can + 2x altın + reklamsız',
                  badge: 'AYLIK',
                  onTap: () => _gotoProduct(context, BillingManager.vipMonthlyId),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: IslandButton(
                        text: 'Mağaza',
                        icon: Icons.shopping_bag_rounded,
                        color: IslandButtonColor.lagoon,
                        size: IslandButtonSize.medium,
                        onPressed: () => _goShop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IslandButton(
                        text: 'Kapat',
                        icon: Icons.close_rounded,
                        color: IslandButtonColor.coral,
                        size: IslandButtonSize.medium,
                        onPressed: () => _close(context),
                      ),
                    ),
                  ],
                ),
              ],
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

class _PromoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _PromoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: TT.sandLight.withAlpha(220),
          border: Border.all(color: TT.bamboo, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(iconColor, Colors.white, 0.2)!, iconColor],
                ),
                boxShadow: [
                  BoxShadow(color: iconColor.withAlpha(140), blurRadius: 8, spreadRadius: -1),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + badge wrap — auto-line-breaks if title is wide
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      Text(
                        title,
                        style: TT.titleMedium.copyWith(
                          color: TT.driftWoodDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [TT.coral, TT.coralDark],
                          ),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TT.bodySmall.copyWith(
                      color: TT.driftWoodDark.withAlpha(180),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: TT.driftWoodDark, size: 22),
          ],
        ),
      ),
    );
  }
}
