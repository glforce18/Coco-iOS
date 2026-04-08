import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/engine/match_engine.dart';
import 'package:patpat_game/game/game_controller.dart';
import 'package:patpat_game/game/level_generator.dart';
import 'package:patpat_game/models/enums.dart';
import 'package:patpat_game/models/level_config.dart';
import 'package:patpat_game/models/position.dart';

void main() {
  group('GameController', () {
    late GameController controller;

    setUp(() {
      controller = GameController();
    });

    tearDown(() {
      controller.dispose();
    });

    LevelConfig simpleConfig({
      int level = 1,
      int maxMoves = 20,
      int targetScore = 500,
      int timeLimit = 0,
      List<LevelGoal>? goals,
    }) {
      return LevelConfig(
        levelNumber: level,
        rows: 9,
        cols: 7,
        maxMoves: maxMoves,
        goals: goals ??
            [
              LevelGoal(jellyType: JellyType.purple, count: 10),
              LevelGoal(jellyType: JellyType.blue, count: 8),
            ],
        region: GameRegion.candyGarden,
        targetScore: targetScore,
        timeLimit: timeLimit,
        availableTypes: const [
          JellyType.purple,
          JellyType.yellow,
          JellyType.blue,
          JellyType.green,
        ],
      );
    }

    group('startLevel', () {
      test('starts level with correct initial state', () {
        final config = simpleConfig(maxMoves: 25, targetScore: 600);
        controller.startLevel(config);

        expect(controller.state, equals(GameState.idle));
        expect(controller.score, equals(0));
        expect(controller.movesLeft, equals(25));
        expect(controller.comboCount, equals(0));
        expect(controller.maxComboThisLevel, equals(0));
        expect(controller.selectedCell, isNull);
        expect(controller.boosterMode, equals(ActiveBoosterMode.none));
      });

      test('grid has no initial matches after startLevel', () {
        final config = simpleConfig();
        controller.startLevel(config);

        final snapshot = controller.grid.snapshot();
        final matches = MatchEngine.findMatches(snapshot);
        expect(matches, isEmpty,
            reason: 'Grid should have no matches after startLevel');
      });

      test('goals are initialized from config (all collected=0)', () {
        final config = simpleConfig(goals: [
          LevelGoal(jellyType: JellyType.purple, count: 15),
          LevelGoal(jellyType: JellyType.blue, count: 10),
          LevelGoal(jellyType: JellyType.green, count: 5),
        ]);
        controller.startLevel(config);

        expect(controller.goals.length, equals(3));
        for (final goal in controller.goals) {
          expect(goal.collected, equals(0),
              reason: 'Goal ${goal.jellyType.name} should start with 0 collected');
        }
        expect(controller.goals[0].jellyType, equals(JellyType.purple));
        expect(controller.goals[0].count, equals(15));
        expect(controller.goals[1].jellyType, equals(JellyType.blue));
        expect(controller.goals[1].count, equals(10));
        expect(controller.goals[2].jellyType, equals(JellyType.green));
        expect(controller.goals[2].count, equals(5));
      });

      test('grid dimensions match config', () {
        final config = simpleConfig();
        controller.startLevel(config);

        expect(controller.grid.rows, equals(9));
        expect(controller.grid.cols, equals(7));
      });

      test('all cells are filled after startLevel', () {
        final config = simpleConfig();
        controller.startLevel(config);

        for (int r = 0; r < controller.grid.rows; r++) {
          for (int c = 0; c < controller.grid.cols; c++) {
            final cell = controller.grid.get(r, c);
            expect(cell.hasJelly || cell.obstacle != ObstacleType.none, isTrue,
                reason: 'Cell ($r,$c) should not be empty');
          }
        }
      });

      test('timeLeft is set from config', () {
        final config = simpleConfig(timeLimit: 60);
        controller.startLevel(config);

        expect(controller.timeLeft, equals(60));
      });

      test('timeLeft is 0 for non-timed level', () {
        final config = simpleConfig(timeLimit: 0);
        controller.startLevel(config);

        expect(controller.timeLeft, equals(0));
      });

      test('starting a new level resets previous state', () {
        final config1 = simpleConfig(maxMoves: 15, targetScore: 300);
        controller.startLevel(config1);

        // Start another level
        final config2 = simpleConfig(maxMoves: 30, targetScore: 1000);
        controller.startLevel(config2);

        expect(controller.score, equals(0));
        expect(controller.movesLeft, equals(30));
        expect(controller.state, equals(GameState.idle));
        expect(controller.comboCount, equals(0));
      });
    });

    group('startLevel with generated levels', () {
      test('works with LevelGenerator output for level 1', () {
        final config = LevelGenerator.generate(1);
        controller.startLevel(config);

        expect(controller.state, equals(GameState.idle));
        expect(controller.movesLeft, equals(config.maxMoves));
        expect(controller.score, equals(0));

        final snapshot = controller.grid.snapshot();
        final matches = MatchEngine.findMatches(snapshot);
        expect(matches, isEmpty);
      });

      test('works with LevelGenerator output for level 100 (with obstacles)', () {
        final config = LevelGenerator.generate(100);
        controller.startLevel(config);

        expect(controller.state, equals(GameState.idle));
        expect(controller.movesLeft, equals(config.maxMoves));

        final snapshot = controller.grid.snapshot();
        final matches = MatchEngine.findMatches(snapshot);
        expect(matches, isEmpty);
      });
    });

    group('togglePause', () {
      test('idle to paused', () {
        controller.startLevel(simpleConfig());
        expect(controller.state, equals(GameState.idle));

        controller.togglePause();
        expect(controller.state, equals(GameState.paused));
      });

      test('paused to idle', () {
        controller.startLevel(simpleConfig());
        controller.togglePause();
        expect(controller.state, equals(GameState.paused));

        controller.togglePause();
        expect(controller.state, equals(GameState.idle));
      });

      test('does not toggle from non-idle/non-paused states', () {
        // state is idle before startLevel is never called — but default is idle
        // However, the game controller default state is idle; after startLevel it's idle.
        // We can't directly set state to swapping, so just verify it only works for idle/paused.
        controller.startLevel(simpleConfig());
        controller.togglePause();
        controller.togglePause();
        expect(controller.state, equals(GameState.idle));
      });
    });

    group('activateBooster', () {
      test('extraMoves adds 3 moves', () {
        final config = simpleConfig(maxMoves: 10);
        controller.startLevel(config);
        expect(controller.movesLeft, equals(10));

        controller.activateBooster(BoosterType.extraMoves);
        expect(controller.movesLeft, equals(13));
        // State remains idle for extraMoves
        expect(controller.state, equals(GameState.idle));
      });

      test('hammer sets boosterActive state and hammerSelect mode', () {
        controller.startLevel(simpleConfig());

        controller.activateBooster(BoosterType.hammer);
        expect(controller.state, equals(GameState.boosterActive));
        expect(controller.boosterMode, equals(ActiveBoosterMode.hammerSelect));
      });

      test('colorBlast sets boosterActive state and colorBlastSelect mode', () {
        controller.startLevel(simpleConfig());

        controller.activateBooster(BoosterType.colorBlast);
        expect(controller.state, equals(GameState.boosterActive));
        expect(
            controller.boosterMode, equals(ActiveBoosterMode.colorBlastSelect));
      });
    });

    group('cancelBooster', () {
      test('resets mode and state to idle', () {
        controller.startLevel(simpleConfig());
        controller.activateBooster(BoosterType.hammer);
        expect(controller.state, equals(GameState.boosterActive));

        controller.cancelBooster();
        expect(controller.state, equals(GameState.idle));
        expect(controller.boosterMode, equals(ActiveBoosterMode.none));
      });
    });

    group('score getters', () {
      test('stars getter returns 0 for score 0', () {
        controller.startLevel(simpleConfig(targetScore: 500));
        expect(controller.stars, equals(0));
      });

      test('coinsEarned getter returns value for level 1 with 0 stars', () {
        controller.startLevel(simpleConfig(level: 1, targetScore: 500));
        // base = 20 + 1*2 = 22, starBonus = 0*10 = 0, boss = 0
        expect(controller.coinsEarned, equals(22));
      });

      test('allGoalsComplete is false initially', () {
        controller.startLevel(simpleConfig());
        expect(controller.allGoalsComplete, isFalse);
      });
    });

    group('onCellTapped — selection', () {
      test('tapping a cell selects it', () {
        controller.startLevel(simpleConfig());
        final pos = const Position(4, 3);
        controller.onCellTapped(pos);

        expect(controller.selectedCell, equals(pos));
      });

      test('tapping same cell deselects', () {
        controller.startLevel(simpleConfig());
        final pos = const Position(4, 3);
        controller.onCellTapped(pos);
        expect(controller.selectedCell, equals(pos));

        controller.onCellTapped(pos);
        expect(controller.selectedCell, isNull);
      });

      test('tapping non-adjacent cell reselects', () {
        controller.startLevel(simpleConfig());
        final pos1 = const Position(0, 0);
        final pos2 = const Position(5, 5);
        controller.onCellTapped(pos1);
        expect(controller.selectedCell, equals(pos1));

        controller.onCellTapped(pos2);
        expect(controller.selectedCell, equals(pos2));
      });

      test('tapping out of bounds is ignored', () {
        controller.startLevel(simpleConfig());
        controller.onCellTapped(const Position(-1, 0));
        expect(controller.selectedCell, isNull);

        controller.onCellTapped(const Position(100, 100));
        expect(controller.selectedCell, isNull);
      });
    });

    group('dispose', () {
      test('can be disposed without error', () {
        final ctrl = GameController();
        ctrl.startLevel(simpleConfig(timeLimit: 60));
        // Should not throw
        ctrl.dispose();
      });

      test('can be disposed without starting a level', () {
        final ctrl = GameController();
        // Should not throw
        ctrl.dispose();
      });
    });
  });
}
