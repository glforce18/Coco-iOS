import 'package:flutter_test/flutter_test.dart';
import 'package:patpat_game/models/cell.dart';
import 'package:patpat_game/models/enums.dart';

void main() {
  group('Cell', () {
    test('empty cell has no jelly', () {
      const cell = Cell(row: 0, col: 0);
      expect(cell.isEmpty, isTrue);
      expect(cell.hasJelly, isFalse);
    });

    test('cell with jelly is not empty', () {
      const cell = Cell(row: 0, col: 0, jellyType: JellyType.purple);
      expect(cell.isEmpty, isFalse);
      expect(cell.hasJelly, isTrue);
    });

    test('ice cell can match', () {
      const cell = Cell(
        row: 0,
        col: 0,
        jellyType: JellyType.blue,
        obstacle: ObstacleType.ice1,
      );
      expect(cell.canMatch, isTrue);
    });

    test('chained cell cannot match', () {
      const cell = Cell(
        row: 0,
        col: 0,
        jellyType: JellyType.green,
        obstacle: ObstacleType.chain1,
      );
      expect(cell.canMatch, isFalse);
      expect(cell.isChained, isTrue);
    });

    test('box cell is blocked', () {
      const cell = Cell(
        row: 0,
        col: 0,
        jellyType: JellyType.pink,
        obstacle: ObstacleType.box,
      );
      expect(cell.isBlocked, isTrue);
      expect(cell.canMatch, isFalse);
    });

    test('bubble cell detected', () {
      const cell = Cell(
        row: 1,
        col: 2,
        obstacle: ObstacleType.bubble,
      );
      expect(cell.isBubble, isTrue);
      expect(cell.isIceWall, isFalse);
    });

    test('iceWall is not empty', () {
      const cell = Cell(
        row: 0,
        col: 0,
        obstacle: ObstacleType.iceWall,
      );
      // iceWall has no jelly and obstacle is non-none, so isEmpty = false
      expect(cell.isEmpty, isFalse);
      expect(cell.isIceWall, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const original = Cell(
        row: 2,
        col: 3,
        jellyType: JellyType.orange,
        specialType: SpecialType.bomb,
        obstacle: ObstacleType.ice1,
        isMatched: false,
      );
      final copy = original.copyWith(isMatched: true);
      expect(copy.row, equals(2));
      expect(copy.col, equals(3));
      expect(copy.jellyType, equals(JellyType.orange));
      expect(copy.specialType, equals(SpecialType.bomb));
      expect(copy.obstacle, equals(ObstacleType.ice1));
      expect(copy.isMatched, isTrue);
    });

    test('copyWith clearJelly removes jelly', () {
      const original = Cell(
        row: 0,
        col: 0,
        jellyType: JellyType.yellow,
      );
      final cleared = original.copyWith(clearJelly: true);
      expect(cleared.jellyType, isNull);
      expect(cleared.isEmpty, isTrue);
    });
  });
}
