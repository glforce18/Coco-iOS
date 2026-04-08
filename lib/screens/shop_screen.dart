import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/billing/billing_manager.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ShopScreen — rich purchase UI with booster cards + IAP packages
// ═══════════════════════════════════════════════════════════════════════════

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  final _billing = BillingManager.instance;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Buy booster with coins ───────────────────────────────────────────
  Future<void> _buyBooster(BoosterType type) async {
    final progress = ref.read(playerProgressProvider);
    if (progress.coins < type.cost) {
      _showSnackBar('Yeterli altinin yok!', GameColors.hotPink);
      return;
    }
    SoundManager.instance.play(SoundType.match);
    HapticManager.instance.tapMatch();
    await ref.read(playerProgressProvider.notifier).buyBooster(type);
    if (mounted) {
      _showSnackBar('${type.displayName} satin alindi!', GameColors.neonGreen);
    }
  }

  // ── Buy IAP product ──────────────────────────────────────────────────
  Future<void> _buyIAP(String productId) async {
    final product = _billing.productById(productId);
    if (product == null) return;
    SoundManager.instance.play(SoundType.buttonClick);
    HapticManager.instance.tapMatch();
    await _billing.buyProduct(product);
  }

  // ── Restore purchases ────────────────────────────────────────────────
  Future<void> _restore() async {
    SoundManager.instance.play(SoundType.buttonClick);
    HapticManager.instance.tapLight();
    await _billing.restorePurchases();
    if (mounted) {
      _showSnackBar('Satin alimlar geri yuklendi', GameColors.neonCyan);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: color.withAlpha(200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Deep purple gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0660),
                  Color(0xFF0D0235),
                  Color(0xFF050120),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Animated floating particles ──
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _SparkleParticlePainter(
                progress: _particleController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                _ShopHeader(
                  coins: progress.coins,
                  onBack: () {
                    SoundManager.instance.play(SoundType.buttonClick);
                    HapticManager.instance.tapLight();
                    context.go('/map');
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Booster section ──
                        _SectionHeader(
                          title: 'Guclendiriciler',
                          icon: Icons.bolt,
                          iconColor: GameColors.goldFrame,
                        ),
                        const SizedBox(height: 10),
                        _BoosterCard(
                          type: BoosterType.hammer,
                          icon: Icons.gavel,
                          iconColor: GameColors.orange,
                          glowColor: GameColors.orangeDark,
                          description: 'Tek bir jelliyi yok et',
                          count: progress.hammerCount,
                          coins: progress.coins,
                          pulseAnim: _pulseAnim,
                          onBuy: () => _buyBooster(BoosterType.hammer),
                        ),
                        const SizedBox(height: 10),
                        _BoosterCard(
                          type: BoosterType.colorBlast,
                          icon: Icons.auto_awesome,
                          iconColor: GameColors.neonPurple,
                          glowColor: GameColors.purpleDark,
                          description: 'Ayni renk jellileri patlat',
                          count: progress.colorBlastCount,
                          coins: progress.coins,
                          pulseAnim: _pulseAnim,
                          onBuy: () => _buyBooster(BoosterType.colorBlast),
                        ),
                        const SizedBox(height: 10),
                        _BoosterCard(
                          type: BoosterType.extraMoves,
                          icon: Icons.add_circle_outline,
                          iconColor: GameColors.blueLight,
                          glowColor: GameColors.blueDark,
                          description: '+3 ekstra hamle kazan',
                          count: progress.extraMovesCount,
                          coins: progress.coins,
                          pulseAnim: _pulseAnim,
                          onBuy: () => _buyBooster(BoosterType.extraMoves),
                        ),

                        const SizedBox(height: 28),

                        // ── Coin Packs section ──
                        _SectionHeader(
                          title: 'Altin Paketleri',
                          icon: Icons.monetization_on,
                          iconColor: GameColors.goldFrame,
                        ),
                        const SizedBox(height: 10),

                        if (!_billing.isAvailable) ...[
                          _StoreUnavailableBanner(),
                          const SizedBox(height: 10),
                        ],

                        _CoinPackCard(
                          amount: 500,
                          productId: BillingManager.coinsSmallId,
                          gradient: const [Color(0xFF1A5C2E), Color(0xFF0D3018)],
                          borderColor: GameColors.greenLight,
                          billing: _billing,
                          onBuy: () => _buyIAP(BillingManager.coinsSmallId),
                        ),
                        const SizedBox(height: 10),
                        _CoinPackCard(
                          amount: 1500,
                          productId: BillingManager.coinsMediumId,
                          gradient: const [Color(0xFF1A3C6E), Color(0xFF0D1E40)],
                          borderColor: GameColors.blueLight,
                          billing: _billing,
                          badgeText: 'Populer',
                          onBuy: () => _buyIAP(BillingManager.coinsMediumId),
                        ),
                        const SizedBox(height: 10),
                        _CoinPackCard(
                          amount: 5000,
                          productId: BillingManager.coinsLargeId,
                          gradient: const [Color(0xFF5C3A1A), Color(0xFF3D2510)],
                          borderColor: GameColors.goldFrame,
                          billing: _billing,
                          badgeText: 'En Degerli',
                          onBuy: () => _buyIAP(BillingManager.coinsLargeId),
                        ),

                        const SizedBox(height: 28),

                        // ── Special offers section ──
                        _SectionHeader(
                          title: 'Ozel Teklifler',
                          icon: Icons.star,
                          iconColor: GameColors.hotPink,
                        ),
                        const SizedBox(height: 10),

                        // Remove Ads
                        _SpecialOfferCard(
                          title: 'Reklam Kaldirma',
                          description: 'Oyundaki tum reklamlari kaldir',
                          icon: Icons.block,
                          iconColor: GameColors.neonCyan,
                          gradient: const [Color(0xFF0D3A4A), Color(0xFF061E28)],
                          borderColor: GameColors.neonCyan,
                          productId: BillingManager.removeAdsId,
                          billing: _billing,
                          isPurchased: progress.removeAdsPurchased,
                          onBuy: () => _buyIAP(BillingManager.removeAdsId),
                        ),
                        const SizedBox(height: 10),

                        // Starter Bundle
                        _SpecialOfferCard(
                          title: 'Baslangic Paketi',
                          description: '500 altin + 5 can + ozel avantajlar',
                          icon: Icons.card_giftcard,
                          iconColor: GameColors.goldFrame,
                          gradient: const [Color(0xFF4A3A0D), Color(0xFF2A2008)],
                          borderColor: GameColors.goldFrame,
                          productId: BillingManager.starterBundleId,
                          billing: _billing,
                          isPurchased: progress.starterBundleClaimed,
                          onBuy: () => _buyIAP(BillingManager.starterBundleId),
                        ),
                        const SizedBox(height: 10),

                        // VIP Monthly
                        _SpecialOfferCard(
                          title: 'VIP Uyelik',
                          description: 'Aylik VIP avantajlari ve ozel icerik',
                          icon: Icons.workspace_premium,
                          iconColor: GameColors.hotPink,
                          gradient: const [Color(0xFF4A0D30), Color(0xFF2A0618)],
                          borderColor: GameColors.hotPink,
                          productId: BillingManager.vipMonthlyId,
                          billing: _billing,
                          isPurchased: progress.vipActive,
                          onBuy: () => _buyIAP(BillingManager.vipMonthlyId),
                        ),

                        const SizedBox(height: 24),

                        // ── Restore button ──
                        Center(
                          child: GestureDetector(
                            onTap: _restore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withAlpha(30)),
                              ),
                              child: const Text(
                                'Satin Alimlari Geri Yukle',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shop Header
// ═══════════════════════════════════════════════════════════════════════════

class _ShopHeader extends StatelessWidget {
  final int coins;
  final VoidCallback onBack;

  const _ShopHeader({required this.coins, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameColors.goldFrame.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldDark.withAlpha(30),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [GameColors.goldLight, GameColors.goldFrame],
              ).createShader(bounds),
              child: const Text(
                'MAGAZA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),

            const Spacer(),

            // Coin display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GameColors.goldDark.withAlpha(120),
                    GameColors.goldDark.withAlpha(60),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: GameColors.goldFrame.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: GameColors.goldDark.withAlpha(40),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\uD83E\uDE99',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GameColors.goldLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [iconColor.withAlpha(180), iconColor.withAlpha(40)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: iconColor,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: iconColor.withAlpha(80),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withAlpha(80),
                  iconColor.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Booster Card — purchase with coins
// ═══════════════════════════════════════════════════════════════════════════

class _BoosterCard extends StatelessWidget {
  final BoosterType type;
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String description;
  final int count;
  final int coins;
  final Animation<double> pulseAnim;
  final VoidCallback onBuy;

  const _BoosterCard({
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.description,
    required this.count,
    required this.coins,
    required this.pulseAnim,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= type.cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameColors.bgMid.withAlpha(220),
            GameColors.bgDeep.withAlpha(240),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha(30),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle with glow
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (context, child) {
              final pulse = pulseAnim.value;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      iconColor.withAlpha(180),
                      iconColor.withAlpha(60),
                      glowColor.withAlpha(20),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: iconColor.withAlpha(160),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withAlpha((40 + 30 * pulse).toInt()),
                      blurRadius: 16 + 4 * pulse,
                      spreadRadius: 1 + pulse,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              );
            },
          ),
          const SizedBox(width: 14),

          // Name + description + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(140),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mevcut: $count',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(100),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Buy button
          GestureDetector(
            onTap: canAfford ? onBuy : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: canAfford
                      ? [
                          const Color(0xFF2ECC40),
                          const Color(0xFF1A8028),
                        ]
                      : [
                          Colors.grey.shade700,
                          Colors.grey.shade800,
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canAfford
                      ? GameColors.neonGreen.withAlpha(120)
                      : Colors.grey.withAlpha(40),
                ),
                boxShadow: canAfford
                    ? [
                        BoxShadow(
                          color: GameColors.neonGreen.withAlpha(40),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\uD83E\uDE99',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${type.cost}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: canAfford ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Coin Pack Card — IAP
// ═══════════════════════════════════════════════════════════════════════════

class _CoinPackCard extends StatelessWidget {
  final int amount;
  final String productId;
  final List<Color> gradient;
  final Color borderColor;
  final BillingManager billing;
  final String? badgeText;
  final VoidCallback onBuy;

  const _CoinPackCard({
    required this.amount,
    required this.productId,
    required this.gradient,
    required this.borderColor,
    required this.billing,
    this.badgeText,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final product = billing.productById(productId);
    final priceText = product?.price ?? '--';
    final available = billing.isAvailable && product != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: available ? onBuy : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor.withAlpha(80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withAlpha(20),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Coin stack icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        GameColors.goldFrame,
                        GameColors.goldDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.goldFrame.withAlpha(60),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '\uD83E\uDE99',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$amount Altin',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GameColors.goldLight,
                        ),
                      ),
                      if (!available)
                        Text(
                          'Magaza yuklenemedi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(80),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: available
                          ? [const Color(0xFF2ECC40), const Color(0xFF1A8028)]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: available
                          ? GameColors.neonGreen.withAlpha(100)
                          : Colors.grey.withAlpha(30),
                    ),
                  ),
                  child: Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: available ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Badge
        if (badgeText != null)
          Positioned(
            top: -6,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [GameColors.hotPink, GameColors.pinkDark],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: GameColors.hotPink.withAlpha(80),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Special Offer Card — remove ads, starter bundle, VIP
// ═══════════════════════════════════════════════════════════════════════════

class _SpecialOfferCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final Color borderColor;
  final String productId;
  final BillingManager billing;
  final bool isPurchased;
  final VoidCallback onBuy;

  const _SpecialOfferCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.borderColor,
    required this.productId,
    required this.billing,
    required this.isPurchased,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final product = billing.productById(productId);
    final priceText = product?.price ?? '--';
    final available = billing.isAvailable && product != null && !isPurchased;

    return GestureDetector(
      onTap: available ? onBuy : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPurchased
                ? GameColors.neonGreen.withAlpha(120)
                : borderColor.withAlpha(80),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPurchased ? GameColors.neonGreen : borderColor)
                  .withAlpha(20),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    iconColor.withAlpha(160),
                    iconColor.withAlpha(40),
                  ],
                ),
                border: Border.all(color: iconColor.withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withAlpha(40),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: isPurchased
                  ? const Icon(Icons.check, color: GameColors.neonGreen, size: 28)
                  : Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPurchased ? GameColors.neonGreen : iconColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPurchased ? 'Aktif' : description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPurchased
                          ? GameColors.neonGreen.withAlpha(160)
                          : Colors.white.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),

            // Price / purchased badge
            if (isPurchased)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GameColors.neonGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: GameColors.neonGreen.withAlpha(80)),
                ),
                child: const Text(
                  'Alindi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GameColors.neonGreen,
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: available
                        ? [const Color(0xFF2ECC40), const Color(0xFF1A8028)]
                        : [Colors.grey.shade700, Colors.grey.shade800],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: available
                        ? GameColors.neonGreen.withAlpha(100)
                        : Colors.grey.withAlpha(30),
                  ),
                ),
                child: Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: available ? Colors.white : Colors.white38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Store Unavailable Banner
// ═══════════════════════════════════════════════════════════════════════════

class _StoreUnavailableBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.orangeDark.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.orange.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: GameColors.orange.withAlpha(180), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Magaza yuklenemedi. Gercek alimlar cihazda denenir.',
              style: TextStyle(
                fontSize: 12,
                color: GameColors.orange.withAlpha(200),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sparkle Particle Painter — animated floating dots
// ═══════════════════════════════════════════════════════════════════════════

class _SparkleParticlePainter extends CustomPainter {
  final double progress;

  _SparkleParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // deterministic seed
    const count = 30;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();
      final radius = 1.0 + rng.nextDouble() * 2.5;

      // Oscillation
      final t = (progress * speed + phase) % 1.0;
      final yOffset = sin(t * 2 * pi) * 20;
      final xOffset = cos(t * 2 * pi * 0.7) * 10;

      // Alpha pulsation
      final alpha = (0.15 + 0.2 * sin(t * 2 * pi)).clamp(0.0, 1.0);

      paint.color = Color.lerp(
        GameColors.goldFrame,
        GameColors.neonCyan,
        rng.nextDouble(),
      )!
          .withAlpha((alpha * 255).toInt());

      canvas.drawCircle(
        Offset(baseX + xOffset, baseY + yOffset),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter old) => true;
}
