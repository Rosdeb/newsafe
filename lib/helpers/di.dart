import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Language/language_model.dart';
import '../controller/localizations/localization_controller.dart';
import '../utils/app_constant.dart';




Future<Map<String, Map<String, String>>>  init() async {

  final sharedPreferences = await SharedPreferences.getInstance();
  Get.lazyPut(() => sharedPreferences);

  // Repository
  //Get.lazyPut(() => ThemeController(sharedPreferences: Get.find()));
  Get.put(LocalizationController(sharedPreferences: Get.find()));
  //Get.lazyPut(() => HomeController());

  //Retrieving localized data
  Map<String, Map<String, String>> languages = Map();
  for(LanguageModel languageModel in AppConstants.languages) {
    String jsonStringValues =  await rootBundle.loadString('assets/language/${languageModel.languageCode}.json');
    Map<String, dynamic> _mappedJson = json.decode(jsonStringValues);
    Map<String, String> _json = Map();
    _mappedJson.forEach((key, value) {
      _json[key] = value.toString();
    });
    languages['${languageModel.languageCode}_${languageModel.countryCode}'] = _json;
  }
  return languages;
}