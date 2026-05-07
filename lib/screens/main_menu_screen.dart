import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patpat_game/auth/auth_manager.dart';
import 'package:patpat_game/data/cloud_sync_manager.dart';
import 'package:patpat_game/providers/auth_provider.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/shared/bottom_nav.dart';
import 'package:patpat_game/widgets/shared/gold_button.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Check if user is already logged in from a previous session.
    // Deferred to avoid modifying provider during widget tree build.
    Future(() {
      ref.read(authProvider.notifier).checkCurrentUser();
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Widget _buildLoginButton(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn) {
      return GoldButton(
        text: authState.userName ?? 'Hesabım',
        color: GoldButtonColor.blue,
        size: GoldButtonSize.large,
        width: 260,
        icon: Icons.account_circle,
        onPressed: () {
          _showProfilePopup(context);
        },
      );
    }

    return GoldButton(
      text: 'Giriş Yap',
      color: GoldButtonColor.blue,
      size: GoldButtonSize.large,
      width: 260,
      icon: Icons.login,
      onPressed: () {
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
                colors: [GameColors.panelPurpleLight, GameColors.panelPurpleDark],
              ),
              border: Border.all(color: GameColors.goldFrameMid, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: GameColors.goldFrameDeep.withAlpha(60),
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
                    backgroundColor: GameColors.buttonBlue.withAlpha(40),
                    child: const Icon(Icons.person, color: GameColors.buttonBlue, size: 32),
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
  Widget build(BuildContext context) {
    final progress = ref.watch(playerProgressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (logo + subtitle are baked into the PNG —
          // do NOT overlay duplicate Text widgets on top)
          Image.asset(
            'assets/backgrounds/main_menu_custom_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GameColors.panelPurpleLight,
                    GameColors.panelPurpleDark,
                  ],
                ),
              ),
            ),
          ),

          // Subtle bottom gradient for stats/nav legibility (kept light so
          // the embedded logo + scenery in the PNG remain vivid)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  GameColors.panelPurpleDark.withAlpha(160),
                  GameColors.panelPurpleDark.withAlpha(240),
                ],
                stops: const [0.0, 0.55, 0.85, 1.0],
              ),
            ),
          ),

          // Floating decorative jelly sprites around the logo zone
          // (mockup M3 — small jellies + sparkles bobbing around the logo).
          _FloatingJellies(controller: _floatCtrl),

          // Main content column
          SafeArea(
            child: Column(
              children: [
                // Logo/subtitle area is provided by the background PNG.
                // Reserve space so buttons land below the artwork.
                const Spacer(flex: 5),

                // Play button — primary CTA
                GoldButton(
                  text: 'OYNA!',
                  color: GoldButtonColor.green,
                  size: GoldButtonSize.large,
                  width: 260,
                  onPressed: () {
                    context.go('/map');
                  },
                ),

                const SizedBox(height: 14),

                // Login / Profile button — secondary CTA
                _buildLoginButton(context),

                const Spacer(flex: 2),

                // Bottom stats pill (stars / coins / lives / level)
                _MenuStatsPill(
                  stars: progress.totalStars,
                  coins: progress.coins,
                  lives: progress.lives,
                  level: progress.currentLevel,
                ),

                const SizedBox(height: 8),

                // Bottom nav (Home tab active)
                const PatPatBottomNav(activeTab: BottomNavTab.home),
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
// _MenuStatsPill — bottom of menu, gold-bordered purple pill with 4 stats
// (matches mockup M3 — distinct from TopStatsBar which has profile/settings)
// ---------------------------------------------------------------------------
class _MenuStatsPill extends StatelessWidget {
  final int stars;
  final int coins;
  final int lives;
  final int level;

  const _MenuStatsPill({
    required this.stars,
    required this.coins,
    required this.lives,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [
              GameColors.goldFrameBright,
              GameColors.goldFrameMid,
              GameColors.goldFrameDeep,
              GameColors.goldFrameMid,
              GameColors.goldFrameBright,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: GameColors.goldFrameMid.withAlpha(80),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.panelPurple,
                GameColors.panelPurpleDark,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MenuStat(
                icon: Icons.star_rounded,
                color: GameColors.starGoldFilled,
                text: '$stars',
              ),
              _MenuStatDivider(),
              _MenuStat(
                icon: Icons.monetization_on,
                color: GameColors.goldFrameMid,
                text: '$coins',
              ),
              _MenuStatDivider(),
              _MenuStat(
                icon: Icons.favorite,
                color: GameColors.cherryRed,
                text: '$lives',
              ),
              _MenuStatDivider(),
              _MenuStat(
                icon: Icons.emoji_events,
                color: GameColors.goldFrameBright,
                text: 'Lv $level',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MenuStat({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 4,
            ),
          ],
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(200),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: GameColors.panelPurpleLight.withAlpha(140),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings gear button (top-right) — mockup M3 style: gold-bordered purple circle
// ---------------------------------------------------------------------------
class _SettingsButton extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showSettingsPopup(context, ref);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              GameColors.goldFrameBright,
              GameColors.goldFrameMid,
              GameColors.goldFrameDeep,
              GameColors.goldFrameMid,
              GameColors.goldFrameBright,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: GameColors.goldFrameMid.withAlpha(100),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.panelPurpleLight,
                GameColors.panelPurpleDark,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(180),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
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
        _errorMessage = 'Giriş başarısız oldu';
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
            colors: [GameColors.panelPurpleLight, GameColors.panelPurpleDark],
          ),
          border: Border.all(color: GameColors.goldFrameMid, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldFrameDeep.withAlpha(60),
              blurRadius: 24,
            ),
            BoxShadow(
              color: GameColors.panelPurpleDark.withAlpha(200),
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
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: GameColors.goldFrameBright,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: GameColors.goldFrameDeep.withAlpha(140),
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
              'İlerlemeni kaydet ve\ncihazlar arası senkronla',
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
                      'Firebase yapılandırılmadı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: GameColors.orangeLight.withAlpha(220),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giriş özelliği henüz aktif değil.',
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
                    AlwaysStoppedAnimation<Color>(GameColors.buttonBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'Giriş yapılıyor...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Google Sign-In button
              _SignInButton(
                label: 'Google ile Giriş Yap',
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
                  label: 'Apple ile Giriş Yap',
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
            colors: [GameColors.panelPurpleLight, GameColors.panelPurpleDark],
          ),
          border: Border.all(
            color: GameColors.goldFrameMid,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.goldFrameDeep.withAlpha(60),
              blurRadius: 24,
            ),
            BoxShadow(
              color: GameColors.panelPurpleDark.withAlpha(200),
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
                      color: GameColors.goldFrameBright,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: GameColors.goldFrameDeep.withAlpha(140),
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
                consumerRef
                    .read(playerProgressProvider.notifier)
                    .updateSettings(sound: v);
              },
            ),

            const SizedBox(height: 12),

            // Music toggle
            _SettingsToggle(
              label: 'Müzik',
              emoji: '\uD83C\uDFB5', // music note
              value: progress.musicEnabled,
              onChanged: (v) {
                consumerRef
                    .read(playerProgressProvider.notifier)
                    .updateSettings(music: v);
              },
            ),

            const SizedBox(height: 12),

            // Vibration toggle
            _SettingsToggle(
              label: 'Titreşim',
              emoji: '\uD83D\uDCF3', // vibration
              value: progress.vibrationEnabled,
              onChanged: (v) {
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
          activeThumbColor: GameColors.buttonBlue,
          activeTrackColor: GameColors.buttonBlue.withAlpha(60),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withAlpha(60),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FloatingJellies — small bobbing jelly sprites positioned around the logo
// area (mockup M3 style). Each jelly has its own phase and bob amplitude so
// they feel alive without being distracting.
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingJellies extends StatelessWidget {
  final AnimationController controller;
  const _FloatingJellies({required this.controller});

  // (assetSuffix, normalized x, normalized y, scale, phase offset)
  // Positions are relative to screen size; y is fraction of screen height.
  // Logo sits roughly between y=0.10 and y=0.30.
  static const _jellies = <(String, double, double, double, double)>[
    // Top-left red potion-ish (use orange jelly as accent)
    ('orange', 0.10, 0.07, 0.55, 0.0),
    // Top-right blue jelly
    ('blue', 0.86, 0.10, 0.50, 0.25),
    // Left side pink jelly
    ('pink', 0.06, 0.22, 0.60, 0.5),
    // Right side green jelly
    ('green', 0.90, 0.24, 0.55, 0.75),
    // Below subtitle — purple jelly
    ('purple', 0.78, 0.34, 0.45, 0.15),
    // Yellow star jelly bottom-left
    ('yellow', 0.14, 0.36, 0.45, 0.6),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return IgnorePointer(
          child: Stack(
            children: _jellies.map((j) {
              final (suffix, nx, ny, scale, phase) = j;
              final bob = sin((t + phase) * 2 * pi) * 6;
              final wobble = cos((t + phase) * 2 * pi) * 3;
              final spriteSize = 64.0 * scale;
              return Positioned(
                left: size.width * nx - spriteSize / 2 + wobble,
                top: size.height * ny - spriteSize / 2 + bob,
                child: Transform.rotate(
                  angle: sin((t + phase) * 2 * pi) * 0.08,
                  child: Image.asset(
                    'assets/sprites/jelly_$suffix.png',
                    width: spriteSize,
                    height: spriteSize,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
