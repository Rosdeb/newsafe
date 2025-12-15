import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saferader/helpers/route.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await TokenService().init();
  // await NotificationService.initialize();
  //
  // // Initialize background location service
  // await BackgroundLocationSocketService.initializeService();
  //
  // final appDir = await getApplicationDocumentsDirectory();
  // Hive.init(appDir.path);
  // await dotenv.load(fileName: ".env");
  // final box = await Hive.openBox('userBox');
  // final savedRole = box.get('role', defaultValue: 'seeker');
  // Get.put(NetworkController());
  // final userController = UserController();
  // userController.userRole.value = savedRole;
  // Get.put(userController, permanent: true);
  // await checkAndRefreshToken();
  runApp(const MyApp());

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

