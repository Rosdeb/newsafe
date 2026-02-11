import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Language/language_model.dart';
import '../controller/localizations/localization_controller.dart';
import '../utils/app_constant.dart';

/// Loads translation maps for all languages in [AppConstants.languages].
/// Does not register any GetX dependencies. Used by main.dart before runApp.
Future<Map<String, Map<String, String>>> loadTranslationMaps() async {
  final Map<String, Map<String, String>> languages = {};
  for (final languageModel in AppConstants.languages) {
    final jsonStringValues = await rootBundle.loadString(
      'assets/language/${languageModel.languageCode}.json',
    );
    final mappedJson = json.decode(jsonStringValues) as Map<String, dynamic>;
    final stringMap = <String, String>{};
    mappedJson.forEach((key, value) {
      stringMap[key] = value.toString();
    });
    languages['${languageModel.languageCode}_${languageModel.countryCode}'] =
        stringMap;
  }
  return languages;
}

Future<Map<String, Map<String, String>>> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.lazyPut(() => sharedPreferences);
  Get.put(LocalizationController(sharedPreferences: Get.find()));

  return loadTranslationMaps();
}