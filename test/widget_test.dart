import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';
import 'package:patpat_game/widgets/tropical/island_bottom_nav.dart';

void main() {
  testWidgets('CocoApp renders with router and shows MainMenuScreen',
      (WidgetTester tester) async {
    // Set a portrait phone-like viewport (390x844 ≈ iPhone 14).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: CocoApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('OYNA'), findsOneWidget);
    expect(find.byType(IslandBottomNav), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}
