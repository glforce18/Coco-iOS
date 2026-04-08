import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';

void main() {
  testWidgets('PatPatApp renders with router and shows MainMenuScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatPatApp()));
    // Use pump with duration instead of pumpAndSettle because the menu has
    // a looping shimmer animation that never settles.
    await tester.pump(const Duration(milliseconds: 500));
    // Initial route is /menu which shows the main menu with title and play button
    expect(find.text('PatPat'), findsOneWidget);
    expect(find.text('OYNA!'), findsOneWidget);
  });
}
