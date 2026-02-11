

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../Models/Language/language_model.dart';

class AppConstants{
  static String APP_NAME="Saferadar";
  //http://164.92.215.115:9443/
  //http://164.92.215.115:9548
  static String BASE_URL ="http://164.92.215.115:9548";
  static String get Secret_key => dotenv.env['API_KEY'] ?? '';
  static String get Bennar_ad_Id=> dotenv.env['BANNER_ADS_ID'] ?? '';

  //----===---> share preference Key <----====---//
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

  static List<LanguageModel> languages = [
    LanguageModel( languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(languageName: 'French', countryCode: 'FR', languageCode: 'fr'),
  ];
}