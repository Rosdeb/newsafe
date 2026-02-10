import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import '../../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../../../../controller/UserController/userController.dart';
import '../../../../controller/bottom_nav/bottomNavController.dart';
import '../../../../controller/notifications/notifications_controller.dart';
import '../../../../controller/profile/profile.dart';
import '../../../../utils/app_constant.dart';
import '../../../base/AppText/appText.dart';
import '../../map_seeker/map_seeker_enhanced.dart';


class Giverhome extends StatefulWidget {
  Giverhome({super.key});

  @override
  State<Giverhome> createState() => _SeakerHomeState();
}

class _SeakerHomeState extends State<Giverhome> with SingleTickerProviderStateMixin {
  late final GiverHomeController controller;
  late final UserController userController;
  late final ProfileController controller1;
  late final SeakerLocationsController locationController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  final navController = Get.find<BottomNavController>();
  final NotificationsController notificationsController = Get.find<NotificationsController>();

  @override
  void initState() {
    super.initState();

    controller = Get.put(GiverHomeController());
    userController = Get.find<UserController>();
    controller1 = Get.put(ProfileController());
    locationController = Get.put(SeakerLocationsController());

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initSocket();
      locationController.startLiveLocation();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    if (controller.socketService != null && controller.socketService!.isConnected.value) {
      controller.socketService!.socket.disconnect();
      controller.socketService!.isConnected.value = false;
      Logger.log("🔌 Socket disconnected because page disposed", type: "info");
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xff202020),
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
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
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: homeHeader(),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  switch (controller.emergencyMode.value) {
                    case 0:
                      return helpMode(context);
                    case 1:
                      return sendMode(context);
                    case 2:
                      return helpComing(context);
                    default:
                      return const SizedBox();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget helpMode(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        helpGiver(),
        SizedBox(height: size.height * 0.02),
        Obx((){
          if(controller.helperStatus.value){
            return Column(
              children: [
                IosTapEffect(
                  onTap: () {
                   // controller.emergencyMode.value = 1;
                  },
                  child: AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 300,
                        width: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFBD3AB),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF24A4A),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE94A4A),
                            ),
                            child: Center(
                              child: Opacity(
                                opacity: _blinkAnimation.value,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppText(
                                      "HELP".toUpperCase(),
                                      fontSize: 35,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.colorWhite,
                                    ),
                                    const AppText(
                                      "Emergency",
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.colorWhite,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                //const BannerAds(),
                SizedBox(height: size.height * 0.01),
                CustomBox(
                  backgroundColor: AppColors.colorYellow.withOpacity(0.10),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      SvgPicture.asset("assets/icon/tabler_heart-handshake.svg"),
                      const SizedBox(height: 15),
                      const AppText(
                        "No emergency requests right now",
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.color2Box,
                      ),
                      const SizedBox(height: 10),
                      const AppText(
                        "Your helping keep the community safe",
                        fontSize: 14,
                        fontWeight: FontWeight.w100,
                        color: AppColors.color2Box,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }else{
            return const SizedBox();
          }
        }),


      ],
    );
  }

  Widget helpGiver() {
    return CustomBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "Helper Status",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.color2Box,
              ),
              SizedBox(height: 8),
              AppText(
                "Ready to help others",
                fontSize: 14,
                fontWeight: FontWeight.w100,
                color: AppColors.color2Box,
              ),
            ],
          ),
          Obx(()=>Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: controller.helperStatus.value,
              onChanged: (v) async {
                controller.helperStatus.value = v;
                try {
                  await controller.updateAvailability(v);
                }on Exception catch (e) {
                  controller.helperStatus.value = !v;
                }
              },
              activeColor: AppColors.colorYellow,
              trackColor: Colors.grey.shade300,
              thumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
            ),
          ),
          ),

        ],
      ),
    );
  }

  Widget sendMode(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _blinkAnimation,
          builder: (context, child) {
            return IosTapEffect(
              onTap: () {},
              child: Container(
                height: 300,
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFEE3B5),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFD7F2C),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFD9346),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: _blinkAnimation.value,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              "Searching",
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppColors.colorWhite,
                            ),
                            AppText(
                              "Please Wait..",
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: AppColors.colorWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: size.height * 0.02),
        IosTapEffect(
          onTap: () {},
          child: Container(
            height: 46,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFD93A3A), Color(0xFFE94A4A)],
              ),
            ),
            child: const Center(
              child: AppText(
                "Cancel Request",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.colorWhite,
              ),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.01),
        const Align(
          alignment: Alignment.topLeft,
          child: AppText(
            "Helpers Responding",
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: AppColors.color2Box,
          ),
        ),

        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.pendingHelpRequests.length,
          itemBuilder: (context, index) {
            final request = controller.pendingHelpRequests[index];
            final seeker = request['seeker'];
            final requestId = request['_id']?.toString() ?? '';

            return emergencyRequestCard(
              name: seeker?['name'] ?? 'Someone',
              image: seeker?['profileImage'] ?? 'https://img.freepik.com/free-photo/portrait-smiling-indian-person-posing-front-camera_482257-122324.jpg?semt=ais_hybrid&w=740&q=80',
              km: request['distance']?.toString() ?? 'Calculating...',
              eta: request['eta']?.toString() ?? 'Calculating...',
              id: requestId,
              request: request,
            );
          },
        ),


      ],
    );
  }

  Widget emergencyRequestCard({
    required String name,
    required String image,
    required String km,
    required String eta,
    required String id,
    required Map<String, dynamic> request, // Add the full request data
  }) {
    // Get the actual seeker data from request
    final seeker = request['seeker'] as Map<String, dynamic>?;
    final actualName = seeker?['name']?.toString() ?? 'Someone';
    final actualImage = seeker?['profileImage']?.toString() ?? 'https://img.freepik.com/free-photo/portrait-smiling-indian-person-posing-front-camera_482257-122324.jpg?semt=ais_hybrid&w=740&q=80';

    // Get actual distance and eta from request
    final actualDistance = request['distance']?.toString() ?? 'Calculating...';
    final actualEta = request['eta']?.toString() ?? 'Calculating...';

    // Extract coordinates for map or distance calculation
    final location = request['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List?;
    final latitude = coordinates?[1]?.toDouble();
    final longitude = coordinates?[0]?.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7C8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Image with better error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.network(
                  actualImage,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "$actualName needs help",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.color2Box,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        AppText(
                          actualDistance,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        AppText(
                          "ETA $actualEta",
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    // Optional: Show request time
                    if (request['createdAt'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatTime(request['createdAt']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IosTapEffect(
                  onTap: ()async {
                    controller.acceptHelpRequest(id);
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          AppText(
                            "Accepts",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IosTapEffect(
                  onTap: ()async {
                    controller.declineHelpRequest(id);
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          AppText(
                            "Decline",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Optional: Show location on map button
          if (latitude != null && longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IosTapEffect(
                onTap: () {
                  // Navigate to map with seeker location
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => MapScreen(
                  //     latitude: latitude,
                  //     longitude: longitude,
                  //     title: "$actualName's Location",
                  //   ),
                  // ));
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "View Location on Map",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} min ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
      } else {
        return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
      }
    }on Exception catch (e) {
      return "Recently";
    }
  }


  Widget helpComing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Obx(() {
      final acceptedRequest = controller.acceptedHelpRequest.value;

      // Check if there's an accepted request
      if (acceptedRequest == null) {
        return Column(
          children: [
            AnimatedBuilder(
              animation: _blinkAnimation,
              builder: (context, child) {
                return IosTapEffect(
                  onTap: () {},
                  child: Container(
                    height: 300,
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD7E5FB),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF60A5FA),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3B82F6),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: _blinkAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  "Help".toUpperCase(),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.colorWhite,
                                ),
                                const AppText(
                                  "Coming",
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.colorWhite,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90),
              child: Column(
                children: [
                  GradientButtons(
                    gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                    onTap: () {},
                    text: "Cancel Request",
                    icon: Icons.cancel_outlined,
                  ),
                  const SizedBox(height: 10),
                  GradientButtons(
                    onTap: () {},
                    text: "Work is done",
                    icon: Icons.check,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // If there's an accepted request, show the seeker info
      final seeker = acceptedRequest['seeker'] as Map<String, dynamic>?;
      final seekerName = seeker?['name']?.toString() ?? 'Someone';
      final seekerImage = seeker?['profileImage']?.toString() ??
          'https://img.freepik.com/free-photo/portrait-smiling-indian-person-posing-front-camera_482257-122324.jpg';
      final distance = acceptedRequest['distance']?.toString() ?? 'Calculating...';
      final eta = acceptedRequest['eta']?.toString() ?? 'Calculating...';
      final requestId = acceptedRequest['_id']?.toString() ?? '';

      final seekerLocation = acceptedRequest['location']?['coordinates'] as List<dynamic>?;
      LatLng? seekerLatLng;

      if (seekerLocation != null && seekerLocation.length == 2) {
        final lon = (seekerLocation[0] as num).toDouble();
        final lat = (seekerLocation[1] as num).toDouble();
        seekerLatLng = LatLng(lat, lon); // Note: LatLng(lat, lng)
      }

      return Column(
        children: [
          // Top Circle with Seeker Info
          IosTapEffect(
            onTap: () {},
            child: Container(
              height: 300,
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      seekerImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _blinkAnimation.value,
                        child: Column(
                          children: [
                            AppText(
                              "Going to help".toUpperCase(),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.colorWhite,
                            ),
                            AppText(
                              seekerName,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colorWhite,
                            ),
                            SizedBox(height: size.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                AppText(
                                  distance,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.colorWhite,
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.timer, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                AppText(
                                  "ETA $eta",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.colorWhite,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: size.height * 0.03),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90),
            child: Column(
              children: [
                GradientButtons(
                  gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                  onTap: () {
                    controller.leaveHelpRequestRoom(requestId);
                  },
                  text: "Cancel Help",
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(height: 10),
                GradientButtons(
                  onTap: () {
                    controller.markWorkDone(requestId);

                  },
                  text: "Work is done",
                  icon: Icons.check,
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.02),

          CustomBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 8),

                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        seekerImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.person, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            seekerName,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.color2Box,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: AppText(
                                  "$distance away • ETA $eta",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Your Location",
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.color2Box,
                    ),
                    const SizedBox(height: 14),

                    // Map Container
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: AppColors.colorYellow,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Map Widget - FIXED: Use locationController instead of controller
                          Obx(() {
                            final giverPos = locationController.currentPosition.value;

                            if (giverPos == null || seekerLatLng == null) {
                              return const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final cameraPosition = CameraPosition(
                              target: seekerLatLng!, // or compute midpoint
                              zoom: 14,
                            );

                            final Set<Marker> markers = {
                              Marker(
                                markerId: const MarkerId("giver_location"),
                                position: LatLng(giverPos.latitude, giverPos.longitude),
                                infoWindow: const InfoWindow(title: "You (Helper)"),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                              ),
                              Marker(
                                markerId: const MarkerId("seeker_location"),
                                position: seekerLatLng!,
                                infoWindow: InfoWindow(title: seekerName ?? "Seeker"),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            };

                            return SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GoogleMap(
                                  initialCameraPosition:cameraPosition,
                                  markers: markers,
                                  onTap: (LatLng tappedPosition) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>const UniversalMapViewEnhanced(
                                          // giverLocation: LatLng(giverPos.latitude, giverPos.longitude),
                                          // seekerLocation: seekerLatLng!,
                                          // seekerName: seekerName,
                                        ),
                                      ),
                                    );
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  liteModeEnabled: true,
                                ),
                              ),
                            );
                          }),

                          // View Map Button Overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IosTapEffect(
                              onTap: () {
                                // TODO: Navigate to full GiverMapView
                                // import 'package:saferader/views/screen/giver_map/giver_map_view.dart';
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => GiverMapView(),
                                //   ),
                                // );
                              },
                              child: Container(
                                height: 32,
                                width: 83,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE047).withOpacity(0.80),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Center(
                                  child: AppText(
                                    "View map",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.color2Box,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                "Address :",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.colorStroke,
                              ),
                              SizedBox(height: 4),
                              AppText(
                                "Last Updated :",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.colorStroke,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Obx(() {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  locationController.addressText.value.isEmpty
                                      ? "Fetching address..."
                                      : locationController.addressText.value,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w200,
                                  color: AppColors.color2Box,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  locationController.currentPosition.value == null
                                      ? "--/--/----"
                                      : "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w200,
                                  color: AppColors.color2Box,
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: GradientButtons(
                            onTap: () {
                              controller.markWorkDone(requestId);
                              Logger.log("hello it click",type: "info");
                            },
                            text: "Done",
                            icon: Icons.check,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: GradientButtons(
                            onTap: () {
                              controller.leaveHelpRequestRoom(requestId);
                            },
                            gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                            text: "Cancel",
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                      ],
                    )
                  ],
                ),

              ],
            ),
          ),
        ],
      );
    });
  }

  CustomBox homeHeader() {
    return CustomBox(
      backgroundColor: AppColors.iconBg.withOpacity(0.01),
      child: Row(
        children: [
          Obx(() =>Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.colorYellow, width: 2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),

                    child: controller1.profileImage.value.isNotEmpty
                        ? Image.network(
                      controller1.profileImage.value,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      "assets/image/8164f733772cbb414dbcbe72a6effd38ed037858.jpg",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),),


          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Obx(() {
                return AppText(
                  controller1.firstName.value,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.color2Box,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),

              Row(
                children: [
                  Obx(() => AppText(
                      "Help ${userController.userRole}",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.color2Box,
                    ),
                  ),
                  const SizedBox(width: 5),
                  IosTapEffect(
                    onTap: () {
                    },
                    child: SvgPicture.asset(
                      "assets/icon/material-symbols-light_change-circle.svg",
                    ),
                  ),
                ],
              ),

            ],
          ),
          const Spacer(),
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
                    child:Obx(() {
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
                    }
                    ),
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

class BannerAds extends StatefulWidget {
  const BannerAds({Key? key}) : super(key: key);

  @override
  State<BannerAds> createState() => _BannerAdsState();
}

class _BannerAdsState extends State<BannerAds> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = AppConstants.Bennar_ad_Id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAd();
      }
    });
  }

  void _loadAd() async {
    try {
      final AnchoredAdaptiveBannerAdSize? size =
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate(),
      );

      if (size == null || !mounted) {
        debugPrint('Unable to get adaptive banner size');
        return;
      }

      _bannerAd?.dispose();

      _bannerAd = BannerAd(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            if (mounted) {
              debugPrint('$ad loaded successfully.');
              setState(() {
                _bannerAd = ad as BannerAd;
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
              });
            }
          },
        ),
      )..load();
    }on Exception catch (e) {
      debugPrint('Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.10),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
  }
}