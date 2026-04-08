import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:patpat_game/engine/hint_engine.dart';
import 'package:patpat_game/engine/match_engine.dart';
import 'package:patpat_game/engine/obstacle_engine.dart';
import 'package:patpat_game/engine/special_engine.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/game_grid.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/position.dart';
import 'package:patpat_game/models/score.dart';

/// Orchestrates the match-3 game loop: selection, swap, cascade,
/// boosters, hints, goals, and win/lose conditions.
class GameController extends ChangeNotifier {
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
      // Invalid swap — animate swap and swap back
      _state = GameState.swapping;
      MatchEngine.swap(_grid, pos1, pos2);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      MatchEngine.swap(_grid, pos1, pos2);
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

    MatchEngine.swap(_grid, pos1, pos2);
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Check for special combos
    final c1 = _grid.get(pos1.row, pos1.col);
    final c2 = _grid.get(pos2.row, pos2.col);
    final s1 = c1.specialType;
    final s2 = c2.specialType;

    if (s1 != SpecialType.none && s2 != SpecialType.none) {
      final effects = SpecialEngine.activateSpecialCombo(_grid, pos1, pos2);
      _updateGoalsFromEffects(effects);
    } else if (s1 != SpecialType.none) {
      final effects = SpecialEngine.activateSpecial(_grid, pos1, c2.jellyType);
      _updateGoalsFromEffects(effects);
    } else if (s2 != SpecialType.none) {
      final effects = SpecialEngine.activateSpecial(_grid, pos2, c1.jellyType);
      _updateGoalsFromEffects(effects);
    }

    // Spread chocolate (happens once per move, before cascade)
    ObstacleEngine.spreadChocolate(_grid);

    await _processMatchChain(pos1);
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

        // Mega match bonus
        if (match.positions.length >= 7) {
          _score += 50 * (match.positions.length - 6);
        }
      }

      // Destroying phase
      _state = GameState.destroying;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 85));

      // Collect explosion positions for obstacle interaction
      final explosionPositions = <Position>[];
      for (final match in matches) {
        explosionPositions.addAll(match.positions);
      }

      MatchEngine.removeMatches(_grid, matches, swapPos);
      _updateGoalsFromMatches(matches);

      // Obstacle interactions
      ObstacleEngine.checkBoxes(_grid, explosionPositions);
      ObstacleEngine.damageAdjacentChains(_grid, explosionPositions);
      ObstacleEngine.damageAdjacentChocolates(_grid, explosionPositions);

      // Falling phase
      _state = GameState.falling;
      MatchEngine.applyGravity(_grid);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Refilling phase
      _state = GameState.refilling;
      MatchEngine.fillEmpty(_grid, _config.availableTypes);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 100));

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

  // ─── 9. _checkGameStatus ───────────────────────────────────────

  void _checkGameStatus() {
    if (allGoalsComplete) {
      _state = GameState.levelComplete;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }

    if (_movesLeft <= 0) {
      _state = GameState.gameOver;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }

    _state = GameState.idle;
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
    notifyListeners();

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
    notifyListeners();

    int count = 0;
    for (int r = 0; r < _grid.rows; r++) {
      for (int c = 0; c < _grid.cols; c++) {
        final cell = _grid.get(r, c);
        if (cell.jellyType == type) {
          _grid.set(
            r,
            c,
            cell.copyWith(
              clearJelly: true,
              specialType: SpecialType.none,
            ),
          );
          count++;
        }
      }
    }
    _score += count * 15;
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
    super.dispose();
  }
}
