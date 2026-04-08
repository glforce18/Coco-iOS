import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/music_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Sync audio toggles from persisted settings.
    final progress = ref.read(playerProgressProvider);
    SoundManager.instance.enabled = progress.soundEnabled;
    MusicManager.instance.enabled = progress.musicEnabled;
    HapticManager.instance.enabled = progress.vibrationEnabled;
    // Start menu music.
    MusicManager.instance.play(MusicTrack.menu);
  }

  @override
  void dispose() {
    MusicManager.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/backgrounds/main_menu_custom_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [GameColors.bgLight, GameColors.bgDeep],
                ),
              ),
            ),
          ),

          // Gradient overlay: transparent top -> dark purple bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  GameColors.bgDeep.withAlpha(120),
                  GameColors.bgDeep.withAlpha(220),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main content column
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Title: "PatPat"
                const _GameTitle(),

                const SizedBox(height: 6),

                // Subtitle: "ESLESTIRME MACERASI"
                Text(
                  'ESLESTIRME MACERASI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GameColors.goldLight,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: GameColors.goldDark.withAlpha(180),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Play button
                MenuActionButton(
                  text: 'OYNA!',
                  gradientColors: const [
                    GameColors.greenLight,
                    GameColors.green,
                    GameColors.greenDark,
                  ],
                  onTap: () {
                    SoundManager.instance.play(SoundType.buttonClick);
                    HapticManager.instance.tapLight();
                    context.go('/map');
                  },
                ),

                const SizedBox(height: 12),

                // Login button (disabled for now)
                MenuActionButton(
                  text: 'Giris Yap',
                  gradientColors: const [
                    GameColors.neonCyan,
                    GameColors.blueLight,
                    GameColors.blueDark,
                  ],
                  onTap: null,
                ),

                const Spacer(flex: 2),

                // Stats bar at bottom
                StatsBar(
                  stars: progress.totalStars,
                  coins: progress.coins,
                  lives: progress.lives,
                  level: progress.currentLevel,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Settings gear button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _SettingsButton(ref: ref),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game Title with colorful shadows
// ---------------------------------------------------------------------------
class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'PatPat',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 3,
        shadows: [
          Shadow(
            color: GameColors.hotPink.withAlpha(200),
            blurRadius: 24,
            offset: const Offset(0, 2),
          ),
          Shadow(
            color: GameColors.neonCyan.withAlpha(160),
            blurRadius: 32,
            offset: const Offset(0, -2),
          ),
          Shadow(
            color: GameColors.purpleDark.withAlpha(220),
            blurRadius: 4,
            offset: const Offset(2, 4),
          ),
          Shadow(
            color: GameColors.goldLight.withAlpha(100),
            blurRadius: 48,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings gear button
// ---------------------------------------------------------------------------
class _SettingsButton extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundManager.instance.play(SoundType.buttonClick);
        HapticManager.instance.tapLight();
        _showSettingsPopup(context, ref);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GameColors.bgDeep.withAlpha(160),
          border: Border.all(color: GameColors.goldFrame.withAlpha(120)),
          boxShadow: [
            BoxShadow(
              color: GameColors.purpleDark.withAlpha(80),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.settings,
          color: Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MenuActionButton — reusable gradient button
// ---------------------------------------------------------------------------
class MenuActionButton extends StatefulWidget {
  final String text;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const MenuActionButton({
    super.key,
    required this.text,
    required this.gradientColors,
    this.onTap,
  });

  @override
  State<MenuActionButton> createState() => _MenuActionButtonState();
}

class _MenuActionButtonState extends State<MenuActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final double opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 240,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            border: Border.all(
              color: GameColors.goldFrame.withAlpha(160),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[1].withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: GameColors.bgDeep.withAlpha(100),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Shimmer highlight
                if (enabled)
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Positioned(
                        left: -80 +
                            _shimmerController.value *
                                (240 + 80),
                        top: 0,
                        child: Container(
                          width: 80,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withAlpha(0),
                                Colors.white.withAlpha(40),
                                Colors.white.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Top highlight (subtle white gradient)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(50),
                          Colors.white.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Centered text
                Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ink splash effect
                if (enabled)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: widget.onTap,
                        splashColor: Colors.white.withAlpha(40),
                        highlightColor: Colors.white.withAlpha(20),
                      ),
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

// ---------------------------------------------------------------------------
// StatsBar — bottom stats row
// ---------------------------------------------------------------------------
class StatsBar extends StatelessWidget {
  final int stars;
  final int coins;
  final int lives;
  final int level;

  const StatsBar({
    super.key,
    required this.stars,
    required this.coins,
    required this.lives,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GameColors.bgDeep.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.purpleLight.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(140),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatCapsule(
              emoji: '\u2B50', // star
              value: '$stars',
              color: GameColors.yellowLight,
            ),
            _StatCapsule(
              emoji: '\uD83E\uDE99', // coin
              value: '$coins',
              color: GameColors.orangeLight,
            ),
            _StatCapsule(
              emoji: '\u2764\uFE0F', // heart
              value: '$lives',
              color: GameColors.pinkLight,
            ),
            _StatCapsule(
              emoji: '\uD83C\uDFC6', // trophy
              value: 'Lv $level',
              color: GameColors.purpleLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCapsule extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _StatCapsule({
    required this.emoji,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            shadows: [
              Shadow(
                color: color.withAlpha(80),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Popup
// ---------------------------------------------------------------------------
void _showSettingsPopup(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Center(
        child: _SettingsDialog(ref: ref),
      );
    },
  );
}

class _SettingsDialog extends ConsumerWidget {
  final WidgetRef ref;
  const _SettingsDialog({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef consumerRef) {
    final progress = consumerRef.watch(playerProgressProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.bgLight, GameColors.bgDeep],
          ),
          border: Border.all(
            color: GameColors.goldFrame,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldDark.withAlpha(60),
              blurRadius: 24,
            ),
            BoxShadow(
              color: GameColors.bgDeep.withAlpha(200),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Stack(
              children: [
                Center(
                  child: Text(
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: GameColors.goldLight,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: GameColors.goldDark.withAlpha(140),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    iconSize: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sound toggle
            _SettingsToggle(
              label: 'Ses',
              emoji: '\uD83D\uDD0A', // speaker
              value: progress.soundEnabled,
              onChanged: (v) {
                SoundManager.instance.enabled = v;
                consumerRef
                    .read(playerProgressProvider.notifier)
                    .updateSettings(sound: v);
              },
            ),

            const SizedBox(height: 12),

            // Music toggle
            _SettingsToggle(
              label: 'Muzik',
              emoji: '\uD83C\uDFB5', // music note
              value: progress.musicEnabled,
              onChanged: (v) {
                MusicManager.instance.enabled = v;
                if (v) MusicManager.instance.play(MusicTrack.menu);
                consumerRef
                    .read(playerProgressProvider.notifier)
                    .updateSettings(music: v);
              },
            ),

            const SizedBox(height: 12),

            // Vibration toggle
            _SettingsToggle(
              label: 'Titresim',
              emoji: '\uD83D\uDCF3', // vibration
              value: progress.vibrationEnabled,
              onChanged: (v) {
                HapticManager.instance.enabled = v;
                consumerRef
                    .read(playerProgressProvider.notifier)
                    .updateSettings(vibration: v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final String emoji;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.label,
    required this.emoji,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: GameColors.neonCyan,
          activeTrackColor: GameColors.neonCyan.withAlpha(60),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withAlpha(60),
        ),
      ],
    );
  }
}
