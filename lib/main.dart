import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saferader/utils/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferader/controller/localizations/localization_controller.dart';
import 'package:saferader/helpers/app_translations.dart';
import 'package:saferader/helpers/di.dart';
import 'package:saferader/helpers/route.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import 'helpers/di.dart' as di;
import 'utils/app_lifecycle_socket_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  Get.put(LocalizationController(sharedPreferences: prefs), permanent: true);
  Map<String, Map<String, String>> languages = await di.init();
  final lifecycleHandler = AppLifecycleSocketHandler();
  WidgetsBinding.instance.addObserver(lifecycleHandler);

  runApp(MyApp(
    lifecycleHandler: lifecycleHandler,
    languages: languages,
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
  final Map<String, Map<String, String>> languages;

  const MyApp({
    Key? key,
    this.lifecycleHandler,
    required this.languages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocalizationController>(
      builder: (localizeController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Saferadar',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF202020),
            ),
            fontFamily: "Roboto",
          ),
          locale: localizeController.locale,
          translations: Messages(languages: languages),
          fallbackLocale: Locale(
            AppConstants.languages[0].languageCode,
            AppConstants.languages[0].countryCode,
          ),
          getPages: AppRoutes.page,
          initialRoute: AppRoutes.splashScreen,
        );
      },
    );

  }
}



