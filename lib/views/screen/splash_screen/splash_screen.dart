import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saferader/utils/app_icon.dart';
import 'package:saferader/utils/app_image.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:saferader/views/screen/welcome/welcome_sreen.dart';
import '../../../Service/Firebase/notifications.dart';
import '../../../controller/UserController/userController.dart';
import '../../../controller/networkService/networkService.dart';
import '../../../firebase_options.dart';
import '../../../main.dart';
import '../../../services/background_location_socket_service.dart';
import '../bottom_nav/bottom_nav_wrappers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await TokenService().init();
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    final box = await Hive.openBox('userBox');
    final savedRole = box.get('role', defaultValue: 'seeker');
    Get.put(NetworkController(), permanent: true);
    final userController = UserController();
    userController.userRole.value = savedRole;
    Get.put(userController, permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNonCriticalServices();
    });
    final token = await TokenService().getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => BottomMenuWrappers()),
            (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => WelcomeSreen()),
            (route) => false,
      );
    }
  }

  Future<void> _initNonCriticalServices() async {
    try {
      MobileAds.instance.initialize();
      await NotificationService.initialize();
      await BackgroundLocationSocketService.initializeService();
      await dotenv.load(fileName: ".env");
      final token = await TokenService().getToken();
      if (token != null) await checkAndRefreshToken();
    }on Exception catch (e) {
      debugPrint("Non-critical init failed: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration:const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xff202020), Color(0xff222222)], )
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.2 ,),
                SvgPicture.asset(AppIcons.safe_radar),
                SizedBox(height: size.height * 0.2 ,),
                Image.asset(AppImage.safe_radar_text),
                SizedBox(height: size.height * 0.02 ,),
                const Text("Your Safety Network",style: TextStyle(color: Color(0xFFD7D7D7)),),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
