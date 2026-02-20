import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/controller/bothhomeController/bothHomeController.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/screen/help_giver/help_giver_home/giverHome.dart';
import 'package:saferader/views/screen/help_seaker/home/seaker_home.dart';
import '../../../controller/SeakerHome/seakerHomeController.dart';
import '../../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../../controller/SocketService/socket_service.dart';
import '../../../controller/bottom_nav/bottomNavController.dart';
import '../../../controller/notifications/notifications_controller.dart';
import '../../../controller/profile/profile.dart';
import '../../../utils/app_color.dart';
import '../../../utils/token_service.dart';
import '../../base/AppText/appText.dart';
import '../../base/Ios_effect/iosTapEffect.dart';
import '../help_seaker/locations/seaker_location.dart';

class Bothhome extends StatefulWidget {
  Bothhome({super.key});

  @override
  State<Bothhome> createState() => _BothhomeState();
}

class _BothhomeState extends State<Bothhome> {
  UserController userController = Get.find<UserController>();
  BothHomeController controller = Get.put(BothHomeController());
  final navController = Get.find<BottomNavController>();
  late final ProfileController controller1;
  final NotificationsController notificationsController = Get.find<NotificationsController>();

  @override
  void initState() {
    super.initState();
    controller1 = Get.put(ProfileController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (userController.userRole.value == 'both') {
        final token = await TokenService().getToken();
        if (token != null) {
          await Get.putAsync(() => SocketService().init(token, role: 'both'));
          Logger.log("Socket initialized for BOTH role", type: "success");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 70),
            homeHeader(),

            const SizedBox(height: 70),

            IosTapEffect(
              onTap: () {
                if (Get.isRegistered<SeakerHomeController>()) {
                  Get.delete<SeakerHomeController>();
                }
                if (Get.isRegistered<SeakerLocationsController>()) {
                  Get.delete<SeakerLocationsController>();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SeakerHome()),
                );
              },
              child: CustomBox(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    AppText(
                      "Help Seeker".tr,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    AppText(
                      "If you need help click here".tr,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.color2Box.withOpacity(0.50),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            IosTapEffect(
              onTap: () {
                if (Get.isRegistered<GiverHomeController>()) {
                  Get.delete<GiverHomeController>();
                }
                if (Get.isRegistered<SeakerLocationsController>()) {
                  Get.delete<SeakerLocationsController>();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Giverhome()),
                );
              },
              child: CustomBox(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    AppText(
                      "Help Giver".tr,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    AppText(
                      "If you want to help click here".tr,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.color2Box.withOpacity(0.50),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomBox homeHeader() {
    return CustomBox(
      backgroundColor: AppColors.iconBg.withOpacity(0.01),
      child: Row(
        children: [
          Obx(() => Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.colorYellow, width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  imageUrl: controller1.profileImage.value,
                  cacheKey: controller1.profileImage.value.split('?').first,
                  fit: BoxFit.cover,
                  height: 50,
                  width: 50,
                  httpHeaders: const {
                    "Accept": "image/*",
                  },
                  placeholder: (_, __) => const CupertinoActivityIndicator(),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                )
              ),
            ),
          ),

          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return AppText(
                    controller1.firstName.value +
                        " " +
                        controller1.lastName.value,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.color2Box,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
                Row(
                  children: [
                    Obx(() {
                      return AppText(
                        "Help ${controller.userRole}",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.color2Box,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    const SizedBox(width: 5),
                    IosTapEffect(
                      onTap: () {},
                      child: SvgPicture.asset(
                        "assets/icon/material-symbols-light_change-circle.svg",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          IosTapEffect(
            onTap: () {
              navController.notification(2);
            },
            child: SizedBox(
              height: 50,
              width: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4,
                    child: SvgPicture.asset(
                      "assets/icon/notifications.svg",
                      height: 30,
                      width: 30,
                    ),
                  ),

                  Positioned(
                    right: -2,
                    top: 0,
                    child: Obx(() {
                      final unreadCount = notificationsController.unreadCount;

                      if (unreadCount <= 0) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? "99+" : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
