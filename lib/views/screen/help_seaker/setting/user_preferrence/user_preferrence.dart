import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/notifications/notifications_controller.dart';
import 'package:saferader/controller/profile/profile.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import '../../../../../controller/localizations/localization_controller.dart';
import '../../../../../utils/app_color.dart';
import '../../../../../utils/app_constant.dart';
import '../../../../base/AppText/appText.dart';
import '../../../help_giver/help_giver_home/giverHome.dart';
import '../base/headers.dart';


class UserPreferrence extends StatelessWidget {
  UserPreferrence({super.key});
  ProfileController controller = Get.put(ProfileController());
  final NotificationsController notificationsController = Get.find<NotificationsController>();

  final List<String> languages  = [
    "English",
  ];


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = size.width > 600;

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
                  title: "User Preferences",
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(height: size.height * 0.02),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0,),
                  child: CustomBox(
                    backgroundColor: AppColors.iconBg.withOpacity(0.20),
                    padding:const  EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const AppText(
                          "Select your preferable settings",
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.color2Box,
                        ),
                        SizedBox(height: size.height * 0.012),
                        AppText(
                          "Language",
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppColors.color2Box.withOpacity(0.50),
                        ),
                        SizedBox(height: size.height * 0.012),
                        buildLanguageSelector(controller, languages),
                        SizedBox(height: size.height * 0.012),
                        Row(
                          children: [
                            SvgPicture.asset("assets/icon/streamline-cyber_mobile-phone-vibration.svg"),
                            SizedBox(width: size.height * 0.009),
                            AppText(
                              "Vibrations",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.color2Box.withOpacity(0.50),
                            ),
                            const Spacer(),
                            Obx(() => Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: notificationsController.isVibrationEnabled.value,
                                onChanged: notificationsController.isNotificationsEnabled.value
                                    ? (value) {
                                  notificationsController.toggleVibration(value);
                                  // 🔥 নতুন লাইন: Vibration অফ হলে Sound অফ হবে
                                  if (!value) {
                                    notificationsController.toggleSound(false);
                                  }
                                }
                                    : null,
                                activeColor: AppColors.colorYellow,
                                trackColor: Colors.grey.shade300,
                                thumbColor: Colors.white,
                              ),
                            )),


                          ],
                        ),
                        Row(
                          children: [
                            SvgPicture.asset("assets/icon/akar-icons_sound-on.svg"),
                            SizedBox(width: size.height * 0.009),
                            AppText(
                              "Speaker",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.color2Box.withOpacity(0.50),
                            ),
                            const Spacer(),
                            Obx(() => Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: notificationsController.isSoundEnabled.value,
                                onChanged: notificationsController.isNotificationsEnabled.value
                                    ? (value) {
                                  notificationsController.toggleSound(value);
                                  // 🔥 নতুন লাইন: Sound অফ হলে Vibration অফ হবে
                                  if (!value) {
                                    notificationsController.toggleVibration(false);
                                  }
                                }
                                    : null,
                                activeColor: AppColors.colorYellow,
                                trackColor: Colors.grey.shade300,
                                thumbColor: Colors.white,
                              ),
                            )),


                          ],
                        ),
                        const AppText(
                          "Emergency Response Notification",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.color2Box,
                        ),
                        Row(
                          children: [
                            SvgPicture.asset("assets/icon/akar-icons_sound-on.svg"),
                            SizedBox(width: size.height * 0.009),
                            AppText(
                              "Receive alerts when others need help",
                              fontSize: 14,
                              fontWeight: FontWeight.w100,
                              color: AppColors.color2Box.withOpacity(0.50),
                            ),
                            const Spacer(),
                            Obx(()=> Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: notificationsController.isNotificationsEnabled.value,
                                onChanged: (value) {
                                  notificationsController.toggleNotifications(value);
                                },
                                activeColor:AppColors.colorYellow,  // ON track color
                                trackColor: Colors.grey.shade300,     // OFF track color
                                thumbColor: Colors.white,
                                inactiveThumbColor: Colors.white,
                              ),
                            ),)


                          ],
                        ),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                const Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 18.0),
                  child: BannerAds(),
                ),


                _buildLanguageTabs(isTablet),
                Text("Home".tr),

              ],
            ),
          ),
      ),
    );
  }

  Widget _buildLanguageTabs(bool isTablet) {
    return GetBuilder<LocalizationController>(
      builder: (controller) {
        return Wrap(
          alignment: WrapAlignment.start,
          spacing: isTablet ? 12.0 : 8.0,
          runSpacing: isTablet ? 4.0 : 2.0,
          children: AppConstants.languages.asMap().entries.map((entry) {
            int index = entry.key;
            final language = entry.value;
            final isSelected = controller.selectedIndex == index;
            return GestureDetector(
              onTap: () {
                controller.setLanguage(Locale(language.languageCode, language.countryCode));
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 11,
                  vertical: isTablet ? 10 : 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      language.languageName.tr,
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.colorWhite : AppColors.colorBlue2),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      height: isTablet ? 3 : 2,
                      width: _textWidth(
                        language.languageName.tr,
                        TextStyle(
                          fontSize: isTablet ? 18 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      color: isSelected ? Colors.yellow : Colors.transparent
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  double _textWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }


  Widget buildLanguageSelector(ProfileController controller, List<String> languages) {
    return Obx(() => PopupMenuButton<String>(
      offset: const Offset(0, 45), // menu shows below the button
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        controller.setLanguage(value); // update reactive variable
        debugPrint("Selected Language: $value");
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: AppText(
            "Select Language",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xff71717A),
          ),
        ),
        ...languages.map(
              (lang) => PopupMenuItem<String>(
            value: lang,
            child: Row(
              children: [
                if (controller.selectedLanguage.value == lang)
                  const Icon(Icons.check, color: Colors.green, size: 16),
                if (controller.selectedLanguage.value == lang)
                  const SizedBox(width: 6),
                AppText(
                  lang,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.colorYellow.withOpacity(0.10),
          border: Border.all(
              width: 1,
              color: AppColors.colorYellow),
        ),
        child: Row(
          children: [
            SizedBox(width: 15,),

            AppText(
              controller.selectedLanguage.value,
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.black,
            ),
            Spacer(),
            SvgPicture.asset(
              "assets/icon/Frame (2).svg",
            ),
            SizedBox(width: 15,),
          ],
        ),
      ),
    ));
  }

  // /// Show notification settings bottom sheet
  // void _showSettingsBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(20.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Text(
  //               'Notification Settings',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //
  //             // Enable Notifications
  //             Obx(() => SwitchListTile(
  //               title: const Text('Enable Notifications'),
  //               subtitle: const Text('Receive push notifications'),
  //               value: notificationsController.isNotificationsEnabled.value,
  //               onChanged: (value) {
  //                 notificationsController.toggleNotifications(value);
  //               },
  //             )),
  //
  //             const Divider(),
  //
  //             // Sound
  //             Obx(() => SwitchListTile(
  //               title: const Text('Sound'),
  //               subtitle: const Text('Play sound when notification arrives'),
  //               value: notificationsController.isSoundEnabled.value,
  //               onChanged: notificationsController.isNotificationsEnabled.value
  //                   ? (value) {
  //                 notificationsController.toggleSound(value);
  //               }
  //                   : null,
  //             )),
  //
  //             const Divider(),
  //
  //             // Vibration
  //             Obx(() => SwitchListTile(
  //               title: const Text('Vibration'),
  //               subtitle: const Text('Vibrate when notification arrives'),
  //               value: notificationsController.isVibrationEnabled.value,
  //               onChanged: notificationsController.isNotificationsEnabled.value
  //                   ? (value) {
  //                 notificationsController.toggleVibration(value);
  //               }
  //                   : null,
  //             )),
  //
  //             const SizedBox(height: 10),
  //
  //             // Clear all button
  //             if (notificationsController.notifications.isNotEmpty)
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     Get.dialog(
  //                       AlertDialog(
  //                         title: const Text('Clear All Notifications'),
  //                         content: const Text(
  //                           'Are you sure you want to clear all notifications?',
  //                         ),
  //                         actions: [
  //                           TextButton(
  //                             onPressed: () => Get.back(),
  //                             child: const Text('Cancel'),
  //                           ),
  //                           TextButton(
  //                             onPressed: () {
  //                               notificationsController.clearAllNotifications();
  //                               Get.back();
  //                               Get.back();
  //                             },
  //                             child: const Text(
  //                               'Clear All',
  //                               style: TextStyle(color: Colors.red),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.red,
  //                     foregroundColor: Colors.white,
  //                   ),
  //                   child: const Text('Clear All Notifications'),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

}
