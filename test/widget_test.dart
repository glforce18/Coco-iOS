import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';

void main() {
  testWidgets('PatPatApp renders GameScreen with level text',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatPatApp()));
    // GameScreen shows "Seviye 1" in the HUD
    expect(find.text('Seviye 1'), findsOneWidget);
  });
}
