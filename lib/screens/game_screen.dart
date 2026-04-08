import 'package:flutter/material.dart';

import 'package:patpat_game/game/game_controller.dart';
import 'package:patpat_game/game/level_generator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/theme/game_colors.dart';
import 'package:patpat_game/widgets/booster_bar.dart';
import 'package:patpat_game/widgets/combo_text.dart';
import 'package:patpat_game/widgets/game_board.dart';
import 'package:patpat_game/widgets/game_hud.dart';
import 'package:patpat_game/widgets/game_over_overlay.dart';
import 'package:patpat_game/widgets/level_complete_overlay.dart';
import 'package:patpat_game/widgets/score_progress_bar.dart';

/// Main gameplay screen: wires [GameController] to all UI widgets.
class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onControllerChange);
    _startLevel(widget.level);
  }

  void _startLevel(int level) {
    final config = LevelGenerator.generate(level);
    _controller.startLevel(config);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [GameColors.bgDeep, GameColors.bgMid, GameColors.bgLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main layout ───────────────────────────────────────────
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
                  Expanded(
                    child: GameBoard(
                      grid: _controller.grid,
                      selectedCell: _controller.selectedCell,
                      hintPositions: _controller.hintPositions,
                      boosterMode: _controller.boosterMode,
                      onCellTapped: (pos) => _controller.onCellTapped(pos),
                      onSwipe: (pos, dir) => _controller.onSwipeTo(pos, dir),
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

              // ── Combo text overlay ────────────────────────────────────
              if (_controller.comboCount >= 2)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ComboText(comboCount: _controller.comboCount),
                  ),
                ),

              // ── Level complete overlay ────────────────────────────────
              if (_controller.state == GameState.levelComplete)
                LevelCompleteOverlay(
                  score: _controller.score,
                  stars: _controller.stars,
                  coinsEarned: _controller.coinsEarned,
                  maxCombo: _controller.maxComboThisLevel,
                  onContinue: () {
                    _startLevel(widget.level + 1);
                  },
                ),

              // ── Game over overlay ─────────────────────────────────────
              if (_controller.state == GameState.gameOver)
                GameOverOverlay(
                  score: _controller.score,
                  onRetry: () => _startLevel(widget.level),
                  onQuit: _onBack,
                ),

              // ── Pause overlay ─────────────────────────────────────────
              if (_controller.state == GameState.paused)
                _PauseOverlay(
                  onResume: _controller.togglePause,
                  onRestart: () => _startLevel(widget.level),
                  onQuit: _onBack,
                ),
            ],
          ),
        ),
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
              color: GameColors.neonCyan.withAlpha(120),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DURAKLADI',
                style: TextStyle(
                  color: GameColors.neonCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
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
