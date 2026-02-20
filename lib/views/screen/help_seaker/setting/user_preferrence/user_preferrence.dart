import 'package:dropdown_button2/dropdown_button2.dart';
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
                  title: "User Preferences".tr,
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

                        AppText(
                          "Select your preferable settings".tr,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.color2Box,
                        ),
                        SizedBox(height: size.height * 0.012),
                        AppText(
                          "Language".tr,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppColors.color2Box.withOpacity(0.50),
                        ),
                        SizedBox(height: size.height * 0.012),
                        buildLanguageSelector(context, isTablet),
                        SizedBox(height: size.height * 0.012),
                        Row(
                          children: [
                            SvgPicture.asset("assets/icon/streamline-cyber_mobile-phone-vibration.svg"),
                            SizedBox(width: size.height * 0.009),
                            AppText(
                              "Vibrations".tr,
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
                              "Speaker".tr,
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
                                  if (!value) {
                                    notificationsController.toggleVibration(false);
                                  }
                                }: null,
                                activeColor: AppColors.colorYellow,
                                trackColor: Colors.grey.shade300,
                                thumbColor: Colors.white,
                              ),
                            )),


                          ],
                        ),
                        AppText(
                          "Emergency Response Notification".tr,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.color2Box,
                        ),
                        Row(
                          children: [
                            SvgPicture.asset("assets/icon/akar-icons_sound-on.svg"),
                            SizedBox(width: size.height * 0.009),
                            Expanded(
                              child: AppText(
                                "Receive alerts when others need help".tr,
                                fontSize: 14,
                                fontWeight: FontWeight.w100,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: AppColors.color2Box.withOpacity(0.50),
                              ),
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
                // const Padding(
                //   padding:  EdgeInsets.symmetric(horizontal: 18.0),
                //   child: BannerAds(),
                // ),

              //  _buildLanguageTabs(isTablet,context),

              ],
            ),
          ),
      ),
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

  Widget buildLanguageSelector(BuildContext context, bool isTablet) {
    return GetBuilder<LocalizationController>(
      builder: (controller) {
        final selectedLang = AppConstants.languages[controller.selectedIndex].languageName.tr;
        return DropdownButtonHideUnderline(
          child: DropdownButton2(
            customButton: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.colorYellow.withOpacity(0.10),
                border: Border.all(
                  width: 1,
                  color: AppColors.colorYellow,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  AppText(
                    selectedLang,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  const Spacer(),
                  SvgPicture.asset("assets/icon/Frame (2).svg"),
                  const SizedBox(width: 15),
                ],
              ),
            ),
            items: AppConstants.languages
                .asMap()
                .entries
                .map((entry) {
              int index = entry.key;
              final language = entry.value;
              final isSelected = controller.selectedIndex == index;

              return DropdownMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        language.languageName.tr,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.green,
                      ),
                  ],
                ),
              );
            })
                .toList(),
            onChanged: (value) {
              if (value != null) {
                final language = AppConstants.languages[value];
                controller.setLanguage(
                  Locale(language.languageCode, language.countryCode)
                );
              }
            },
            dropdownStyleData: DropdownStyleData(
              width: 300,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              elevation: 8,
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        );
      },
    );
  }

}
