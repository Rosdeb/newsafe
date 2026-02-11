import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/Language/language_model.dart';
import '../../utils/app_constant.dart';

class LocalizationController extends GetxController {
  final SharedPreferences sharedPreferences;

  LocalizationController({required this.sharedPreferences}) {
    loadCurrentLanguage();
  }

  Locale _locale = Locale(AppConstants.languages[0].languageCode, AppConstants.languages[0].countryCode);
  final bool _isLtr = true;
  List<LanguageModel> _languages = [];
  int _selectedIndex = 0;
  /// Trigger incremented when language changes; controllers can listen and refetch language-dependent data.
  final RxInt localeChangeTrigger = 0.obs;
  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  List<LanguageModel> get languages => _languages;
  int get selectedIndex => _selectedIndex;
  void setLanguage(Locale locale) {
    int index = AppConstants.languages.indexWhere((lang) => lang.languageCode == locale.languageCode);

    if (index != -1) {
      _selectedIndex = index;
    }

    _locale = locale;
    Get.updateLocale(locale);
    sharedPreferences.setString(AppConstants.LANGUAGE_CODE, locale.languageCode);
    sharedPreferences.setString(AppConstants.COUNTRY_CODE, locale.countryCode ?? "");
    localeChangeTrigger.value++;
    update();
  }

  void loadCurrentLanguage() {
    String languageCode = sharedPreferences.getString(AppConstants.LANGUAGE_CODE) ??
        AppConstants.languages[0].languageCode;
    String countryCode = sharedPreferences.getString(AppConstants.COUNTRY_CODE) ??
        AppConstants.languages[0].countryCode;

    _locale = Locale(languageCode, countryCode);

    int index = AppConstants.languages.indexWhere((lang) => lang.languageCode == languageCode);
    _selectedIndex = (index != -1) ? index : 0;
    Get.updateLocale(_locale);
    update();
  }


  void saveLanguage(Locale locale) async {
    await sharedPreferences.setString(AppConstants.LANGUAGE_CODE, locale.languageCode);
    await sharedPreferences.setString(AppConstants.COUNTRY_CODE, locale.countryCode ?? '');
  }
  void setSelectIndex(int index) {
    _selectedIndex = index;
    update();
  }

  void searchLanguage(String query) {
    if (query.isEmpty) {
      _languages = AppConstants.languages;
    } else {
      _selectedIndex = -1;
      _languages = AppConstants.languages.where((language) {
        return language.languageName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    update();
  }
}