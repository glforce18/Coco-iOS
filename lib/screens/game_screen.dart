import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:patpat_game/audio/haptic_manager.dart';
import 'package:patpat_game/audio/music_manager.dart';
import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/game/game_controller.dart';
import 'package:patpat_game/game/level_generator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/providers/game_providers.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/booster_bar.dart';
import 'package:patpat_game/widgets/combo_text.dart';
import 'package:patpat_game/widgets/game_board.dart';
import 'package:patpat_game/widgets/game_hud.dart';
import 'package:patpat_game/widgets/game_over_overlay.dart';
import 'package:patpat_game/widgets/level_complete_overlay.dart';
import 'package:patpat_game/widgets/score_progress_bar.dart';
import 'package:patpat_game/widgets/tutorial_overlay.dart';
import 'package:patpat_game/game/tutorial_manager.dart';
import 'package:patpat_game/ads/ad_manager.dart';

/// Main gameplay screen: wires [GameController] to all UI widgets.
class GameScreen extends ConsumerStatefulWidget {
  final int level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final GameController _controller;
  late final TutorialManager _tutorial;

  // Track previous state/combo so we only fire sounds on transitions.
  GameState _prevState = GameState.idle;
  int _prevCombo = 0;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onControllerChange);

    // Initialize tutorial + read progress for settings
    final progress = ref.read(playerProgressProvider);
    _tutorial = TutorialManager(startCompleted: progress.tutorialCompleted);

    _startLevel(widget.level);

    // Sync audio toggles from settings.
    SoundManager.instance.enabled = progress.soundEnabled;
    MusicManager.instance.enabled = progress.musicEnabled;
    HapticManager.instance.enabled = progress.vibrationEnabled;

    // Start game music (boss track for levels divisible by 10).
    final track = widget.level % 10 == 0 ? MusicTrack.boss : MusicTrack.game;
    MusicManager.instance.play(track);
  }

  void _startLevel(int level) {
    final config = LevelGenerator.generate(level);
    _controller.startLevel(config);
  }

  void _onControllerChange() {
    if (!mounted) return;

    final newState = _controller.state;
    final newCombo = _controller.comboCount;

    // Sound effects based on state transitions
    if (newState != _prevState) {
      switch (newState) {
        case GameState.swapping:
          SoundManager.instance.play(SoundType.swap);
          HapticManager.instance.tapLight();
        case GameState.destroying:
          SoundManager.instance.play(SoundType.destroy);
          HapticManager.instance.tapMatch();
        case GameState.levelComplete:
          SoundManager.instance.play(SoundType.levelComplete);
          HapticManager.instance.tapHeavy();
          MusicManager.instance.stop();
        case GameState.gameOver:
          SoundManager.instance.play(SoundType.gameOver);
          HapticManager.instance.tapHeavy();
          MusicManager.instance.stop();
        case GameState.paused:
          MusicManager.instance.pause();
        case GameState.idle:
          if (_prevState == GameState.paused) {
            MusicManager.instance.resume();
          }
        default:
          break;
      }
    }

    // Combo sound when combo count increases
    if (newCombo > _prevCombo && newCombo >= 2) {
      SoundManager.instance.play(SoundType.combo);
      HapticManager.instance.tapCombo();
    }

    // Match sound when entering matching-related destruction
    if (newCombo > _prevCombo && newCombo >= 1 && _prevCombo == 0) {
      SoundManager.instance.play(SoundType.match);
      HapticManager.instance.tapMatch();
    }

    _prevState = newState;
    _prevCombo = newCombo;

    // Auto-advance tutorial on relevant game events
    if (!_tutorial.isCompleted && widget.level <= 3) {
      final step = _tutorial.currentStep;
      if (step != null) {
        if (step == TutorialStep.teachSwap &&
            newState == GameState.matching) {
          _tutorial.advance();
        }
        if (step == TutorialStep.teachMatch &&
            newState == GameState.destroying) {
          _tutorial.advance();
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    MusicManager.instance.stop();
    super.dispose();
  }

  void _onBack() {
    SoundManager.instance.play(SoundType.buttonClick);
    HapticManager.instance.tapLight();
    context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with overlay
          _GameBackground(),

          // Main game content
          SafeArea(
            child: Stack(
              children: [
                // Main layout
                Column(
                  children: [
                    GameHud(
                      level: _controller.config.levelNumber,
                      movesLeft: _controller.movesLeft,
                      score: _controller.score,
                      timeLeft: _controller.timeLeft,
                      goals: _controller.goals,
                      onPause: _controller.togglePause,
                      onBack: _onBack,
                    ),
                    ScoreProgressBar(
                      score: _controller.score,
                      targetScore: _controller.config.targetScore,
                      stars: _controller.stars,
                    ),
                    // Board with golden frame
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: _GoldFrameBoard(
                          child: GameBoard(
                            grid: _controller.grid,
                            selectedCell: _controller.selectedCell,
                            hintPositions: _controller.hintPositions,
                            boosterMode: _controller.boosterMode,
                            onCellTapped: (pos) =>
                                _controller.onCellTapped(pos),
                            onSwipe: (pos, dir) =>
                                _controller.onSwipeTo(pos, dir),
                            animator: _controller.animator,
                            onCellMetrics: _controller.setCellMetrics,
                          ),
                        ),
                      ),
                    ),
                    BoosterBar(
                      boosterMode: _controller.boosterMode,
                      onActivate: (type) => _controller.activateBooster(type),
                      onCancel: _controller.cancelBooster,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),

                // Combo text overlay
                if (_controller.comboCount >= 2)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ComboText(comboCount: _controller.comboCount),
                    ),
                  ),

                // Level complete overlay
                if (_controller.state == GameState.levelComplete)
                  LevelCompleteOverlay(
                    score: _controller.score,
                    stars: _controller.stars,
                    coinsEarned: _controller.coinsEarned,
                    maxCombo: _controller.maxComboThisLevel,
                    onContinue: () {
                      ref.read(playerProgressProvider.notifier).completeLevel(
                        widget.level,
                        _controller.stars,
                        _controller.score,
                        _controller.coinsEarned,
                      );
                      final progress = ref.read(playerProgressProvider);
                      final adsDisabled =
                          progress.removeAdsPurchased || progress.vipActive;
                      if (!adsDisabled &&
                          AdManager.instance.shouldShowInterstitial()) {
                        AdManager.instance.showInterstitialAd(
                          onDismissed: () {
                            if (mounted) context.go('/map');
                          },
                        );
                      } else {
                        context.go('/map');
                      }
                    },
                  ),

                // Game over overlay
                if (_controller.state == GameState.gameOver)
                  GameOverOverlay(
                    score: _controller.score,
                    onRetry: () => _startLevel(widget.level),
                    onQuit: _onBack,
                    showAdButton: AdManager.instance.isRewardedAdReady &&
                        !ref.read(playerProgressProvider).removeAdsPurchased,
                    onWatchAd: () {
                      AdManager.instance.showRewardedAd(
                        onRewarded: () {
                          _controller.addExtraMoves(3);
                        },
                      );
                    },
                  ),

                // Tutorial overlay
                if (_tutorial.isVisible &&
                    _tutorial.currentStep != null &&
                    widget.level <= 3 &&
                    _controller.state == GameState.idle)
                  TutorialOverlay(
                    step: _tutorial.currentStep!,
                    onContinue: () {
                      setState(() {
                        if (_tutorial.isWaitingForAction) {
                          _tutorial.hideOverlay();
                        } else {
                          _tutorial.advance();
                          if (_tutorial.isCompleted) {
                            ref
                                .read(playerProgressProvider.notifier)
                                .completeTutorial();
                          }
                        }
                      });
                    },
                    onSkip: () {
                      setState(() {
                        _tutorial.skip();
                        ref
                            .read(playerProgressProvider.notifier)
                            .completeTutorial();
                      });
                    },
                  ),

                // Pause overlay
                if (_controller.state == GameState.paused)
                  _PauseOverlay(
                    onResume: _controller.togglePause,
                    onRestart: () => _startLevel(widget.level),
                    onQuit: _onBack,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Background — uses actual background image with overlay
// ─────────────────────────────────────────────────────────────────────────────

class _GameBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          'assets/backgrounds/game_bg_leonardo.jpg',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [GameColors.bgDeep, GameColors.bgMid, GameColors.bgLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Semi-transparent overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.bgDeep.withAlpha(140),
                GameColors.bgDeep.withAlpha(100),
                GameColors.bgDeep.withAlpha(160),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold Frame Board — ornate golden border around the game board
// ─────────────────────────────────────────────────────────────────────────────

class _GoldFrameBoard extends StatelessWidget {
  final Widget child;
  const _GoldFrameBoard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.transparent,
          width: 3,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE44D), // goldLight
            Color(0xFFFFD700), // goldFrame
            Color(0xFFB8860B), // goldDark
            Color(0xFFFFD700), // goldFrame
            Color(0xFFFFE44D), // goldLight
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.goldFrame.withAlpha(50),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: GameColors.goldDark.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0235).withAlpha(200),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pause overlay
// ─────────────────────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D0B80), Color(0xFF1A0660)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: GameColors.goldFrame.withAlpha(140),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.goldFrame.withAlpha(30),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DURAKLADI',
                style: TextStyle(
                  color: GameColors.goldLight,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: GameColors.goldDark, blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _PauseButton(
                label: 'Devam Et',
                color: GameColors.neonGreen,
                onTap: onResume,
              ),
              const SizedBox(height: 12),
              _PauseButton(
                label: 'Basla',
                color: GameColors.neonCyan,
                onTap: onRestart,
              ),
              const SizedBox(height: 12),
              _PauseButton(
                label: 'Cik',
                color: GameColors.hotPink,
                onTap: onQuit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PauseButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(120)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
