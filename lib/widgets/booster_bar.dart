import 'package:flutter/material.dart';

import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/theme/tropical_theme.dart';

/// Mockup-style booster panel — unified wooden plank with 3 round socket
/// slots inside, each with image + red count badge. Optional 4th lock slot.
class BoosterBar extends StatelessWidget {
  final ActiveBoosterMode boosterMode;
  final int hammerCount;
  final int colorBlastCount;
  final int extraMovesCount;
  final int unlockLevel; // shows lock slot with this level requirement
  final int playerLevel;
  final Function(BoosterType) onActivate;
  final VoidCallback onCancel;

  const BoosterBar({
    super.key,
    required this.boosterMode,
    required this.onActivate,
    required this.onCancel,
    this.hammerCount = 0,
    this.colorBlastCount = 0,
    this.extraMovesCount = 0,
    this.unlockLevel = 10,
    this.playerLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = boosterMode != ActiveBoosterMode.none;
    if (isActive) return _CancelBar(boosterMode: boosterMode, onCancel: onCancel);

    // Locked 4th-slot was a misleading visual — there is no 4th booster
    // type. Removed to avoid confusion about what unlocks at level 10.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Socket(
            asset: TA.boosterHammer,
            label: 'Çekiç',
            count: hammerCount,
            onTap: () => onActivate(BoosterType.hammer),
          ),
          _Socket(
            asset: TA.boosterColorBlast,
            label: 'Renk',
            count: colorBlastCount,
            onTap: () => onActivate(BoosterType.colorBlast),
          ),
          _Socket(
            asset: TA.boosterExtraMoves,
            label: '+3 Hamle',
            count: extraMovesCount,
            onTap: () => onActivate(BoosterType.extraMoves),
          ),
        ],
      ),
    );
  }
}

class _Socket extends StatelessWidget {
  final String asset;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _Socket({
    required this.asset,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = count > 0;
    return GestureDetector(
      onTap: available ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Wooden coin-style socket — gold ring + dark wood interior.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [TT.goldShine, TT.gold, TT.goldDeep],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 10, offset: const Offset(0, 4)),
                    BoxShadow(color: TT.gold.withAlpha(140), blurRadius: 14, spreadRadius: -2),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Dark wood interior — coin-like depth
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      radius: 0.95,
                      colors: [
                        Color(0xFF6B4226),
                        Color(0xFF3D2712),
                        Color(0xFF1F1408),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: ColorFiltered(
                    colorFilter: available
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix(<double>[
                            0.33, 0.33, 0.33, 0, 0,
                            0.33, 0.33, 0.33, 0, 0,
                            0.33, 0.33, 0.33, 0, 0,
                            0, 0, 0, 0.85, 0,
                          ]),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: TT.goldShine, size: 32),
                    ),
                  ),
                ),
              ),
              // Red count badge
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TT.coralLight, TT.coral, TT.coralDark],
                    ),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: TT.sandLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelBar extends StatelessWidget {
  final ActiveBoosterMode boosterMode;
  final VoidCallback onCancel;
  const _CancelBar({required this.boosterMode, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final hammerMode = boosterMode == ActiveBoosterMode.hammerSelect;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TT.goldShine, TT.gold, TT.goldDeep],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(170), blurRadius: 12, offset: const Offset(0, 5)),
            BoxShadow(color: TT.coral.withAlpha(140), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1A), Color(0xFF3D2712)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: TT.coralButtonGradient,
                  border: Border.all(color: TT.goldShine, width: 1.5),
                ),
                child: Icon(
                  hammerMode ? Icons.gavel_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hammerMode ? 'Hedef seç' : 'Renk seç',
                style: TT.bodyMedium.copyWith(
                  color: TT.sandLight,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: TT.coralButtonGradient,
                    border: Border.all(color: TT.goldShine, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: TT.coral.withAlpha(120), blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    'İptal',
                    style: TT.titleSmall.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black.withAlpha(220), blurRadius: 3, offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
