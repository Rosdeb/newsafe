import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/app_lifecycle_socket_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferader/controller/localizations/localization_controller.dart';
import 'package:saferader/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Get.put(LocalizationController(sharedPreferences: prefs), permanent: true);
    await tester.pumpWidget(const MyApp(
      lifecycleHandler: null,
      languages: {},

    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
