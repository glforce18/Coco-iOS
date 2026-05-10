import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/tropical_theme.dart';
import 'package:patpat_game/widgets/tropical/island_button.dart';
import 'package:patpat_game/widgets/tropical/island_chip.dart';
import 'package:patpat_game/widgets/tropical/island_panel.dart';
import 'package:patpat_game/widgets/tropical/island_scaffold.dart';
import 'package:patpat_game/widgets/tropical/island_top_bar.dart';
import 'package:patpat_game/widgets/tropical/mascot_view.dart';

enum DecorationCategory {
  furniture('Mobilya', Icons.chair_rounded, TT.bamboo),
  wallpaper('Duvar', Icons.wallpaper_rounded, TT.lagoon),
  accessory('Aksesuar', Icons.workspace_premium_rounded, TT.coral),
  garden('Bahçe', Icons.park_rounded, TT.palm);

  final String label;
  final IconData icon;
  final Color color;
  const DecorationCategory(this.label, this.icon, this.color);
}

enum DecorationRarity {
  common('Yaygın', TT.palm),
  rare('Nadir', TT.lagoon),
  epic('Epik', TT.coral);

  final String label;
  final Color color;
  const DecorationRarity(this.label, this.color);
}

class DecorationItem {
  final String id;
  final String name;
  final int price;
  final DecorationCategory category;
  final DecorationRarity rarity;
  final IconData icon;

  const DecorationItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.rarity,
    required this.icon,
  });
}

const _allDecorations = <DecorationItem>[
  DecorationItem(id: 'bed', name: 'Hamak', price: 200, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.bed_rounded),
  DecorationItem(id: 'table', name: 'Bambu Masa', price: 150, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.table_restaurant_rounded),
  DecorationItem(id: 'chair', name: 'Hindistan Cevizi', price: 100, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.chair_rounded),
  DecorationItem(id: 'shelf', name: 'Sandık Raf', price: 120, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.shelves),
  DecorationItem(id: 'lamp', name: 'Tiki Lamba', price: 80, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.light_rounded),
  DecorationItem(id: 'piano', name: 'Davul Set', price: 500, category: DecorationCategory.furniture, rarity: DecorationRarity.epic, icon: Icons.piano_rounded),
  DecorationItem(id: 'stars_wp', name: 'Yıldız', price: 100, category: DecorationCategory.wallpaper, rarity: DecorationRarity.common, icon: Icons.star_rounded),
  DecorationItem(id: 'forest_wp', name: 'Orman', price: 150, category: DecorationCategory.wallpaper, rarity: DecorationRarity.rare, icon: Icons.forest_rounded),
  DecorationItem(id: 'ocean_wp', name: 'Deniz', price: 200, category: DecorationCategory.wallpaper, rarity: DecorationRarity.rare, icon: Icons.water_rounded),
  DecorationItem(id: 'crown', name: 'Taç', price: 300, category: DecorationCategory.accessory, rarity: DecorationRarity.epic, icon: Icons.workspace_premium_rounded),
  DecorationItem(id: 'bowtie', name: 'Papyon', price: 100, category: DecorationCategory.accessory, rarity: DecorationRarity.common, icon: Icons.checkroom_rounded),
  DecorationItem(id: 'glasses', name: 'Gözlük', price: 150, category: DecorationCategory.accessory, rarity: DecorationRarity.rare, icon: Icons.visibility_rounded),
  DecorationItem(id: 'flower', name: 'Çiçek', price: 80, category: DecorationCategory.garden, rarity: DecorationRarity.common, icon: Icons.local_florist_rounded),
  DecorationItem(id: 'tree', name: 'Palmiye', price: 200, category: DecorationCategory.garden, rarity: DecorationRarity.rare, icon: Icons.park_rounded),
  DecorationItem(id: 'pool', name: 'Havuz', price: 400, category: DecorationCategory.garden, rarity: DecorationRarity.epic, icon: Icons.pool_rounded),
  DecorationItem(id: 'swing', name: 'Salıncak', price: 250, category: DecorationCategory.garden, rarity: DecorationRarity.rare, icon: Icons.toys_rounded),
];

class MascotHomeScreen extends ConsumerStatefulWidget {
  const MascotHomeScreen({super.key});

  @override
  ConsumerState<MascotHomeScreen> createState() => _MascotHomeScreenState();
}

class _MascotHomeScreenState extends ConsumerState<MascotHomeScreen> {
  DecorationCategory _category = DecorationCategory.furniture;

  List<DecorationItem> get _items =>
      _allDecorations.where((d) => d.category == _category).toList();

  void _onBuy(DecorationItem item) async {
    final progress = ref.read(playerProgressProvider);
    if (progress.decorations.contains(item.id)) return;
    if (progress.coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: TT.coral,
          content: Text('Yeterli altının yok!', textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _BuyConfirmDialog(item: item),
    );
    if (ok == true) {
      await ref.read(playerProgressProvider.notifier).buyDecoration(item.id, item.price);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return IslandScaffold(
      backgroundAsset: TA.mascotHomeBg,
      overlayOpacity: 0.36,
      child: Column(
        children: [
          IslandTopBar(
            stars: progress.totalStars,
            coins: progress.coins,
            hearts: progress.lives,
            leading: IslandCircleButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/profile')),
          ),
          const SizedBox(height: 12),
          // ─── Room view — actual rendered "home" with mascot + decor ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _RoomView(
              ownedIds: progress.decorations.toSet(),
              totalDecor: _allDecorations.length,
              allDecor: _allDecorations,
            ),
          ),
          const SizedBox(height: 12),
          // Category tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                for (final cat in DecorationCategory.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: _category == cat
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.lerp(cat.color, Colors.white, 0.2)!,
                                    cat.color,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [TT.bambooLight.withAlpha(180), TT.bambooDark.withAlpha(180)],
                                ),
                          border: Border.all(color: TT.goldShine, width: _category == cat ? 2 : 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, color: TT.sandLight, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              cat.label,
                              style: const TextStyle(
                                color: TT.sandLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final owned = progress.decorations.contains(item.id);
                return _DecorCard(
                  item: item,
                  owned: owned,
                  canAfford: progress.coins >= item.price,
                  onTap: () => _onBuy(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCard extends StatelessWidget {
  final DecorationItem item;
  final bool owned;
  final bool canAfford;
  final VoidCallback onTap;

  const _DecorCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: owned ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: owned
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TT.palmLight, TT.palm, TT.palmDark],
                )
              : const LinearGradient(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(item.rarity.color, Colors.white, 0.2)!,
                      item.rarity.color,
                    ],
                  ),
                ),
                child: Text(
                  item.rarity.label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              Expanded(
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 38,
                    color: owned ? TT.palm : TT.goldDeep,
                    shadows: [
                      Shadow(color: Colors.black.withAlpha(80), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
              Text(
                item.name,
                style: TT.bodySmall.copyWith(fontWeight: FontWeight.w900, color: TT.driftWoodDark, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: TT.palmButtonGradient,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Sahip',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: canAfford ? TT.coralButtonGradient : TT.bambooButtonGradient,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: TT.goldShine, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${item.price}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyConfirmDialog extends StatelessWidget {
  final DecorationItem item;
  const _BuyConfirmDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: IslandPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 64, color: TT.goldDeep),
                const SizedBox(height: 8),
                Text(item.name, style: TT.titleLarge.copyWith(color: TT.goldDeep)),
                const SizedBox(height: 4),
                IslandChip(
                  text: '${item.price} altın',
                  icon: Icons.monetization_on_rounded,
                  bg: TT.gold,
                  fontSize: 13,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: IslandButton(
                        text: 'İptal',
                        color: IslandButtonColor.bamboo,
                        size: IslandButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IslandButton(
                        text: 'Satın Al',
                        color: IslandButtonColor.coral,
                        size: IslandButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// _RoomView — renders Coco's actual home: hut interior with mascot in
// center and owned decorations placed around the room.
// ─────────────────────────────────────────────────────────────────────
class _RoomView extends StatelessWidget {
  final Set<String> ownedIds;
  final int totalDecor;
  final List<DecorationItem> allDecor;

  const _RoomView({
    required this.ownedIds,
    required this.totalDecor,
    required this.allDecor,
  });

  @override
  Widget build(BuildContext context) {
    final ownedItems = allDecor.where((d) => ownedIds.contains(d.id)).toList();

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TT.goldShine, TT.gold, TT.goldDeep],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(170), blurRadius: 14, offset: const Offset(0, 6)),
          BoxShadow(color: TT.gold.withAlpha(120), blurRadius: 18, spreadRadius: -2),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Real Leonardo hut interior BG
            Positioned.fill(
              child: Image.asset(
                TA.cocoHomeInterior,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8B6F4A), Color(0xFF5C4A2D), Color(0xFF3D2F1A)],
                    ),
                  ),
                ),
              ),
            ),
            // Soft warm overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Title plaque top-center
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: TT.coralButtonGradient,
                      border: Border.all(color: TT.goldShine, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      "Coco'nun Evi",
                      style: TT.titleSmall.copyWith(
                        color: TT.sandLight,
                        fontSize: 13,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Mascot in center (slightly above floor)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: MascotView(pose: MascotPose.happy, height: 170, showHalo: true, interactive: true),
              ),
            ),
            // Owned decorations — placed around the room
            ..._buildDecorPlacements(ownedItems),
            // Counter bottom-right
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withAlpha(180),
                  border: Border.all(color: TT.gold.withAlpha(180), width: 1),
                ),
                child: Text(
                  '${ownedItems.length} / $totalDecor',
                  style: const TextStyle(
                    color: TT.goldShine,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorPlacements(List<DecorationItem> items) {
    // Fixed slot positions in the room — top-left, top-right, mid-left,
    // mid-right, floor-left, floor-right, floor-near-left, floor-near-right.
    const slots = <Offset>[
      Offset(20, 50),    // top-left
      Offset(280, 50),   // top-right (will be flipped on x-axis)
      Offset(15, 110),   // mid-left
      Offset(285, 110),  // mid-right
      Offset(35, 175),   // floor-left
      Offset(265, 175),  // floor-right
      Offset(75, 200),   // near-mascot left
      Offset(225, 200),  // near-mascot right
    ];
    return [
      for (int i = 0; i < items.length && i < slots.length; i++)
        Positioned(
          left: slots[i].dx,
          top: slots[i].dy,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  items[i].rarity.color.withAlpha(220),
                  items[i].rarity.color.withAlpha(120),
                ],
              ),
              border: Border.all(color: TT.goldShine, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(
              items[i].icon,
              color: Colors.white,
              size: 20,
              shadows: [
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
    ];
  }
}


