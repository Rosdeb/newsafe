// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saferader/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      translationsMap: const {'en_US': {}},
      initialLocale: const Locale('en', 'US'),
    ));

    // Verify that the app builds (splash or first route is shown).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
