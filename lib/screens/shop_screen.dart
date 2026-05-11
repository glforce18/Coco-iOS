import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/coco_banner_ad.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_chip.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _billing = BillingManager.instance;

  Future<void> _buyBooster(BoosterType type) async {
    final p = ref.read(playerProgressProvider);
    if (p.coins < type.cost) {
      _showSnack('Yeterli altının yok!', TT.coral);
      return;
    }
    await ref.read(playerProgressProvider.notifier).buyBooster(type);
    if (mounted) _showSnack('${type.displayName} satın alındı!', TT.palm);
  }

  Future<void> _buyIAP(String productId) async {
    final product = _billing.productById(productId);
    if (product == null) return;
    await _billing.buyProduct(product);
  }

  Future<void> _restore() async {
    await _billing.restorePurchases();
    if (mounted) _showSnack('Satın alımlar geri yüklendi', TT.lagoon);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: color.withAlpha(220),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    return IslandScaffold(
      backgroundAsset: TA.shopBg,
      overlayOpacity: 0.42,
      bottomBar: IslandBottomNav(
        activeIndex: 1,
        tabs: [
          IslandNavTab(icon: Icons.home_rounded, label: 'Ana Sayfa', onTap: () => context.go('/menu')),
          IslandNavTab(icon: Icons.shopping_bag_rounded, label: 'Mağaza', onTap: () {}),
          IslandNavTab(
            icon: Icons.casino_rounded,
            label: 'Çark',
            onTap: () => context.push('/spin'),
            isCenter: true,
          ),
          IslandNavTab(icon: Icons.egg_rounded, label: 'Yuva', onTap: () => context.push('/nest')),
          IslandNavTab(icon: Icons.person_rounded, label: 'Profil', onTap: () => context.push('/profile')),
        ],
      ),
      child: Column(
        children: [
          IslandTopBar(
            stars: progress.totalStars,
            coins: progress.coins,
            hearts: progress.lives,
            leading: IslandCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.go('/map'),
            ),
            trailing: [
              IslandCircleButton(
                icon: Icons.restore_rounded,
                onTap: _restore,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: TT.coralButtonGradient,
                border: Border.all(color: TT.goldShine, width: 2),
                boxShadow: [
                  BoxShadow(color: TT.coral.withAlpha(160), blurRadius: 16, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer_rounded, color: TT.goldShine, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'HAZİNE MAĞAZASI',
                    style: TT.titleLarge.copyWith(
                      color: TT.sandLight,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              children: [
                // ─── Boosters ───
                _SectionHeader(icon: Icons.bolt_rounded, title: 'Güçlendiriciler'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _BoosterCard(
                      type: BoosterType.hammer,
                      asset: TA.boosterHammer,
                      count: progress.hammerCount,
                      coins: progress.coins,
                      onBuy: () => _buyBooster(BoosterType.hammer),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _BoosterCard(
                      type: BoosterType.colorBlast,
                      asset: TA.boosterColorBlast,
                      count: progress.colorBlastCount,
                      coins: progress.coins,
                      onBuy: () => _buyBooster(BoosterType.colorBlast),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _BoosterCard(
                      type: BoosterType.extraMoves,
                      asset: TA.boosterExtraMoves,
                      count: progress.extraMovesCount,
                      coins: progress.coins,
                      onBuy: () => _buyBooster(BoosterType.extraMoves),
                    )),
                  ],
                ),
                const SizedBox(height: 18),

                // ─── Coin Packs ───
                _SectionHeader(icon: Icons.monetization_on_rounded, title: 'Altın Paketleri'),
                const SizedBox(height: 8),
                _CoinCard(
                  productId: BillingManager.coinsSmallId,
                  asset: TA.shopCoins500,
                  amount: '500',
                  subtitle: 'Küçük Sandık',
                  onBuy: () => _buyIAP(BillingManager.coinsSmallId),
                ),
                const SizedBox(height: 8),
                _CoinCard(
                  productId: BillingManager.coinsMediumId,
                  asset: TA.shopCoins1500,
                  amount: '1.500',
                  subtitle: 'Orta Sandık',
                  badge: 'Popüler',
                  onBuy: () => _buyIAP(BillingManager.coinsMediumId),
                ),
                const SizedBox(height: 8),
                _CoinCard(
                  productId: BillingManager.coinsLargeId,
                  asset: TA.shopCoins5000,
                  amount: '5.000',
                  subtitle: 'Hazine Sandığı',
                  badge: 'En İyi Değer',
                  onBuy: () => _buyIAP(BillingManager.coinsLargeId),
                ),
                const SizedBox(height: 18),

                // ─── Specials ───
                _SectionHeader(icon: Icons.workspace_premium_rounded, title: 'Özel Teklifler'),
                const SizedBox(height: 8),
                // Remove Ads — top of the specials section so it's the
                // first thing players see when ads start to feel intrusive.
                if (!progress.removeAdsPurchased) ...[
                  _PremiumCard(
                    productId: BillingManager.removeAdsId,
                    asset: TA.shopRemoveAds,
                    title: 'Reklamları Kaldır',
                    desc: 'Tek seferlik. Tüm banner + ara reklamlar kapanır. Ödüllü reklam (bonus için) seçimlik kalır.',
                    isPurchased: progress.removeAdsPurchased,
                    onBuy: () => _buyIAP(BillingManager.removeAdsId),
                  ),
                  const SizedBox(height: 8),
                ],
                _PremiumCard(
                  productId: BillingManager.starterBundleId,
                  asset: TA.shopStarter,
                  title: 'Başlangıç Paketi',
                  desc: 'Tüm güçlendiricilerden 5 + 1000 altın',
                  isPurchased: false,
                  onBuy: () => _buyIAP(BillingManager.starterBundleId),
                ),
                if (progress.removeAdsPurchased) ...[
                  const SizedBox(height: 8),
                  _PremiumCard(
                    productId: BillingManager.removeAdsId,
                    asset: TA.shopRemoveAds,
                    title: 'Reklamları Kaldır',
                    desc: 'Satın alındı — teşekkürler!',
                    isPurchased: true,
                    onBuy: () {},
                  ),
                ],
                const SizedBox(height: 8),
                _PremiumCard(
                  productId: BillingManager.vipMonthlyId,
                  asset: TA.shopVip,
                  title: 'VIP Üyelik',
                  desc: 'Sınırsız can + 2x altın + reklamsız (aylık otomatik yenilenir)',
                  isPurchased: progress.vipActive,
                  isVip: true,
                  onBuy: () => _buyIAP(BillingManager.vipMonthlyId),
                ),
                const SizedBox(height: 10),
                // Apple Guideline 3.1.2 — subscription disclosure + links
                _ShopSubscriptionFooter(),
                const SizedBox(height: 16),
                const Center(child: CocoBannerAd()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.driftWood, TT.driftWoodDark],
        ),
        border: Border.all(color: TT.gold, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: TT.gold.withAlpha(80), blurRadius: 14, spreadRadius: -1),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: TT.goldShine, size: 22, shadows: [
            Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 1)),
          ]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TT.titleMedium.copyWith(
              color: TT.sandLight,
              shadows: [
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booster card ─────────────────────────────────────────────────────────
class _BoosterCard extends StatelessWidget {
  final BoosterType type;
  final String asset;
  final int count;
  final int coins;
  final VoidCallback onBuy;

  const _BoosterCard({
    required this.type,
    required this.asset,
    required this.count,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= type.cost;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
          ),
        ),
        child: Column(
          children: [
            // count badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: TT.coral,
                  border: Border.all(color: TT.goldShine, width: 1.2),
                ),
                child: Text(
                  'x$count',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            // image
            SizedBox(
              height: 64,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: TT.gold, size: 48),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TT.bodySmall.copyWith(fontWeight: FontWeight.w900, color: TT.driftWoodDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            IslandButton(
              text: '${type.cost}',
              icon: Icons.monetization_on_rounded,
              color: canAfford ? IslandButtonColor.gold : IslandButtonColor.bamboo,
              size: IslandButtonSize.small,
              fullWidth: true,
              onPressed: canAfford ? onBuy : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coin card ────────────────────────────────────────────────────────────
class _CoinCard extends StatelessWidget {
  final String productId;
  final String asset;
  final String amount;
  final String subtitle;
  final String? badge;
  final VoidCallback onBuy;

  const _CoinCard({
    required this.productId,
    required this.asset,
    required this.amount,
    required this.subtitle,
    this.badge,
    required this.onBuy,
  });

  static const Map<String, String> _fallbackPrices = {
    BillingManager.coinsSmallId: '\$0.99',
    BillingManager.coinsMediumId: '\$2.99',
    BillingManager.coinsLargeId: '\$9.99',
  };

  @override
  Widget build(BuildContext context) {
    final billing = BillingManager.instance;
    final ProductDetails? product = billing.productById(productId);
    final price = product?.price ?? _fallbackPrices[productId] ?? '—';
    return IslandSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.savings_rounded, color: TT.gold, size: 56),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      amount,
                      style: TT.titleLarge.copyWith(color: TT.goldDeep, fontSize: 22),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.monetization_on_rounded, color: TT.gold, size: 22),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      IslandRibbon(text: badge!),
                    ],
                  ],
                ),
                Text(subtitle, style: TT.bodySmall),
              ],
            ),
          ),
          IslandButton(
            text: price,
            color: IslandButtonColor.palm,
            size: IslandButtonSize.small,
            onPressed: product == null ? null : onBuy,
          ),
        ],
      ),
    );
  }
}

// ─── Premium card ────────────────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  final String productId;
  final String asset;
  final String title;
  final String desc;
  final bool isPurchased;
  final bool isVip;
  final VoidCallback onBuy;

  const _PremiumCard({
    required this.productId,
    required this.asset,
    required this.title,
    required this.desc,
    required this.isPurchased,
    this.isVip = false,
    required this.onBuy,
  });

  static const Map<String, String> _fallbackPrices = {
    BillingManager.removeAdsId: '\$3.99',
    BillingManager.starterBundleId: '\$4.99',
    BillingManager.vipMonthlyId: '\$4.99 / ay',
  };

  @override
  Widget build(BuildContext context) {
    final billing = BillingManager.instance;
    final ProductDetails? product = billing.productById(productId);
    final price = product?.price ?? _fallbackPrices[productId] ?? '—';
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isVip
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep, TT.gold],
                stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.gold, TT.goldDeep],
              ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 12, offset: const Offset(0, 4)),
          if (isVip)
            BoxShadow(color: TT.gold.withAlpha(180), blurRadius: 22, spreadRadius: 2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isVip
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF7D6), Color(0xFFFFE8A0)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
                ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  isVip ? Icons.workspace_premium_rounded : Icons.card_giftcard_rounded,
                  color: TT.gold,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TT.titleMedium.copyWith(
                            color: TT.goldDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVip) ...[
                        const SizedBox(width: 4),
                        const IslandChip(
                          text: 'VIP',
                          icon: Icons.diamond_rounded,
                          fontSize: 9,
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TT.bodySmall.copyWith(fontSize: 11, height: 1.2),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            isPurchased
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: TT.palmButtonGradient,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Aktif',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                  )
                : IslandButton(
                    text: price,
                    color: isVip ? IslandButtonColor.gold : IslandButtonColor.coral,
                    size: IslandButtonSize.small,
                    onPressed: product == null ? null : onBuy,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Apple Guideline 3.1.2 footer for the Shop screen — subscription terms +
/// ToS + Privacy Policy links shown beneath the VIP Üyelik card.
class _ShopSubscriptionFooter extends StatelessWidget {
  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: TT.sandLight.withAlpha(220),
        border: Border.all(color: TT.bamboo.withAlpha(180), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIP Üyelik — Aylık abonelik. Otomatik olarak yenilenir; mevcut dönem bitmeden 24 saat önce iptal etmezsen aynı tutar tahsil edilir. iCloud → Apple ID → Abonelikler menüsünden istediğin zaman iptal edebilirsin.',
            style: TT.bodySmall.copyWith(
              color: TT.driftWoodDark,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _open('https://dosto.tr/coco/kullanim-sartlari'),
                child: Text(
                  'Kullanım Şartları',
                  style: TT.bodySmall.copyWith(
                    color: TT.lagoonDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text('  ·  ', style: TT.bodySmall.copyWith(color: TT.driftWoodDark, fontSize: 11)),
              GestureDetector(
                onTap: () => _open('https://dosto.tr/coco/gizlilik'),
                child: Text(
                  'Gizlilik Politikası',
                  style: TT.bodySmall.copyWith(
                    color: TT.lagoonDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
