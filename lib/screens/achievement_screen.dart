import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/models/achievement.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';
import 'package:patpat_game/widgets/tropical/island_chip.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProgressProvider);
    final unlocked = progress.achievements.toSet();
    final total = Achievement.values.length;
    final earned = unlocked.length;
    final progressFraction = (earned / total).clamp(0.0, 1.0);

    return IslandScaffold(
      backgroundAsset: TA.achievementBg,
      overlayOpacity: 0.42,
      bottomBar: IslandBottomNav(
        activeIndex: -1,
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
          IslandNavTab(icon: Icons.person_rounded, label: 'Profil', onTap: () => context.push('/profile')),
        ],
      ),
      child: Column(
        children: [
          IslandTopBar(
            stars: progress.totalStars,
            coins: progress.coins,
            hearts: progress.lives,
            leading: IslandCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/map')),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: TT.coralButtonGradient,
                border: Border.all(color: TT.goldShine, width: 2),
                boxShadow: [
                  BoxShadow(color: TT.coral.withAlpha(160), blurRadius: 16, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: TT.goldShine, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'BAŞARIMLAR',
                        style: TT.titleLarge.copyWith(
                          color: TT.sandLight,
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(color: Colors.black.withAlpha(220), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IslandChip(
                        text: '$earned / $total',
                        bg: TT.gold,
                        fontSize: 13,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(color: TT.coralDark.withAlpha(180)),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressFraction,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [TT.goldShine, TT.gold, TT.goldDeep],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: Achievement.values.length,
              itemBuilder: (_, i) {
                final ach = Achievement.values[i];
                return _AchievementCard(achievement: ach, unlocked: unlocked.contains(ach.id));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementCard({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: unlocked
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.goldShine, TT.goldBright, TT.gold, TT.goldDeep],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [TT.bambooLight.withAlpha(160), TT.bamboo.withAlpha(120), TT.bambooDark.withAlpha(120)],
              ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 10, offset: const Offset(0, 4)),
          if (unlocked)
            BoxShadow(color: TT.gold.withAlpha(160), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: unlocked
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF1D9), Color(0xFFF5DBA8)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.bambooLight.withAlpha(180), TT.sandDark.withAlpha(180)],
                ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix(<double>[
                          0.33, 0.33, 0.33, 0, 0,
                          0.33, 0.33, 0.33, 0, 0,
                          0.33, 0.33, 0.33, 0, 0,
                          0, 0, 0, 0.7, 0,
                        ]),
                  child: SizedBox(
                    height: 68,
                    width: 68,
                    child: Image.asset(
                      'assets/tropical/achievements/ach_${_iconSlug(achievement)}.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(achievement.emoji, style: const TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TT.driftWoodDark.withAlpha(200),
                      border: Border.all(color: TT.bamboo, width: 1.5),
                    ),
                    child: const Icon(Icons.lock_rounded, color: TT.sandLight, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TT.titleSmall.copyWith(
                color: unlocked ? TT.goldDeep : TT.driftWoodDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TT.bodySmall.copyWith(
                  fontSize: 10,
                  color: unlocked ? TT.driftWoodDark : TT.driftWoodDark.withAlpha(180),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: unlocked
                    ? TT.palmButtonGradient
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [TT.bamboo.withAlpha(180), TT.bambooDark.withAlpha(180)],
                      ),
                border: Border.all(color: TT.goldShine, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: TT.goldShine, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${achievement.coinReward}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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

  String _iconSlug(Achievement a) {
    const map = <String, String>{
      'first_match': 'first_match',
      'combo_5': 'first_combo',
      'combo_10': 'combo_master',
      'stars_50': '3stars_50',
      'stars_100': 'score_100k',
      'stars_200': 'score_1m',
      'level_10': 'tutorial_done',
      'level_30': 'level_50',
      'level_60': 'level_100',
      'level_100': 'level_100',
      'level_240': 'level_240',
      'coins_1000': 'money_saver',
      'coins_5000': 'big_spender',
      'daily_7': 'daily_streak_7',
      'daily_30': 'daily_streak_30',
      'perfect_level': 'perfect_run',
      'perfect_10': '3stars_50',
      'booster_user': 'bomb_user',
      'shop_visitor': 'first_purchase',
      'spin_wheel': 'event_winner',
      'first_special': 'rainbow_user',
      'ice_breaker': 'lightning_user',
      'chocolate_lover': 'rocket_user',
      'speed_runner': 'speed_demon',
      'collector': 'vip_member',
    };
    return map[a.id] ?? 'first_match';
  }
}
