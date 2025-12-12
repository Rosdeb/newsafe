import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:saferader/controller/shareApp/shareApp.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import '../../../help_giver/help_giver_home/giverHome.dart';
import '../base/headers.dart';

class ShareApp extends StatelessWidget {
  ShareApp({super.key});

  final ShareAppController controller = Get.put(ShareAppController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.07),
              Headers(
                iconPath: "assets/icon/Vector.svg",
                title: "Share",
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Container(
                padding:const  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1.2, color: AppColors.colorYellow),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      const AppText("Share with",fontSize: 18,fontWeight: FontWeight.w600,color: AppColors.color2Box,),
                      const Spacer(),
                      SvgPicture.asset("assets/icon/close.svg"),

                    ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconColumn((){
                          controller.openChatSMS();
                        },"assets/icon/comment 1.svg", "Chat"),
                        _buildIconColumn((){
                          controller.openTelegram();
                        },"assets/icon/telegram-alt 1.svg", "Telegram"),

                        _buildIconCircleAvatar((){
                          controller.openTwitter();
                        },"assets/icon/twitter-alt 1.svg", "Twitter"),
                        _buildIconColumn((){
                          controller.openWhatsApp();
                        },"assets/icon/whatsapp 1.svg", "Whatsapp"),
                        _buildIconColumn((){
                          controller.openEmail();
                        },"assets/icon/alternate_email.svg", "E-mail"),
                      ],
                    ),
                    SizedBox(height: size.height * 0.01),
                    AppText("Or share with link",fontSize: 14,fontWeight: FontWeight.w500,color: Color(0xFF333C4A).withOpacity(0.50),),
                    SizedBox(height: size.height * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "https://app.futureconnect.ai/invite/user/9f3b7c1d-e28a-4a7c-bf1d-4d2e9a6c3f70?session=active&ref=join-now&utm_source=invite_link&utm_medium=direct",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333C4A).withOpacity(0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IosTapEffect(
                            onTap: (){
                              Clipboard.setData(
                                const ClipboardData(text: "https://app.futureconnect.ai/invite/user/9f3b7c1d-e28a-4a7c-bf1d-4d2e9a6c3f70?session=active&ref=join-now&utm_source=invite_link&utm_medium=direct"),
                              );

                            },
                            child: Image.asset("assets/image/c8dd7257a8b5e00676273d70373227a536abebb9.png",height: 14,width: 14,)),

                      ],
                    ),
                  ],
                ),
              ),


             const SizedBox(height: 10,),
             const Padding(
                padding:  EdgeInsets.symmetric(horizontal: 18.0),
                child: BannerAds(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildIconColumn(
      VoidCallback ontap,
      String iconPath, String label) {
    return IosTapEffect(
      onTap: ontap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(height: 10),
          AppText(
            label,
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppColors.color2Box,
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircleAvatar(
      VoidCallback onTap,
      String iconPath, String label) {
    return IosTapEffect(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.iconBg.withOpacity(0.20),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(height: 3),
          AppText(
            label,
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppColors.color2Box,
          ),
        ],
      ),
    );
  }


}
