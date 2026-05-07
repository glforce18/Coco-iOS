import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';
import 'package:patpat_game/widgets/shared/bottom_nav.dart';

void main() {
  testWidgets('PatPatApp renders with router and shows MainMenuScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatPatApp()));
    // Use pump with duration instead of pumpAndSettle because the menu has
    // a looping shimmer animation that never settles.
    await tester.pump(const Duration(milliseconds: 500));
    // Initial route is /menu. The "PatPat" wordmark is now baked into the
    // background PNG (no Text widget), so we verify by checking for the
    // play button label and the bottom nav with the home tab active.
    expect(find.text('OYNA!'), findsOneWidget);
    expect(find.byType(PatPatBottomNav), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}
