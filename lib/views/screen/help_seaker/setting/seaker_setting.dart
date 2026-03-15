import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../base/AppTextField/apptextfield.dart';
import 'package:saferader/controller/setting/setting_controller.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';
import 'package:saferader/views/screen/help_seaker/setting/distanceSetting/distanceSetting.dart';
import 'package:saferader/views/screen/help_seaker/setting/help/help_setting.dart';
import 'package:saferader/views/screen/help_seaker/setting/legal_terms/legal_terms.dart';
import 'package:saferader/views/screen/help_seaker/setting/profile/profile.dart';
import 'package:saferader/views/screen/help_seaker/setting/share/share_app.dart';
import 'package:saferader/views/screen/help_seaker/setting/user_preferrence/user_preferrence.dart';
import 'package:flutter/cupertino.dart';

import '../../../base/gradientbutton/gradientButton.dart';

class SeakerSetting extends StatelessWidget {
  SeakerSetting({super.key});

  final SettingController controller = Get.put(SettingController());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  "Setting".tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),


                Expanded(
                  child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return IosTapEffect(
                            onTap: () {
                              controller.selectedIndex.value = index;
                              switch (index) {
                                case 0:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => Profile(),
                                    ),
                                  );
                                  break;
                                  break;
                                case 1:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => Distancesetting(),
                                    ),
                                  );
                                  break;
                                case 2:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => UserPreferrence(),
                                    ),
                                  );
                                  break;
                                case 3:
                                  break;
                                case 4:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => ShareApp(),
                                    ),
                                  );
                                  break;
                                case 5:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => LegalTerms(),
                                    ),
                                  );
                                  break;
                                case 6:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) => HelpSetting(),
                                    ),
                                  );
                                  break;
                                case 7:
                                  LogoutDialog.show(context);
                                  break;
                                case 8:
                                  DeleteAccountSheet.show(context);
                                  break;
                                default:
                                  break;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Container(
                                height: 75,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFDE047).withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.colorYellow,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (items[index]['icon']
                                        .toString()
                                        .endsWith('.svg'))
                                      SvgPicture.asset(
                                        items[index]['icon'],
                                        width: 26,
                                        height: 26,
                                      )
                                    else
                                      Image.asset(
                                        items[index]['icon'],
                                        width: 26,
                                        height: 26,
                                      ),
                                    const SizedBox(width: 20),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          items[index]["title"],
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        AppText(
                                          items[index]["subtitle"],
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                          color: AppColors.colorStroke,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                      },
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  final List<Map<String, dynamic>> items = [
    {
      "icon": "assets/icon/Add-User.svg",
      "title": "Profile".tr,
      "subtitle": "Get instant help when you need it most",
    },
    {
      "icon": "assets/icon/weui_location-filled copy.svg",
      "title": "Distance Settings".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/icon/material-symbols_settings-rounded copy.svg",
      "title": "User Preferences".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/icon/mdi_star-rate copy.svg",
      "title": "Rate App".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/icon/material-symbols_share copy.svg",
      "title": "Share App".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/icon/mdi_legal (1) copy.svg",
      "title": "Legal Terms".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/icon/material-symbols_question-mark-rounded.svg",
      "title": "Help".tr,
      "subtitle": "Share your location safely with helpers",
    },
    {
      "icon": "assets/image/out.png",
      "title": "Log Out".tr,
      "subtitle": "Log out your profile",
    },
    {
      "icon": "assets/icon/delete.png",
      "title": "Account Delete".tr,
      "subtitle": "Delete Your Account".tr,
    },

  ];

}

class DeleteAccountSheet {
  static void show(BuildContext context) {
    final SettingController controller = Get.find<SettingController>();

    showModalBottomSheet(
      enableDrag: false,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Obx(() => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(35),topRight: Radius.circular(35)),
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                // Warning icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red.shade400,
                    size: 26,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Delete Account",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Are you sure you want to delete your account?\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),


                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                          await controller.deleteAccount(context);
                        },
                        child:controller.isLoading.value ?  CupertinoActivityIndicator(color: Colors.white,)
                         : const AppText("Delete",color: Colors.white,fontSize: 14,),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LogoutDialog {
  static void show(BuildContext context) {
    final SettingController controllers = Get.find<SettingController>();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Color(0xFFEAF0F0).withOpacity(0.70),
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: SvgPicture.asset("assets/icons/maki_cross.svg"),
                  ),
                ),
                 Align(
                  alignment: Alignment.topLeft,
                  child: AppText(
                    "Log Out".tr,
                    color: AppColors.color2Box,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to log out your account?".tr,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    color: AppColors.colorStroke,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: IosTapEffect(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: AppColors.colorStroke,
                            ),
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Cancel".tr,
                            style: const TextStyle(
                              color: AppColors.color2Box,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Gradientbutton1(
                        ontap: ()async{
                          controllers.logoutUser(context);
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder)=>SigninScreen()), (route)=> false);
                        }, text: "Log Out".tr,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

