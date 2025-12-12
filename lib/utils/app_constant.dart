

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants{

  static String APP_NAME="Saferadar";
  static String BASE_URL ="https://itself-initially-wrapping-beer.trycloudflare.com";
  static String get Secret_key => dotenv.env['API_KEY'] ?? '';

  // share preference Key
  static String THEME ="theme";
  static const String fcmToken = '';

  static const String LANGUAGE_CODE = 'language_code';
  static const String COUNTRY_CODE = 'country_code';
  static const String FONT_FAMILY = 'Inter';

  static RegExp emailValidator = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  static RegExp passwordValidator = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"
  );
  // static List<LanguageModel> languages = [
  //   LanguageModel( languageName: 'English', countryCode: 'US', languageCode: 'en'),
  //   LanguageModel(languageName: 'French', countryCode: 'FR', languageCode: 'fr'),
  // ];
}