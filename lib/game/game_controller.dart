import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:patpat_game/audio/sound_manager.dart';
import 'package:patpat_game/engine/hint_engine.dart';
import 'package:patpat_game/engine/match_engine.dart';
import 'package:patpat_game/engine/obstacle_engine.dart';
import 'package:patpat_game/engine/special_engine.dart';
import 'package:patpat_game/game/board_animator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/models/score.dart';
import 'package:patpat_game/widgets/special_effects_overlay.dart';

/// Orchestrates the match-3 game loop: selection, swap, cascade,
/// boosters, hints, goals, and win/lose conditions.
class GameController extends ChangeNotifier {
  // ─── Animation layer ────────────────────────────────────────────
  final BoardAnimator animator = BoardAnimator();
  double _cellSize = 40;
  double _cellGap = 3;

  /// Called by the GameBoard once it knows the cell dimensions.
  void setCellMetrics(double cellSize, double gap) {
    _cellSize = cellSize;
    _cellGap = gap;
  }

  // ─── State fields ────────────────────────────────────────────────
  GameGrid _grid = GameGrid(rows: 9, cols: 7);
  LevelConfig _config = LevelConfig(
    levelNumber: 0,
    maxMoves: 0,
    goals: [],
    region: GameRegion.candyGarden,
    targetScore: 0,
  );
  GameState _state = GameState.idle;
  int _score = 0;
  int _movesLeft = 0;
  int _comboCount = 0;
  int _maxComboThisLevel = 0;
  int _timeLeft = 0;
  Position? _selectedCell;
  (Position, Position)? _hintPositions;
  Timer? _hintTimer;
  Timer? _countdownTimer;
  ActiveBoosterMode _boosterMode = ActiveBoosterMode.none;
  List<LevelGoal> _goals = [];

  /// Fired when a booster's effect actually applies to the board (or, in the
  /// case of extraMoves, when activated). The screen layer wires this to
  /// PlayerProgressNotifier.consumeBooster so the user's count decrements.
  void Function(BoosterType type)? onBoosterUsed;

  /// Fired whenever score increases. Game screen renders floating "+N"
  /// labels at the centroid of the affected positions.
  /// [center] is in row/col grid space — board widget translates to pixels.
  void Function(int delta, Position center)? onScorePopup;

  /// Fired on visually impactful events that warrant a screen shake.
  /// [intensity] in 0..1 scale (0.3 = small combo, 1.0 = big bomb).
  void Function(double intensity)? onScreenShake;

  // ─── Public getters ──────────────────────────────────────────────
  GameGrid get grid => _grid;
  LevelConfig get config => _config;
  GameState get state => _state;
  int get score => _score;
  int get movesLeft => _movesLeft;
  int get comboCount => _comboCount;
  int get maxComboThisLevel => _maxComboThisLevel;
  int get timeLeft => _timeLeft;
  Position? get selectedCell => _selectedCell;
  (Position, Position)? get hintPositions => _hintPositions;
  ActiveBoosterMode get boosterMode => _boosterMode;
  List<LevelGoal> get goals => _goals;

  int get stars => ScoreCalculator.starsForScore(_score, _config.targetScore);
  int get coinsEarned =>
      ScoreCalculator.coinsForLevel(_config.levelNumber, stars);
  bool get allGoalsComplete => _goals.every((g) => g.isComplete);

  // ─── 1. startLevel ───────────────────────────────────────────────

  /// Resets all state and initialises the grid for the given level.
  void startLevel(LevelConfig config) {
    _config = config;
    _score = 0;
    _movesLeft = config.maxMoves;
    _comboCount = 0;
    _maxComboThisLevel = 0;
    _timeLeft = config.timeLimit;
    _selectedCell = null;
    _hintPositions = null;
    _boosterMode = ActiveBoosterMode.none;
    _goals = config.goals.map((g) => g.copyReset()).toList();

    // Create grid and place obstacles
    _grid = GameGrid(rows: config.rows, cols: config.cols);
    for (final entry in config.obstacles.entries) {
      final pos = entry.key;
      final obstacle = entry.value;
      if (pos.isValid(config.rows, config.cols)) {
        final cell = _grid.get(pos.row, pos.col);
        _grid.set(pos.row, pos.col, cell.copyWith(obstacle: obstacle));
      }
    }

    // Fill empty cells with random jellies and remove initial matches
    MatchEngine.fillEmpty(_grid, config.availableTypes);
    MatchEngine.ensureNoInitialMatches(_grid, config.availableTypes);

    // Start countdown timer for timed levels
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (config.timeLimit > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_state == GameState.paused) return;
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _countdownTimer?.cancel();
          _countdownTimer = null;
          _state = GameState.gameOver;
        }
        notifyListeners();
      });
    }

    animator.clearAll();
    animator.endSkipMode();
    _state = GameState.idle;
    _resetHintTimer();
    notifyListeners();
  }

  // ─── 2. onCellTapped ────────────────────────────────────────────

  /// Handles a tap on a grid cell.
  void onCellTapped(Position pos) {
    if (!pos.isValid(_grid.rows, _grid.cols)) return;

    if (_state == GameState.boosterActive) {
      _onBoosterCellTapped(pos);
      return;
    }

    if (_state != GameState.idle) return;

    if (_selectedCell == null) {
      // Nothing selected — select this cell
      _selectedCell = pos;
      _hintPositions = null;
      notifyListeners();
    } else if (_selectedCell == pos) {
      // Tapped same cell — deselect
      _selectedCell = null;
      notifyListeners();
    } else if (_selectedCell!.isAdjacentTo(pos)) {
      // Adjacent cell — attempt swap
      _attemptSwap(_selectedCell!, pos);
    } else {
      // Non-adjacent — reselect
      _selectedCell = pos;
      _hintPositions = null;
      notifyListeners();
    }
  }

  // ─── 3. onSwipeTo ──────────────────────────────────────────────

  /// Handles a swipe gesture from a cell in a direction.
  void onSwipeTo(Position from, SwapDirection direction) {
    if (_state != GameState.idle) return;

    final target = Position.fromDirection(from, direction);
    if (!target.isValid(_grid.rows, _grid.cols)) return;

    _attemptSwap(from, target);
  }

  // ─── 4. _attemptSwap ───────────────────────────────────────────

  Future<void> _attemptSwap(Position pos1, Position pos2) async {
    _selectedCell = null;
    _hintPositions = null;
    _cancelHintTimer();

    final c1 = _grid.get(pos1.row, pos1.col);
    final c2 = _grid.get(pos2.row, pos2.col);

    // Reject chained cells
    if (c1.isChained || c2.isChained) {
      notifyListeners();
      return;
    }

    // Allow swap if either cell is special, or it is a valid match swap
    final hasSpecial =
        c1.specialType != SpecialType.none ||
        c2.specialType != SpecialType.none;

    if (hasSpecial || MatchEngine.isValidSwap(_grid, pos1, pos2)) {
      await _performSwapAndProcess(pos1, pos2);
    } else {
      // Invalid swap — animate slide to target, then slide back
      _state = GameState.swapping;
      notifyListeners();
      await animator.animateInvalidSwap(pos1, pos2, _cellSize, _cellGap);
      _state = GameState.idle;
      _resetHintTimer();
      notifyListeners();
    }
  }

  // ─── 5. _performSwapAndProcess ─────────────────────────────────

  Future<void> _performSwapAndProcess(Position pos1, Position pos2) async {
    _state = GameState.swapping;
    _comboCount = 0;
    _movesLeft--;
    notifyListeners();

    // Animate the swap visually BEFORE modifying the grid
    SoundManager.instance.play(SoundManager.swap, volume: 0.5);
    await animator.animateSwap(pos1, pos2, _cellSize, _cellGap, durationMs: 200);
    MatchEngine.swap(_grid, pos1, pos2);
    notifyListeners();

    // Check for special combos
    final c1 = _grid.get(pos1.row, pos1.col);
    final c2 = _grid.get(pos2.row, pos2.col);
    final s1 = c1.specialType;
    final s2 = c2.specialType;

    List<ExplosionEffect>? specialEffects;
    SpecialEffectType? effectType;
    Position effectOrigin = pos1;

    if (s1 != SpecialType.none && s2 != SpecialType.none) {
      effectType = _getComboEffectType(s1, s2);
      specialEffects = SpecialEngine.activateSpecialCombo(_grid, pos1, pos2);
      _updateGoalsFromEffects(specialEffects);
    } else if (s1 != SpecialType.none) {
      effectType = _getSpecialEffectType(s1);
      specialEffects = SpecialEngine.activateSpecial(_grid, pos1, c2.jellyType);
      _updateGoalsFromEffects(specialEffects);
      effectOrigin = pos1;
    } else if (s2 != SpecialType.none) {
      effectType = _getSpecialEffectType(s2);
      specialEffects = SpecialEngine.activateSpecial(_grid, pos2, c1.jellyType);
      _updateGoalsFromEffects(specialEffects);
      effectOrigin = pos2;
    }

    // If a special was activated, play the spectacular overlay effect,
    // then run gravity + fill so cleared cells don't leave empty holes.
    if (specialEffects != null && specialEffects.isNotEmpty) {
      final specialScore = specialEffects.length * 15;
      _score += specialScore;
      onScorePopup?.call(specialScore, effectOrigin);
      // Big shake for any special activation — bombs and rainbows shouldn't
      // feel like a swap.
      onScreenShake?.call(
        effectType == SpecialEffectType.bombBlast ||
                effectType == SpecialEffectType.megaBomb
            ? 0.5
            : 0.3,
      );

      final targetPositions =
          specialEffects.map((e) => e.position).toList();

      // Determine effect duration based on type
      final durationMs = switch (effectType) {
        SpecialEffectType.rainbowWave => 500,
        SpecialEffectType.boardClear => 550,
        SpecialEffectType.lightningStrike => 400,
        SpecialEffectType.multiBeam => 450,
        _ => 400,
      };

      // Play the spectacular overlay effect
      notifyListeners();
      if (effectType != null) {
        await animator.playSpecialEffect(SpecialEffect(
          type: effectType,
          origin: effectOrigin,
          targets: targetPositions,
          durationMs: durationMs,
        ));
      } else {
        // Fallback to simple flash for unknown types
        await animator.animateSpecialActivation(targetPositions,
            durationMs: 300);
      }

      // Gravity: let remaining jellies fall into empty cells
      _state = GameState.falling;
      final fallMoves = MatchEngine.applyGravity(_grid);
      notifyListeners();
      if (fallMoves.isNotEmpty) {
        await animator.animateFall(fallMoves, _cellSize, _cellGap,
            durationMs: 250);
      }

      // Refill: spawn new jellies in the remaining empty cells
      _state = GameState.refilling;
      final newPositions =
          MatchEngine.fillEmpty(_grid, _config.availableTypes);
      notifyListeners();
      if (newPositions.isNotEmpty) {
        await animator.animateAppear(newPositions, _cellSize, _cellGap,
            durationMs: 250);
      }
    }

    // Spread chocolate (happens once per move, before cascade)
    ObstacleEngine.spreadChocolate(_grid);

    // Process any chain reactions from the new board configuration
    await _processMatchChain(specialEffects != null ? null : pos1);
  }

  // ─── 6. _processMatchChain ─────────────────────────────────────

  Future<void> _processMatchChain(Position? swapPos) async {
    for (int iteration = 0; iteration < 20; iteration++) {
      final snapshot = _grid.snapshot();
      final matches = MatchEngine.findMatches(snapshot);
      if (matches.isEmpty) break;

      _comboCount++;
      if (_comboCount > _maxComboThisLevel) {
        _maxComboThisLevel = _comboCount;
      }

      // Calculate score for this iteration
      for (final match in matches) {
        final matchScore = (match.positions.length *
                10 *
                pow(1.5, _comboCount - 1))
            .toInt();
        _score += matchScore;
        // Centroid for floating "+N" popup.
        final cx = match.positions.fold<double>(0, (a, p) => a + p.col) /
            match.positions.length;
        final cy = match.positions.fold<double>(0, (a, p) => a + p.row) /
            match.positions.length;
        onScorePopup?.call(matchScore, Position(cy.round(), cx.round()));

        // Mega match bonus
        if (match.positions.length >= 7) {
          final bonus = 50 * (match.positions.length - 6);
          _score += bonus;
          onScorePopup?.call(bonus, Position(cy.round(), cx.round()));
        }

        // Only the biggest match shakes; 4-match no longer triggers any
        // shake (was too jittery on cascade boards).
        if (match.positions.length >= 5) {
          onScreenShake?.call(0.35);
        }
      }

      // Determine which positions will get a special spawned —
      // these must NOT be destroyed visually.
      final spawnPositions = MatchEngine.getSpawnPositions(matches, swapPos);

      // Destroying phase — animate matched cells with pop + fade,
      // but exclude spawn positions so the new special stays visible.
      _state = GameState.destroying;
      final explosionPositions = <Position>[];
      for (final match in matches) {
        for (final pos in match.positions) {
          if (!spawnPositions.contains(pos)) {
            explosionPositions.add(pos);
          }
        }
      }
      notifyListeners();
      // Brief pre-destroy golden flash so the player sees what's matching.
      // Skip for the very first chain after a swap to avoid double-flashing
      // the swap-to-match transition.
      if (_comboCount > 1 || swapPos == null) {
        await animator.animatePreMatchGlow(explosionPositions, durationMs: 65);
      }
      // Play match SFX — combo tone for chains, regular pop otherwise.
      if (_comboCount >= 2) {
        SoundManager.instance.play(SoundManager.combo, volume: 0.6);
      } else {
        SoundManager.instance.play(SoundManager.pop, volume: 0.55);
      }
      await animator.animateDestroy(explosionPositions, durationMs: 200);

      MatchEngine.removeMatches(_grid, matches, swapPos);
      _updateGoalsFromMatches(matches);

      // Animate + sound when a new special is spawned (4/5/6+ matches).
      if (spawnPositions.isNotEmpty) {
        SoundManager.instance.play(SoundManager.special, volume: 0.7);
        notifyListeners();
        await animator.animateSpecialSpawn(spawnPositions.toList(), durationMs: 300);
      }

      // Obstacle interactions
      ObstacleEngine.checkBoxes(_grid, explosionPositions);
      ObstacleEngine.damageAdjacentChains(_grid, explosionPositions);
      ObstacleEngine.damageAdjacentChocolates(_grid, explosionPositions);
      notifyListeners();

      // Falling phase — animate gravity with bounce
      _state = GameState.falling;
      final fallMoves = MatchEngine.applyGravity(_grid);
      notifyListeners();
      if (fallMoves.isNotEmpty) {
        await animator.animateFall(fallMoves, _cellSize, _cellGap, durationMs: 250);
      }

      // Refilling phase — animate new jellies sliding in from above
      _state = GameState.refilling;
      final newPositions = MatchEngine.fillEmpty(_grid, _config.availableTypes);
      notifyListeners();
      if (newPositions.isNotEmpty) {
        await animator.animateAppear(newPositions, _cellSize, _cellGap, durationMs: 250);
      }

      // After first iteration, swapPos is no longer relevant
      swapPos = null;
    }

    _checkGameStatus();
    _resetHintTimer();
    notifyListeners();
  }

  // ─── 7. _updateGoalsFromMatches ────────────────────────────────

  void _updateGoalsFromMatches(List<Match> matches) {
    for (final match in matches) {
      for (final goal in _goals) {
        if (goal.goalType == GoalType.collectJelly &&
            goal.jellyType == match.jellyType) {
          goal.collected += match.positions.length;
        }
      }
    }
  }

  // ─── 8. _updateGoalsFromEffects ────────────────────────────────

  void _updateGoalsFromEffects(List<ExplosionEffect> effects) {
    for (final effect in effects) {
      for (final goal in _goals) {
        if (goal.goalType == GoalType.collectJelly &&
            goal.jellyType == effect.jellyType) {
          goal.collected += 1;
        }
      }
    }
  }

  // ─── Special effect type mapping ────────────────────────────────

  /// Map a single special type to its visual effect type.
  static SpecialEffectType _getSpecialEffectType(SpecialType s) {
    return switch (s) {
      SpecialType.rocketHorizontal => SpecialEffectType.rocketHorizontal,
      SpecialType.rocketVertical => SpecialEffectType.rocketVertical,
      SpecialType.bomb => SpecialEffectType.bombBlast,
      SpecialType.rainbow => SpecialEffectType.rainbowWave,
      SpecialType.lightning => SpecialEffectType.lightningStrike,
      SpecialType.none => SpecialEffectType.bombBlast, // should not happen
    };
  }

  /// Map a combo of two special types to the visual effect type.
  static SpecialEffectType _getComboEffectType(
      SpecialType s1, SpecialType s2) {
    final isRocket1 =
        s1 == SpecialType.rocketHorizontal || s1 == SpecialType.rocketVertical;
    final isRocket2 =
        s2 == SpecialType.rocketHorizontal || s2 == SpecialType.rocketVertical;

    // rainbow + rainbow
    if (s1 == SpecialType.rainbow && s2 == SpecialType.rainbow) {
      return SpecialEffectType.boardClear;
    }
    // bomb + bomb
    if (s1 == SpecialType.bomb && s2 == SpecialType.bomb) {
      return SpecialEffectType.megaBomb;
    }
    // rocket + rocket
    if (isRocket1 && isRocket2) {
      return SpecialEffectType.rocketCross;
    }
    // rocket + bomb or bomb + rocket
    if ((isRocket1 && s2 == SpecialType.bomb) ||
        (s1 == SpecialType.bomb && isRocket2)) {
      return SpecialEffectType.multiBeam;
    }
    // rainbow + any
    if (s1 == SpecialType.rainbow || s2 == SpecialType.rainbow) {
      return SpecialEffectType.rainbowWave;
    }
    // Fallback: use first special's effect
    return _getSpecialEffectType(s1);
  }

  // ─── 9. _checkGameStatus ───────────────────────────────────────

  void _checkGameStatus() {
    if (allGoalsComplete) {
      _state = GameState.levelComplete;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      SoundManager.instance.play(SoundManager.success, volume: 0.8);
      return;
    }

    if (_movesLeft <= 0) {
      _state = GameState.gameOver;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      SoundManager.instance.play(SoundManager.fail, volume: 0.7);
      return;
    }

    _state = GameState.idle;
    animator.endSkipMode();
  }

  /// Tell the animator to fast-forward all running + pending animations.
  /// The cascade resolves logically the same way, just visually instantly.
  void skipCascade() {
    animator.requestSkip();
  }

  // ─── 9b. addExtraMoves (from rewarded ad) ──────────────────────

  /// Add extra moves when the player watches a rewarded ad after game over.
  void addExtraMoves(int count) {
    if (_state == GameState.gameOver) {
      _movesLeft += count;
      _state = GameState.idle;
      _resetHintTimer();
      notifyListeners();
    }
  }

  // ─── 10. togglePause ───────────────────────────────────────────

  void togglePause() {
    if (_state == GameState.idle) {
      _state = GameState.paused;
      notifyListeners();
    } else if (_state == GameState.paused) {
      _state = GameState.idle;
      _resetHintTimer();
      notifyListeners();
    }
  }

  // ─── 11. activateBooster ───────────────────────────────────────

  void activateBooster(BoosterType type) {
    switch (type) {
      case BoosterType.extraMoves:
        _movesLeft += 3;
        onBoosterUsed?.call(BoosterType.extraMoves);
        notifyListeners();
      case BoosterType.hammer:
        _boosterMode = ActiveBoosterMode.hammerSelect;
        _state = GameState.boosterActive;
        notifyListeners();
      case BoosterType.colorBlast:
        _boosterMode = ActiveBoosterMode.colorBlastSelect;
        _state = GameState.boosterActive;
        notifyListeners();
    }
  }

  // ─── 12. cancelBooster ─────────────────────────────────────────

  void cancelBooster() {
    _boosterMode = ActiveBoosterMode.none;
    _state = GameState.idle;
    notifyListeners();
  }

  // ─── Booster cell tap handler ──────────────────────────────────

  void _onBoosterCellTapped(Position pos) {
    if (!pos.isValid(_grid.rows, _grid.cols)) return;

    switch (_boosterMode) {
      case ActiveBoosterMode.hammerSelect:
        _useHammer(pos);
      case ActiveBoosterMode.colorBlastSelect:
        final cell = _grid.get(pos.row, pos.col);
        if (cell.jellyType != null) {
          _useColorBlast(cell.jellyType!);
        }
      case ActiveBoosterMode.none:
        break;
    }
  }

  // ─── 13. _useHammer ────────────────────────────────────────────

  Future<void> _useHammer(Position pos) async {
    _boosterMode = ActiveBoosterMode.none;
    _state = GameState.destroying;
    onBoosterUsed?.call(BoosterType.hammer);
    notifyListeners();

    // Realistic hammer animation: swing in from top-left + impact burst at
    // tap target. Wait for the swing to land before clearing the cell.
    await animator.playSpecialEffect(SpecialEffect(
      type: SpecialEffectType.hammerSmash,
      origin: pos,
      targets: const [],
      durationMs: 650,
    ));

    final cell = _grid.get(pos.row, pos.col);
    _grid.set(
      pos.row,
      pos.col,
      cell.copyWith(
        clearJelly: true,
        specialType: SpecialType.none,
        obstacle: ObstacleType.none,
      ),
    );
    _score += 20;
    onScorePopup?.call(20, pos);
    _grid.bumpVersion();
    notifyListeners();

    MatchEngine.applyGravity(_grid);
    MatchEngine.fillEmpty(_grid, _config.availableTypes);
    notifyListeners();

    await _processMatchChain(null);
  }

  // ─── 14. _useColorBlast ────────────────────────────────────────

  Future<void> _useColorBlast(JellyType type) async {
    _boosterMode = ActiveBoosterMode.none;
    _state = GameState.destroying;
    onBoosterUsed?.call(BoosterType.colorBlast);
    notifyListeners();

    // Collect all targets first (cells of the selected color), play a
    // radial sweep animation, THEN clear them. Origin = tapped cell of
    // that color (use first found as fallback).
    final targets = <Position>[];
    Position? origin;
    for (int r = 0; r < _grid.rows; r++) {
      for (int c = 0; c < _grid.cols; c++) {
        if (_grid.get(r, c).jellyType == type) {
          final pos = Position(r, c);
          targets.add(pos);
          origin ??= pos;
        }
      }
    }
    if (origin != null) {
      await animator.playSpecialEffect(SpecialEffect(
        type: SpecialEffectType.colorSweep,
        origin: origin,
        targets: targets,
        targetColor: type,
        durationMs: 750,
      ));
    }

    int count = 0;
    for (final pos in targets) {
      final cell = _grid.get(pos.row, pos.col);
      _grid.set(
        pos.row,
        pos.col,
        cell.copyWith(clearJelly: true, specialType: SpecialType.none),
      );
      count++;
    }
    final blastScore = count * 15;
    _score += blastScore;
    if (count > 0) {
      onScorePopup?.call(blastScore, Position(_grid.rows ~/ 2, _grid.cols ~/ 2));
      onScreenShake?.call(0.4);
    }
    _grid.bumpVersion();
    notifyListeners();

    MatchEngine.applyGravity(_grid);
    MatchEngine.fillEmpty(_grid, _config.availableTypes);
    notifyListeners();

    await _processMatchChain(null);
  }

  // ─── 15. _resetHintTimer ───────────────────────────────────────

  void _resetHintTimer() {
    _cancelHintTimer();
    _hintPositions = null;
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (_state == GameState.idle) {
        final hint = HintEngine.findHint(_grid);
        if (hint != null) {
          _hintPositions = hint;
          notifyListeners();
        }
      }
    });
  }

  void _cancelHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  // ─── 19. dispose ───────────────────────────────────────────────

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    animator.dispose();
    super.dispose();
  }
}
