import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import '../../../../../controller/profile/profileEdit.dart';
import '../../../../base/AppTextField/apptextfield.dart';
import '../../../welcome/welcome_sreen.dart';
import '../base/headers.dart';

class EditProfile extends StatefulWidget {
  EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  ProfileEditController controllers = Get.put(ProfileEditController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controllers.password.text = "12345678";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
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
              title: "Profile",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Obx(() {
                // Show loading indicator while data is loading
                if (controllers.isLoading.value) {
                  return Container(
                    width: double.infinity,
                    height: 148,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1.2,
                        color: AppColors.colorYellow,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.colorYellow,
                      ),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  height: 148,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.iconBg.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 1.2,
                      color: AppColors.colorYellow,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Obx(() => IosTapEffect(
                          onTap: () {
                            controllers.pickProfileImage();
                          },
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: AppColors.colorYellow,
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: controllers.selectedProfileImage.value != null
                                  ? Image.file(
                                controllers.selectedProfileImage.value!,
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                "assets/icon/user.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: size.height * 0.02),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              controllers.userName.value.isNotEmpty
                                  ? controllers.userName.value
                                  : "No Name",
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: AppColors.color2Box,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: size.height * 0.005),
                            AppText(
                              controllers.userEmail.value.isNotEmpty
                                  ? controllers.userEmail.value
                                  : "No Email",
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.color2Box,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: size.height * 0.005),
                            AppText(
                              controllers.userPhone.value.isNotEmpty
                                  ? controllers.userPhone.value
                                  : "No Phone",
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.color2Box,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    child:  AppTextField(
                        textColor: Colors.black,
                        fillColor: Colors.transparent,
                        keyboardType: TextInputType.emailAddress,
                        controller: controllers.nameController,
                        hint: "First name",
                      ),
                    ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                        textColor: Colors.black,
                        fillColor: Colors.transparent,
                        keyboardType: TextInputType.emailAddress,
                        controller: controllers.lastnameController,
                        hint: "Last name",
                      ),
                  ),

                ],
              ),
            ),

            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iconBg.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width: 1.2,
                          color: AppColors.colorYellow,
                        ),
                      ),
                      child: Row(
                        children: [
                          const AppText(
                            "Gender : ",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.color2Box,
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 50,
                              child: PageView.builder(
                                onPageChanged: (value) {
                                  controllers.onGenderPageChanged(value);
                                },
                                controller: controllers.pageController,
                                itemCount: controllers.genderList.length,
                                itemBuilder: (context, index) {
                                  return Obx(() {
                                    bool isSelected =
                                        controllers.selectedIndex.value ==
                                        index;

                                    return AnimatedScale(
                                      scale: isSelected ? 1.81 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: AppText(
                                            controllers.genderList[index],
                                            fontSize: isSelected ? 16 : 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.color2Box
                                                : AppColors.colorYellow,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          ),

                          const Spacer(),
                          IosTapEffect(
                            onTap: () {
                              if (controllers.selectedIndex.value <= 0) {
                                controllers.selectedIndex.value++;
                              } else {
                                controllers.selectedIndex.value--;
                              }
                            },
                            child:const Icon(
                              Icons.arrow_forward_ios_sharp,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Obx(
                      () => GestureDetector(
                        onTap: () {
                          controllers.selectDateOfBirth(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.iconBg.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1.2,
                              color: AppColors.colorYellow,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const AppText(
                                "Date of birth",
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.color2Box,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppText(
                                      controllers.dateOfBirth.value.isNotEmpty
                                          ? controllers.dateOfBirth.value
                                          : "Select date",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          controllers.dateOfBirth.value ==
                                              'Not provided'
                                          ? AppColors.colorSubheading
                                          : AppColors.color2Box,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.colorYellow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.iconBg.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 1.2, color: AppColors.colorYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Password",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.color2Box,
                    ),
                    SizedBox(height: size.height * 0.008),
                    Obx(
                      () => TextField(
                        controller: controllers.password,
                        obscureText: !controllers.isPasswordVisible.value,
                        // Changed to ! for clarity
                        autocorrect: false,
                        obscuringCharacter: "*",
                        enableSuggestions: false,
                        enabled: false,
                        keyboardType: TextInputType.text,
                        cursorColor: AppColors.colorYellow,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.color2Box,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              controllers.isPasswordVisible.value
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              color: AppColors.colorYellow,
                            ),
                            onPressed: () {
                              controllers.togglePasswordVisibility();
                            },
                          ),
                          hintStyle: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: AppColors.colorSubheading,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              width: 1,
                              color: AppColors.colorYellow,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              width: 1.5,
                              color: AppColors.colorYellow,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              width: 1.5,
                              color: AppColors.colorYellow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child:Obx(()=>GradientButton(
                isLoading: controllers.save.value,
                text: 'Save & update'.toUpperCase(),
                onTap: ()async{
                  controllers.updateProfileHttp(context);
                },
              ),)
            ),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }
}
