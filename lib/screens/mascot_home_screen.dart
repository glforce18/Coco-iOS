import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

// ---------------------------------------------------------------------------
// Decoration data model
// ---------------------------------------------------------------------------

enum DecorationCategory {
  furniture('Mobilya', Icons.chair_rounded, GameColors.buttonPurple),
  wallpaper('Duvar Kağıdı', Icons.wallpaper_rounded, GameColors.buttonBlue),
  accessory('Aksesuar', Icons.auto_awesome_rounded, GameColors.cherryRed),
  garden('Bahçe', Icons.park_rounded, GameColors.buttonGreen);

  final String label;
  final IconData icon;
  final Color color;
  const DecorationCategory(this.label, this.icon, this.color);
}

enum DecorationRarity {
  common('Yaygın', GameColors.buttonGreen),
  rare('Nadir', GameColors.buttonBlue),
  epic('Epik', GameColors.buttonPurple);

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
  // Furniture
  DecorationItem(id: 'bed', name: 'Yatak', price: 200, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.bed_rounded),
  DecorationItem(id: 'table', name: 'Masa', price: 150, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.table_restaurant_rounded),
  DecorationItem(id: 'chair', name: 'Sandalye', price: 100, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.chair_rounded),
  DecorationItem(id: 'shelf', name: 'Raf', price: 120, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.shelves),
  DecorationItem(id: 'lamp', name: 'Lamba', price: 80, category: DecorationCategory.furniture, rarity: DecorationRarity.common, icon: Icons.light_rounded),
  DecorationItem(id: 'piano', name: 'Piyano', price: 500, category: DecorationCategory.furniture, rarity: DecorationRarity.epic, icon: Icons.piano_rounded),
  // Wallpaper
  DecorationItem(id: 'stars_wp', name: 'Yıldızlı', price: 100, category: DecorationCategory.wallpaper, rarity: DecorationRarity.common, icon: Icons.star_rounded),
  DecorationItem(id: 'forest_wp', name: 'Orman', price: 150, category: DecorationCategory.wallpaper, rarity: DecorationRarity.rare, icon: Icons.forest_rounded),
  DecorationItem(id: 'ocean_wp', name: 'Deniz', price: 200, category: DecorationCategory.wallpaper, rarity: DecorationRarity.rare, icon: Icons.water_rounded),
  // Accessory
  DecorationItem(id: 'crown', name: 'Taç', price: 300, category: DecorationCategory.accessory, rarity: DecorationRarity.epic, icon: Icons.workspace_premium_rounded),
  DecorationItem(id: 'bowtie', name: 'Papyon', price: 100, category: DecorationCategory.accessory, rarity: DecorationRarity.common, icon: Icons.checkroom_rounded),
  DecorationItem(id: 'glasses', name: 'Gözlük', price: 150, category: DecorationCategory.accessory, rarity: DecorationRarity.rare, icon: Icons.visibility_rounded),
  // Garden
  DecorationItem(id: 'flower', name: 'Çiçek', price: 80, category: DecorationCategory.garden, rarity: DecorationRarity.common, icon: Icons.local_florist_rounded),
  DecorationItem(id: 'tree', name: 'Ağaç', price: 200, category: DecorationCategory.garden, rarity: DecorationRarity.rare, icon: Icons.nature_rounded),
  DecorationItem(id: 'pool', name: 'Havuz', price: 400, category: DecorationCategory.garden, rarity: DecorationRarity.epic, icon: Icons.pool_rounded),
  DecorationItem(id: 'swing', name: 'Salıncak', price: 250, category: DecorationCategory.garden, rarity: DecorationRarity.rare, icon: Icons.toys_rounded),
];

// ---------------------------------------------------------------------------
// MascotHomeScreen
// ---------------------------------------------------------------------------

class MascotHomeScreen extends ConsumerStatefulWidget {
  const MascotHomeScreen({super.key});

  @override
  ConsumerState<MascotHomeScreen> createState() => _MascotHomeScreenState();
}

class _MascotHomeScreenState extends ConsumerState<MascotHomeScreen>
    with TickerProviderStateMixin {
  DecorationCategory _selectedCategory = DecorationCategory.furniture;
  late final AnimationController _bounceCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  List<DecorationItem> get _filteredItems =>
      _allDecorations.where((d) => d.category == _selectedCategory).toList();

  void _onBuy(DecorationItem item) {
    final progress = ref.read(playerProgressProvider);
    if (progress.decorations.contains(item.id)) return;
    if (progress.coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetersiz altın! ${item.price} altın gerekli.'),
          backgroundColor: GameColors.cherryRed,
        ),
      );
      return;
    }
    _showBuyDialog(item);
  }

  void _showBuyDialog(DecorationItem item) {
    showDialog(
      context: context,
      builder: (ctx) => _BuyConfirmDialog(
        item: item,
        onConfirm: () {
          ref.read(playerProgressProvider.notifier).buyDecoration(item.id, item.price);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);
    final ownedCount =
        _allDecorations.where((d) => progress.decorations.contains(d.id)).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0235), Color(0xFF1A0660), Color(0xFF2D0B80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _MascotHomeHeader(
                ownedCount: ownedCount,
                totalCount: _allDecorations.length,
                coins: progress.coins,
                onBack: () {
                  context.go('/profile');
                },
              ),
              const SizedBox(height: 8),
              // Room view with mascot
              _RoomView(
                bounceCtrl: _bounceCtrl,
                sparkleCtrl: _sparkleCtrl,
                ownedDecorations: progress.decorations,
              ),
              const SizedBox(height: 12),
              // Category tabs
              _CategoryTabs(
                selected: _selectedCategory,
                onSelected: (c) => setState(() => _selectedCategory = c),
              ),
              const SizedBox(height: 8),
              // Decoration grid
              Expanded(
                child: _DecorationGrid(
                  items: _filteredItems,
                  owned: progress.decorations,
                  onBuy: _onBuy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _MascotHomeHeader extends StatelessWidget {
  final int ownedCount;
  final int totalCount;
  final int coins;
  final VoidCallback onBack;

  const _MascotHomeHeader({
    required this.ownedCount,
    required this.totalCount,
    required this.coins,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
                border: Border.all(color: Colors.white.withAlpha(60)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Maskot Evi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: GameColors.goldFrameBright,
                shadows: [
                  Shadow(
                    color: GameColors.goldFrameDeep.withAlpha(160),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Owned count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GameColors.buttonPurple.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.buttonPurple.withAlpha(80)),
            ),
            child: Text(
              '$ownedCount/$totalCount',
              style: const TextStyle(
                color: GameColors.buttonPurple,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Coin display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GameColors.goldFrameDeep.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.goldFrameMid.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\uD83E\uDE99', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: GameColors.goldFrameBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

// ---------------------------------------------------------------------------
// Room View (220dp) with mascot and sparkles
// ---------------------------------------------------------------------------

class _RoomView extends StatelessWidget {
  final AnimationController bounceCtrl;
  final AnimationController sparkleCtrl;
  final Set<String> ownedDecorations;

  const _RoomView({
    required this.bounceCtrl,
    required this.sparkleCtrl,
    required this.ownedDecorations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A50), Color(0xFF2D1070)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.purpleLight.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background pattern
            CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _RoomBgPainter(ownedDecorations),
            ),
            // Floating sparkles
            AnimatedBuilder(
              animation: sparkleCtrl,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter:
                      _SparklesPainter(sparkleCtrl.value),
                );
              },
            ),
            // Bouncing mascot
            Center(
              child: AnimatedBuilder(
                animation: bounceCtrl,
                builder: (context, _) {
                  final bounce = -6.0 * sin(bounceCtrl.value * pi);
                  return Transform.translate(
                    offset: Offset(0, bounce),
                    child: const Text(
                      '\uD83E\uDEB4', // jelly emoji placeholder for mascot
                      style: TextStyle(fontSize: 72),
                    ),
                  );
                },
              ),
            ),
            // Floor shadow
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Owned decoration indicators at bottom
            if (ownedDecorations.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ownedDecorations.take(6).map((id) {
                    final item = _allDecorations.where((d) => d.id == id).firstOrNull;
                    if (item == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(item.icon, color: Colors.white.withAlpha(100), size: 18),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomBgPainter extends CustomPainter {
  final Set<String> owned;
  _RoomBgPainter(this.owned);

  @override
  void paint(Canvas canvas, Size size) {
    // Floor
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2D1070).withAlpha(0),
          const Color(0xFF1A0A50).withAlpha(120),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      floorPaint,
    );

    // Wall line
    final wallPaint = Paint()
      ..color = GameColors.purpleLight.withAlpha(30)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      wallPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomBgPainter old) => false;
}

class _SparklesPainter extends CustomPainter {
  final double t;
  _SparklesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height * 0.6;
      final y = baseY + sin((t + i * 0.3) * 2 * pi) * 8;
      final alpha = (100 + 80 * sin((t + i * 0.5) * 2 * pi)).toInt();
      final sparkPaint = Paint()
        ..color = Colors.white.withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), 2, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) => true;
}

// ---------------------------------------------------------------------------
// Category Tabs
// ---------------------------------------------------------------------------

class _CategoryTabs extends StatelessWidget {
  final DecorationCategory selected;
  final ValueChanged<DecorationCategory> onSelected;

  const _CategoryTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: DecorationCategory.values.map((cat) {
          final isActive = cat == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                onSelected(cat);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? cat.color.withAlpha(40) : Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? cat.color.withAlpha(140) : Colors.white.withAlpha(20),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon,
                        color: isActive ? cat.color : Colors.white38, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      cat.label,
                      style: TextStyle(
                        color: isActive ? cat.color : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decoration Grid
// ---------------------------------------------------------------------------

class _DecorationGrid extends StatelessWidget {
  final List<DecorationItem> items;
  final Set<String> owned;
  final ValueChanged<DecorationItem> onBuy;

  const _DecorationGrid({
    required this.items,
    required this.owned,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = owned.contains(item.id);
        return _DecorationCard(
          item: item,
          isOwned: isOwned,
          onTap: () => onBuy(item),
        );
      },
    );
  }
}

class _DecorationCard extends StatelessWidget {
  final DecorationItem item;
  final bool isOwned;
  final VoidCallback onTap;

  const _DecorationCard({
    required this.item,
    required this.isOwned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOwned ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOwned
                ? [
                    item.rarity.color.withAlpha(20),
                    item.rarity.color.withAlpha(10),
                  ]
                : [const Color(0xFF1A0660), const Color(0xFF0D0235)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOwned
                ? item.rarity.color.withAlpha(100)
                : Colors.white.withAlpha(20),
            width: isOwned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rarity label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.rarity.color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.rarity.label,
                style: TextStyle(
                  color: item.rarity.color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.category.color.withAlpha(20),
                border: Border.all(color: item.category.color.withAlpha(40)),
              ),
              child: Icon(item.icon, color: item.category.color, size: 28),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Price or owned badge
            if (isOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: GameColors.buttonGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GameColors.buttonGreen.withAlpha(80)),
                ),
                child: const Text(
                  'Sahip',
                  style: TextStyle(
                    color: GameColors.buttonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('\uD83E\uDE99', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      color: GameColors.goldFrameBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buy Confirmation Dialog
// ---------------------------------------------------------------------------

class _BuyConfirmDialog extends StatelessWidget {
  final DecorationItem item;
  final VoidCallback onConfirm;

  const _BuyConfirmDialog({
    required this.item,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D0B80), Color(0xFF1A0660)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: GameColors.goldFrameMid.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.buttonPurple.withAlpha(40),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.category.color.withAlpha(30),
                border: Border.all(color: item.category.color.withAlpha(80)),
              ),
              child: Icon(item.icon, color: item.category.color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.price} altına satın almak istiyor musun?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                      child: const Text(
                        'Vazgeç',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [GameColors.goldFrameMid, GameColors.goldFrameDeep],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.goldFrameDeep.withAlpha(80),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Satın Al',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
