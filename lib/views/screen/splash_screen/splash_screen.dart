import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saferader/utils/app_icon.dart';
import 'package:saferader/utils/app_image.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:saferader/views/screen/welcome/welcome_sreen.dart';
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
    Future.delayed(
        const Duration(seconds: 3),()async{
          final token = await TokenService().getToken();
          if(!mounted)
            return;
          if (token != null && token.isNotEmpty){
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder)=>BottomMenuWrappers()), (route)=> false);
          }else{
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder)=>WelcomeSreen()), (route)=> false);
          }
    });
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
