import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferader/helpers/app_translations.dart';
import 'package:saferader/helpers/di.dart';
import 'package:saferader/helpers/route.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import 'utils/app_lifecycle_socket_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  final translationsMap = await loadTranslationMaps();
  final localeCode = prefs.getString(AppConstants.LANGUAGE_CODE) ?? 'en';
  final countryCode = prefs.getString(AppConstants.COUNTRY_CODE) ?? 'US';
  final initialLocale = Locale(localeCode, countryCode);

  final lifecycleHandler = AppLifecycleSocketHandler();
  WidgetsBinding.instance.addObserver(lifecycleHandler);

  runApp(MyApp(
    lifecycleHandler: lifecycleHandler,
    translationsMap: translationsMap,
    initialLocale: initialLocale,
  ));
}

Future<void> checkAndRefreshToken() async {
  final token =await TokenService().getToken();
  if (token == null) {
    Logger.log('No token found, user needs login');
    return;
  }
  if (isTokenValid(token)) {
    Logger.log('Token is valid, nothing to do!');
  } else {
    Logger.log('Token expired, refreshing...');
    final bool success = await AuthService.refreshToken();
    if (success) {
      Logger.log('Token refreshed successfully');
    } else {
      Logger.log('Refresh failed, user must login again');
      await TokenService().clearAll();
    }
  }
}

bool isTokenValid(String? token) {
  if (token == null) return false;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );

    final exp = payload['exp'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return exp > now;
  }on Exception catch (e) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  final AppLifecycleSocketHandler? lifecycleHandler;
  final Map<String, Map<String, String>> translationsMap;
  final Locale initialLocale;

  const MyApp({
    Key? key,
    this.lifecycleHandler,
    required this.translationsMap,
    required this.initialLocale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saferadar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF202020)),
        fontFamily: "Roboto",
      ),
      translations: [AppTranslations(translationsMap)],
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppRoutes.page,
      initialRoute: AppRoutes.splashScreen,
    );
  }
}

