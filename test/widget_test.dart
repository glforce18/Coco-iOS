import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';

void main() {
  testWidgets('PatPatApp renders with router and shows MENU placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatPatApp()));
    await tester.pumpAndSettle();
    // Initial route is /menu which shows placeholder text
    expect(find.text('MENU'), findsOneWidget);
  });
}
