import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saferader/Service/Firebase/notifications.dart';
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/controller/networkService/networkService.dart';
import 'package:saferader/helpers/route.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  TokenService().init();
  await NotificationService.initialize();
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
  await dotenv.load(fileName: ".env");
  final box = await Hive.openBox('userBox');
  final savedRole = box.get('role', defaultValue: 'seeker');
  Get.put(NetworkController());
  final userController = UserController();
  userController.userRole.value = savedRole;
  Get.put(userController, permanent: true);
  await checkAndRefreshToken();
  runApp(const MyApp());

}

Future<void> checkAndRefreshToken() async {
  final token =await TokenService().getToken();

  if (token == null) {
    print('No token found, user needs login');
    return;
  }

  if (isTokenValid(token)) {
    print('Token is valid, nothing to do!');
  } else {
    print('Token expired, refreshing...');
    final bool success = await AuthService.refreshToken();
    if (success) {
      print('Token refreshed successfully');
    } else {
      print('Refresh failed, user must login again');
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
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor:const Color(0xFF202020)),
        fontFamily: "Roboto",
      ),
      getPages: AppRoutes.page,
      initialRoute: AppRoutes.splashScreen,
    );
  }
}

