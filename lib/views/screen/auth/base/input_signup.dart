import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controller/signup/signupController.dart';
import '../../../../utils/app_color.dart';
import '../../../base/AppText/appText.dart';
import '../../../base/AppTextField/apptextfield.dart';
import '../../../base/animationsWrapper/animations_wrapper.dart';
import '../signUpPage/sign_up_screen.dart';
import '../signUpPage/widget/countryCode.dart';
import 'countices.dart';

class InputSignUpPage extends StatelessWidget {
  InputSignUpPage({super.key});

  final SignUpController controller = Get.put(SignUpController());
  final controller1 = Get.put(CountryController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [

        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.topLeft,
            child: AppText(
              "Full Name".tr,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.colorSubheading,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: AppTextField(
            keyboardType: TextInputType.text,
            controller: controller.nameController,
            hint: "Enter your full name".tr,
          ),
        ),
        //----===--- email address --==---
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.topLeft,
            child: AppText(
              "Email Address".tr,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.colorSubheading,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: AppTextField(
            keyboardType: TextInputType.emailAddress,
            controller: controller.emailController,
            hint: "Enter your email".tr,
            suffix: Icon(CupertinoIcons.mail,color: Colors.white38),
          ),
        ),
        //----===--- phone number --==---
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.topLeft,
            child: AppText(
              "Phone number".tr,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.colorSubheading,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        phoneNumber(),
        //----===--- password --==---
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.topLeft,
            child: AppText(
              "Password".tr,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.colorSubheading,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Obx(() => AppTextField(
            obscure: controller.passShowHide.value,
            keyboardType: TextInputType.twitter,
            controller: controller.passwordController,
            hint: "Enter your password".tr,
            suffix: IconButton(
              icon: Icon(
                controller.passShowHide.value
                    ? CupertinoIcons.eye_slash
                    : CupertinoIcons.eye,
                color: Colors.white38,
              ),
              onPressed: () {
                controller.toggle();
              },
            ),
          )),
        ),
        //----===--- confirm password --==---
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.topLeft,
            child: AppText(
              "Confirm Password".tr,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.colorSubheading,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        AnimatedWidgetWrapper(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 500),
          child: Obx(() => AppTextField(
            obscure: controller.passShowHide1.value,
            keyboardType: TextInputType.twitter,
            controller: controller.confirmPasswordController,
            hint: "Enter your password".tr,
            suffix: IconButton(
              icon: Icon(
                controller.passShowHide1.value
                    ? CupertinoIcons.eye_slash
                    : CupertinoIcons.eye,
                color: Colors.white38,
              ),
              onPressed: () {
                controller.toggle1();
              },
            ),
          )),
        ),


      ],
    );
  }
  InkWell phoneNumber() {
    return InkWell(
      onTap: () async {
        final selected = await Get.to(() => CountryPage());
        if (selected != null) {
          controller1.selectedCountryName.value = selected.name;
          controller1.selectedCountryFlag.value = selected.flagEmoji;
          controller1.selectedCountryCode.value = selected.phoneCode;

          // Optional: Auto-fill the code into the text field
          //controller.phoneController.text = "+${selected.phoneCode} ";

        }
      },
      child: Obx(() {
        final hasSelection = controller1.selectedCountryName.value.isNotEmpty;

        return FocusScope(
          child: Focus(
            onFocusChange: (hasFocus) {
              controller1.selectedField.value = hasFocus;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color:const Color(0xFF383838),
                border: Border.all(
                  color: controller1.selectedField.value
                      ? AppColors.colorYellow
                      : AppColors.colorIcons.withOpacity(0.50),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (hasSelection)
                    Text(
                      controller1.selectedCountryFlag.value,
                      style: const TextStyle(fontSize: 22),
                    )
                  else
                    const Icon(Icons.flag_outlined, color: Colors.white70, size: 20),

                  const SizedBox(width: 8),


                  InkWell(
                    onTap: () async {
                      final selected = await Get.to(() => CountryPage());
                      if (selected != null) {
                        controller1.selectedCountryName.value = selected.name;
                        controller1.selectedCountryFlag.value = selected.flagEmoji;
                        controller1.selectedCountryCode.value = selected.phoneCode;
                        controller.phoneController.text = "+${selected.phoneCode} ";
                      }
                    },
                    child: Row(
                      children: [
                        Text(hasSelection
                              ? "+${controller1.selectedCountryCode.value}"
                              : "Select".tr,style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 1),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
                      ],
                    ),
                  ),

                  const SizedBox(width: 5),

                  // ✏️ Phone number input
                  Expanded(
                    child: TextField(
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      onTap: () => controller1.selectedField.value = true,
                      decoration: InputDecoration(
                        hintText: "Enter number".tr,
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}