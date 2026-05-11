import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/providers/auth_provider.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/coco_banner_ad.dart';
import 'package:patpat_game/widgets/tropical/island_chip.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';
import 'package:patpat_game/widgets/tropical/tropical_frame.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);
    final auth = ref.watch(authProvider);

    return IslandScaffold(
      backgroundAsset: TA.profileBg,
      overlayOpacity: 0.36,
      bottomBar: IslandBottomNav(
        activeIndex: 4,
        tabs: [
          IslandNavTab(icon: Icons.home_rounded, label: 'Ana Sayfa', onTap: () => context.go('/menu')),
          IslandNavTab(icon: Icons.shopping_bag_rounded, label: 'Mağaza', onTap: () => context.push('/shop')),
          IslandNavTab(
            icon: Icons.casino_rounded,
            label: 'Çark',
            onTap: () => context.push('/spin'),
            isCenter: true,
          ),
          IslandNavTab(icon: Icons.egg_rounded, label: 'Yuva', onTap: () => context.push('/nest')),
          IslandNavTab(icon: Icons.person_rounded, label: 'Profil', onTap: () {}),
        ],
      ),
      child: Stack(
        children: [
          // Animated tropical frame — palm leaves sway + string lights pulse
          const Positioned.fill(child: TropicalFrame()),
          Column(
            children: [
              IslandTopBar(
                stars: progress.totalStars,
                coins: progress.coins,
                hearts: progress.lives,
                leading: IslandCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/map')),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  children: [
                    // ─── Hero: Avatar + Name side-by-side (matches reference) ───
                    IslandSurface(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gold-ringed circular avatar with crowned parrot
                          _AvatarRing(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.userName ?? 'Tropik Oyuncu',
                                  style: TT.titleLarge.copyWith(
                                    color: TT.goldDeep,
                                    fontSize: 22,
                                    height: 1.05,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                IslandChip(
                                  text: 'Bölüm ${progress.currentLevel}',
                                  icon: Icons.flag_rounded,
                                  bg: TT.coral,
                                  fontSize: 12,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Renkli kuşlarla dolu bu maceranın en iyisi sen ol!',
                                  style: TT.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: TT.driftWoodDark,
                                    height: 1.25,
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 14),

                // ─── Stats grid ───
                _StatGrid(
                  totalStars: progress.totalStars,
                  totalScore: progress.totalScore,
                  coins: progress.coins,
                  achievements: progress.achievements.length,
                  streak: progress.dailyRewardStreak,
                  perfect: progress.perfectLevelCount,
                ),
                const SizedBox(height: 14),

                // ─── Booster inventory ───
                _SectionHeader(icon: Icons.bolt_rounded, title: 'Güçlendiricilerim'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _BoosterTile(asset: TA.boosterHammer, label: 'Çekiç', count: progress.hammerCount)),
                    const SizedBox(width: 8),
                    Expanded(child: _BoosterTile(asset: TA.boosterColorBlast, label: 'Renk Patlatma', count: progress.colorBlastCount)),
                    const SizedBox(width: 8),
                    Expanded(child: _BoosterTile(asset: TA.boosterExtraMoves, label: '+3 Hamle', count: progress.extraMovesCount)),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── Yuva CTA — egg incubator ───
                // COCO PREMIUM CTA — moved here from main menu by user request
                Center(child: _CocoPremiumCta(onTap: () => context.push('/shop'))),
                const SizedBox(height: 12),
                IslandButton(
                  text: 'Yuva',
                  icon: Icons.egg_rounded,
                  color: IslandButtonColor.lagoon,
                  size: IslandButtonSize.large,
                  fullWidth: true,
                  onPressed: () => context.go('/nest'),
                ),
                const SizedBox(height: 10),
                IslandButton(
                  text: 'Başarımlar',
                  icon: Icons.emoji_events_rounded,
                  color: IslandButtonColor.gold,
                  size: IslandButtonSize.large,
                  fullWidth: true,
                  onPressed: () => context.push('/achievements'),
                ),
                const SizedBox(height: 10),
                IslandButton(
                  text: 'Bildirimler',
                  icon: Icons.notifications_active_rounded,
                  color: IslandButtonColor.coral,
                  size: IslandButtonSize.large,
                  fullWidth: true,
                  onPressed: () => context.push('/notifications-settings'),
                ),
                const SizedBox(height: 10),
                IslandButton(
                  text: 'Etkinlikler',
                  icon: Icons.celebration_rounded,
                  color: IslandButtonColor.bamboo,
                  size: IslandButtonSize.large,
                  fullWidth: true,
                  onPressed: () => context.push('/events'),
                ),
                const SizedBox(height: 16),
                const Center(child: CocoBannerAd()),
              ],
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

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
      ),
      child: Row(
        children: [
          Icon(icon, color: TT.goldShine, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TT.titleMedium.copyWith(color: TT.sandLight)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final int totalStars;
  final int totalScore;
  final int coins;
  final int achievements;
  final int streak;
  final int perfect;

  const _StatGrid({
    required this.totalStars,
    required this.totalScore,
    required this.coins,
    required this.achievements,
    required this.streak,
    required this.perfect,
  });

  @override
  Widget build(BuildContext context) {
    final stats = <(IconData, String, String, Color)>[
      (Icons.star_rounded, 'Yıldızlar', '$totalStars', TT.starFilled),
      (Icons.bar_chart_rounded, 'Toplam Skor', _fmt(totalScore), TT.coral),
      (Icons.monetization_on_rounded, 'Altın', _fmt(coins), TT.gold),
      (Icons.emoji_events_rounded, 'Başarımlar', '$achievements', TT.lagoon),
      (Icons.local_fire_department_rounded, 'Seri', '$streak', TT.coralDark),
      (Icons.diamond_rounded, '3 Yıldız', '$perfect', TT.palm),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: stats.map((s) {
        final (icon, label, value, color) = s;
        return _StatCard(icon: icon, label: label, value: value, color: color);
      }).toList(),
    );
  }

  String _fmt(int v) {
    if (v < 1000) return '$v';
    if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}K';
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withAlpha(220), color.withAlpha(120)],
                ),
                boxShadow: [
                  BoxShadow(color: color.withAlpha(180), blurRadius: 8, spreadRadius: -1),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(180), blurRadius: 3, offset: const Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: TT.titleSmall.copyWith(color: TT.goldDeep, fontSize: 16)),
            Text(
              label,
              style: TT.bodySmall.copyWith(fontSize: 10, color: TT.driftWoodDark),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoosterTile extends StatelessWidget {
  final String asset;
  final String label;
  final int count;
  const _BoosterTile({required this.asset, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: TT.gold, size: 40),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TT.bodySmall.copyWith(fontWeight: FontWeight.w900, color: TT.driftWoodDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: TT.coralButtonGradient,
                border: Border.all(color: TT.goldShine, width: 1),
              ),
              child: Text(
                '×$count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular avatar with gold ring — crowned royal parrot inside, matches reference #2.
class _AvatarRing extends StatefulWidget {
  @override
  State<_AvatarRing> createState() => _AvatarRingState();
}

class _AvatarRingState extends State<_AvatarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final glow = _glowCtrl.value;
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep, TT.gold],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: TT.gold.withValues(alpha: 0.5 + glow * 0.3),
                blurRadius: 18,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A4A8C), Color(0xFF071F4A)],
                stops: [0.0, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Radial glow behind parrot
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFE89C).withValues(alpha: 0.45 + glow * 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.85],
                      ),
                    ),
                  ),
                  // Crowned parrot
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      TA.mascotVip,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person_rounded, color: Colors.white, size: 60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium IAP CTA — gold gradient pill with crown icon + pulsing glow.
/// Lives on the Profile screen; tap → routes to Shop (removeAds/vipMonthly/starterBundle).
class _CocoPremiumCta extends StatefulWidget {
  final VoidCallback onTap;
  const _CocoPremiumCta({required this.onTap});

  @override
  State<_CocoPremiumCta> createState() => _CocoPremiumCtaState();
}

class _CocoPremiumCtaState extends State<_CocoPremiumCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final glow = _glowCtrl.value;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: TT.gold.withValues(alpha: 0.45 + glow * 0.4),
                  blurRadius: 22,
                  spreadRadius: glow * 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF6B0B0B),
                  size: 24,
                  shadows: [
                    Shadow(color: Color(0xFFFFE89C), blurRadius: 6),
                  ],
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFFF0B0)],
                  ).createShader(rect),
                  child: const Text(
                    'COCO PREMIUM',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.4,
                      shadows: [
                        Shadow(color: Color(0xFF6B0B0B), offset: Offset(0, 1), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B0B0B),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
