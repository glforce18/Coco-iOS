import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/music_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/auth/auth_manager.dart';
import 'package:patpat_game/data/cloud_sync_manager.dart';
import 'package:patpat_game/providers/auth_provider.dart';
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
    // Check if user is already logged in from a previous session.
    // Deferred to avoid modifying provider during widget tree build.
    Future(() {
      ref.read(authProvider.notifier).checkCurrentUser();
    });
  }

  Widget _buildLoginButton(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn) {
      // Show logged-in state: user name + tap to show profile/logout
      return MenuActionButton(
        text: authState.userName ?? 'Hesabim',
        gradientColors: const [
          GameColors.neonCyan,
          GameColors.blueLight,
          GameColors.blueDark,
        ],
        onTap: () {
          SoundManager.instance.play(SoundType.buttonClick);
          HapticManager.instance.tapLight();
          _showProfilePopup(context);
        },
      );
    }

    return MenuActionButton(
      text: 'Giris Yap',
      gradientColors: const [
        GameColors.neonCyan,
        GameColors.blueLight,
        GameColors.blueDark,
      ],
      onTap: () {
        SoundManager.instance.play(SoundType.buttonClick);
        HapticManager.instance.tapLight();
        _showLoginPopup(context);
      },
    );
  }

  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Center(
        child: _LoginDialog(parentRef: ref),
      ),
    );
  }

  void _showProfilePopup(BuildContext context) {
    final authState = ref.read(authProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Center(
        child: Material(
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
              border: Border.all(color: GameColors.goldFrame, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: GameColors.goldDark.withAlpha(60),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
                if (authState.photoUrl != null) ...[
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(authState.photoUrl!),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: GameColors.neonCyan.withAlpha(40),
                    child: const Icon(Icons.person, color: GameColors.neonCyan, size: 32),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  authState.userName ?? 'Oyuncu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (authState.userEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authState.userEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(140),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Sign out button
                GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: GameColors.pinkDark.withAlpha(60),
                      border: Border.all(color: GameColors.pinkLight.withAlpha(80)),
                    ),
                    child: const Center(
                      child: Text(
                        'Cikis Yap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: GameColors.pinkLight,
                        ),
                      ),
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

                // Login / Profile button
                _buildLoginButton(context),

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
// Login Popup Dialog
// ---------------------------------------------------------------------------
class _LoginDialog extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _LoginDialog({required this.parentRef});

  @override
  ConsumerState<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<_LoginDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn(Future<bool> Function() signInMethod) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await signInMethod();

    if (success && mounted) {
      // Pull cloud progress and merge
      final cloudProgress = await CloudSyncManager.instance.pull();
      if (cloudProgress != null) {
        await widget.parentRef
            .read(playerProgressProvider.notifier)
            .mergeWithCloud(cloudProgress);
      } else {
        // No cloud data — push local progress to cloud
        final localProgress = widget.parentRef.read(playerProgressProvider);
        await CloudSyncManager.instance.push(localProgress);
      }
      if (mounted) Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Giris basarisiz oldu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = AuthManager.instance.firebaseReady;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.bgLight, GameColors.bgDeep],
          ),
          border: Border.all(color: GameColors.goldFrame, width: 2.5),
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
            // Header
            Stack(
              children: [
                Center(
                  child: Text(
                    'Giris Yap',
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

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Ilerlemeni kaydet ve\ncihazlar arasi senkronla',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(160),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            if (!firebaseReady) ...[
              // Firebase not configured message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: GameColors.orangeDark.withAlpha(40),
                  border: Border.all(color: GameColors.orangeLight.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: GameColors.orangeLight, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Firebase yapilandirilmadi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GameColors.orangeLight.withAlpha(220),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giris ozelligi henuz aktif degil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_isLoading) ...[
              // Loading spinner
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(GameColors.neonCyan),
              ),
              const SizedBox(height: 16),
              Text(
                'Giris yapiliyor...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Google Sign-In button
              _SignInButton(
                label: 'Google ile Giris Yap',
                icon: Icons.g_mobiledata,
                iconColor: Colors.white,
                gradientColors: const [
                  Color(0xFF4285F4),
                  Color(0xFF3367D6),
                ],
                onTap: () => _handleSignIn(
                  ref.read(authProvider.notifier).signInWithGoogle,
                ),
              ),

              // Apple Sign-In button (iOS only)
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                _SignInButton(
                  label: 'Apple ile Giris Yap',
                  icon: Icons.apple,
                  iconColor: Colors.white,
                  gradientColors: const [
                    Color(0xFF1A1A1A),
                    Color(0xFF000000),
                  ],
                  onTap: () => _handleSignIn(
                    ref.read(authProvider.notifier).signInWithApple,
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GameColors.pinkLight,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _SignInButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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
