import 'package:get/get.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';

import '../views/screen/splash_screen/splash_screen.dart';

class AppRoutes{
  static String splashScreen="/splash_screen";
  static String signInScreen="/signIn_screen";


  static List<GetPage> page =[
    GetPage(name: splashScreen, page: ()=> SplashScreen()),
    GetPage(name: signInScreen, page: ()=> SigninScreen()),

  ];
}