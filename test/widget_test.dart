import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patpat_game/main.dart';

void main() {
  testWidgets('PatPatApp renders loading text', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatPatApp()));
    expect(find.text('PatPat - Loading...'), findsOneWidget);
  });
}
