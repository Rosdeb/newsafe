// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:saferader/controller/profile/profile.dart';
// import 'package:saferader/utils/app_color.dart';
// import 'package:saferader/views/base/AppText/appText.dart';
// import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
// import 'package:saferader/views/screen/help_seaker/setting/profile/editpage.dart';
// import '../../../../../utils/token_service.dart';
// import '../base/headers.dart';
// import '../base/profile_item.dart';
//
// class Profile extends StatefulWidget {
//   Profile({super.key});
//
//   @override
//   State<Profile> createState() => _ProfileState();
// }
//
// class _ProfileState extends State<Profile> {
//   ProfileController controller = Get.put(ProfileController());
//
//   @override
//   void initState() {
//     super.initState();
//     controller.loadUserData();
//     controller.fetchUserProfile();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.centerRight,
//             end: Alignment.centerLeft,
//             colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
//             stops: [0.0046, 0.5005, 0.9964],
//           ),
//         ),
//         child: Column(
//           children: [
//             SizedBox(height: size.height * 0.07),
//             Headers(
//               iconPath: "assets/icon/Vector.svg",
//               title: "Profile",
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             SizedBox(height: size.height * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18.0),
//               child: Container(
//                 width: double.infinity,
//                 height: 148,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                 decoration: BoxDecoration(
//                   color: AppColors.iconBg.withOpacity(0.20),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(width: 1.2, color: AppColors.colorYellow),
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Profile Image with reactive update
//                     Obx(() {
//                       final imageUrl = controller.profileImage.value;
//                       return ClipRRect(
//                         borderRadius: BorderRadius.circular(50),
//                         child: imageUrl.isNotEmpty
//                             ? Image.network(
//                           imageUrl,
//                           height: 100,
//                           width: 100,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               height: 100,
//                               width: 100,
//                               color: AppColors.colorYellow.withOpacity(0.3),
//                               child: const Icon(
//                                 Icons.person,
//                                 size: 50,
//                                 color: AppColors.color2Box,
//                               ),
//                             );
//                           },
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Container(
//                               height: 100,
//                               width: 100,
//                               color: AppColors.colorYellow.withOpacity(0.3),
//                               child: const Center(
//                                 child: CircularProgressIndicator(
//                                   color: AppColors.colorYellow,
//                                 ),
//                               ),
//                             );
//                           },
//                         )
//                             : Container(
//                           height: 100,
//                           width: 100,
//                           decoration: BoxDecoration(
//                             color: AppColors.colorYellow.withOpacity(0.3),
//                             borderRadius: BorderRadius.circular(50),
//                           ),
//                           child: const Icon(
//                             Icons.person,
//                             size: 50,
//                             color: AppColors.color2Box,
//                           ),
//                         ),
//                       );
//                     }),
//                     SizedBox(width: size.height * 0.02),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Obx(() => AppText(
//                           "${controller.firstName} ${controller.lastName}",
//                           fontWeight: FontWeight.w600,
//                           fontSize: 20,
//                           color: AppColors.color2Box,
//                         )),
//                         SizedBox(height: size.height * 0.005),
//                         Obx(() => AppText(
//                           controller.emails.value.isNotEmpty ? controller.emails.value : 'N/A',
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.color2Box,
//                         )),
//                         SizedBox(height: size.height * 0.005),
//                         Obx(() => AppText(
//                           controller.phones.value.isNotEmpty ? controller.phones.value : 'N/A',
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.color2Box,
//                         )),
//                       ],
//                     ),
//                     const Spacer(),
//                     Align(
//                       alignment: Alignment.topLeft,
//                       child: IosTapEffect(
//                         onTap: () async {
//                           // Navigate to edit page and wait for result
//
//                           await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => EditProfile(),
//                             ),
//                           );
//                           // Refresh profile data when returning
//                           await controller.refreshProfile();
//                         },
//                         child: Row(
//                           children: [
//                             SvgPicture.asset(
//                               "assets/icon/material-symbols_edit.svg",
//                             ),
//                             const AppText(
//                               "Edit",
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: AppColors.colorStroke,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: size.height * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Obx(() => ProfileInfoBox(
//                       title: "First name",
//                       value: controller.firstName.value.isNotEmpty ? controller.firstName.value : 'N/A',
//                     )),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Obx(() => ProfileInfoBox(
//                       title: "Last name",
//                       value: controller.lastName.value.isNotEmpty ? controller.lastName.value : 'N/A',
//                     )),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: size.height * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18.0),
//               child: Obx(() => ProfileInfoBox(
//                 title: "Phone number",
//                 value: controller.phones.value.isNotEmpty ? controller.phones.value : 'N/A',
//               )),
//             ),
//             SizedBox(height: size.height * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.iconBg.withOpacity(0.20),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(
//                           width: 1.2,
//                           color: AppColors.colorYellow,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const AppText(
//                                 "Gender",
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w400,
//                                 color: AppColors.color2Box,
//                               ),
//                               Obx(() => AppText(
//                                 controller.genders.value.isNotEmpty ? controller.genders.value : 'N/A',
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.color2Box,
//                               )),
//                             ],
//                           ),
//                           const Spacer(),
//                           const Icon(Icons.arrow_forward_ios_sharp),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Obx(() => ProfileInfoBox(
//                       title: "Date of Birth",
//                       value: controller.dateOfBirth.value.isNotEmpty && controller.dateOfBirth.value != 'Not provided'
//                           ? controller.dateOfBirth.value
//                           : 'N/A',
//                     )),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: size.height * 0.02),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18.0),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.iconBg.withOpacity(0.20),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(width: 1.2, color: AppColors.colorYellow),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const AppText(
//                       "Password",
//                       fontSize: 14,
//                       fontWeight: FontWeight.w400,
//                       color: AppColors.color2Box,
//                     ),
//                     SizedBox(height: size.height * 0.008),
//                     Obx(
//                           () => TextField(
//                         controller: controller.password,
//                         obscureText: controller.passShowHide.value,
//                         autocorrect: false,
//                         obscuringCharacter: "*",
//                         enableSuggestions: false,
//                         enabled: false,
//                         keyboardType: TextInputType.text,
//                         cursorColor: AppColors.colorYellow,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.color2Box,
//                           fontSize: 14,
//                         ),
//                         decoration: InputDecoration(
//                           hintStyle: const TextStyle(
//                             fontWeight: FontWeight.w400,
//                             color: AppColors.colorSubheading,
//                             fontSize: 14,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 13,
//                             horizontal: 12,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: const BorderSide(
//                               width: 1,
//                               color: AppColors.colorYellow,
//                             ),
//                           ),
//                           disabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: const BorderSide(
//                               width: 1.2,
//                               color: AppColors.colorYellow,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: const BorderSide(
//                               width: 1.5,
//                               color: AppColors.colorYellow,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/profile/profile.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/help_seaker/setting/profile/editpage.dart';
import '../base/headers.dart';
import '../base/profile_item.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await controller.fetchUserProfile();
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

            // Main Content with RefreshIndicator
            Expanded(
              child: Obx(() {
                // Show loading indicator on first load
                if (controller.isLoading.value &&
                    controller.userName.value.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.colorYellow,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.colorYellow,
                  backgroundColor: Colors.white,
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        children: [
                          // Profile Header Card
                          _buildProfileHeader(size),

                          SizedBox(height: size.height * 0.02),

                          // Name Fields
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => ProfileInfoBox(
                                  title: "First name",
                                  value: controller.firstName.value.isNotEmpty
                                      ? controller.firstName.value
                                      : 'N/A',
                                )),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => ProfileInfoBox(
                                  title: "Last name",
                                  value: controller.lastName.value.isNotEmpty
                                      ? controller.lastName.value
                                      : 'N/A',
                                )),
                              ),
                            ],
                          ),

                          SizedBox(height: size.height * 0.02),

                          // Email Field
                          Obx(() => ProfileInfoBox(
                            title: "Email address",
                            value: controller.emails.value.isNotEmpty
                                ? controller.emails.value
                                : 'N/A',
                          )),

                          SizedBox(height: size.height * 0.02),

                          // Phone Field
                          Obx(() => ProfileInfoBox(
                            title: "Phone number",
                            value: controller.phones.value.isNotEmpty
                                ? controller.phones.value
                                : 'N/A',
                          )),

                          SizedBox(height: size.height * 0.02),

                          // Gender & DOB Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderBox(),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => ProfileInfoBox(
                                  title: "Date of Birth",
                                  value: controller.dateOfBirth.value.isNotEmpty &&
                                      controller.dateOfBirth.value != 'Not provided'
                                      ? controller.dateOfBirth.value
                                      : 'N/A',
                                )),
                              ),
                            ],
                          ),

                          SizedBox(height: size.height * 0.02),

                          // Password Field
                          _buildPasswordField(size),

                          SizedBox(height: size.height * 0.03),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.iconBg.withOpacity(0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1.5, color: AppColors.colorYellow),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorYellow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Obx(() {
                final imageUrl = controller.profileImage.value;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.colorYellow,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.colorYellow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingAvatar();
                      },
                    )
                        : _buildDefaultAvatar(),
                  ),
                );
              }),

              SizedBox(width: size.width * 0.04),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => AppText(
                      controller.firstName.value.isNotEmpty ||
                          controller.lastName.value.isNotEmpty
                          ? "${controller.firstName.value} ${controller.lastName.value}".trim()
                          : "No Name",
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.color2Box,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),

                    SizedBox(height: size.height * 0.008),

                    Obx(() => Row(
                      children: [
                        const Icon(
                          CupertinoIcons.mail_solid,
                          size: 14,
                          color: AppColors.colorYellow,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText(
                            controller.emails.value.isNotEmpty
                                ? controller.emails.value
                                : 'No Email',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.color2Box,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )),

                    SizedBox(height: size.height * 0.005),

                    Obx(() => Row(
                      children: [
                        const Icon(
                          CupertinoIcons.phone_fill,
                          size: 14,
                          color: AppColors.colorYellow,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText(
                            controller.phones.value.isNotEmpty
                                ? controller.phones.value
                                : 'No Phone',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.color2Box,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Edit Button
          IosTapEffect(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfile(),
                ),
              );
              await controller.refreshProfile();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.colorYellow,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.colorYellow.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/icon/material-symbols_edit.svg",
                    height: 18,
                    width: 18,
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    "Edit Profile",
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.color2Box,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      height: 100,
      width: 100,
      color: AppColors.colorYellow.withOpacity(0.3),
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.color2Box,
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      height: 100,
      width: 100,
      color: AppColors.colorYellow.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.colorYellow,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildGenderBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.iconBg.withOpacity(0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1.2, color: AppColors.colorYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            "Gender",
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.color2Box,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Obx(() => AppText(
                  controller.genders.value.isNotEmpty
                      ? controller.genders.value
                      : 'N/A',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.color2Box,
                )),
              ),
              const Icon(
                Icons.arrow_forward_ios_sharp,
                size: 14,
                color: AppColors.colorYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.iconBg.withOpacity(0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1.2, color: AppColors.colorYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            "Password",
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.color2Box,
          ),
          SizedBox(height: size.height * 0.008),
          Obx(
                () => TextField(
              controller: controller.password,
              obscureText: controller.passShowHide.value,
              autocorrect: false,
              obscuringCharacter: "•",
              enableSuggestions: false,
              enabled: false,
              keyboardType: TextInputType.text,
              cursorColor: AppColors.colorYellow,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.color2Box,
                fontSize: 14,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.passShowHide.value
                        ? CupertinoIcons.eye_slash_fill
                        : CupertinoIcons.eye_fill,
                    color: AppColors.colorYellow,
                    size: 20,
                  ),
                  onPressed: controller.toggle,
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
                    width: 1.2,
                    color: AppColors.colorYellow,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    width: 1.2,
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
    );
  }
}
