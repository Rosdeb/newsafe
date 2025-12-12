  import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:saferader/controller/bottom_nav/bottomNavController.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import '../../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../../../../controller/SeakerHome/seakerHomeController.dart';
import '../../../../controller/UserController/userController.dart';
import '../../../../controller/profile/profile.dart';
import '../../../base/AppText/appText.dart';
import '../../map_seeker/map_seeker_enhanced.dart';

class SeakerHome extends StatefulWidget {
  SeakerHome({super.key});

  @override
  State<SeakerHome> createState() => _SeakerHomeState();
}

class _SeakerHomeState extends State<SeakerHome> with SingleTickerProviderStateMixin {

  late final SeakerHomeController controller;
  late final UserController userController;
  late final ProfileController controller1;
  late final SeakerLocationsController locationController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  final navController = Get.find<BottomNavController>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(SeakerHomeController());
    locationController = Get.put(SeakerLocationsController());
    userController = Get.find<UserController>();
    controller1 = Get.put(ProfileController());

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
    locationController.startLiveLocation();

  }

  @override
  void dispose() {
    if (Get.isRegistered<SeakerLocationsController>()) {
      locationController.stopLocationSharing();
    }
    if (Get.isRegistered<SeakerHomeController>()) {
      controller.removeAllListeners();
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
        decoration:const BoxDecoration(
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
                padding:const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  switch (controller.emergencyMode.value) {
                    case 0:
                      return condition(context); // Mode 0
                    case 1:
                      return sendMode(context); // Mode 1
                    case 2:
                      return helpComing(context); // Mode 2
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
    final size = MediaQuery
        .of(context)
        .size;
    final String userRole = userController.userRole.value;
    return Column(
      children: [
        SizedBox(height: size.height * 0.02),

        IosTapEffect(
            onTap: () {
              //controller.toggleMode();
              controller.helpRequest(
                  context, locationController.currentPosition.value!.latitude,
                  locationController.currentPosition.value!.longitude);
              print("click help request:${locationController.currentPosition
                  .value!.latitude.toString()}");
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
                        )
                    ),
                  );
                }
            )
        ),

        SizedBox(height: size.height * 0.10),
        const BannerAds(),
        SizedBox(height: size.height * 0.01),
        const CustomBox(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              AppText(
                "Safe",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2DBD8C),
              ),
              AppText(
                "Tap the emergency button if you need help",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.color2Box,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget condition(BuildContext context) {
    return Obx(() {
        return helpMode(context);
    });
  }

  Widget sendMode(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        IosTapEffect(
          onTap: () {
            //controller.toggleMode();
          },
          child: Container(
            height: 300,
            width: 300,
            padding:const EdgeInsets.all(24),
            decoration:const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFEE3B5),
            ),
            child: Container(
              padding:const EdgeInsets.all(10),
              decoration:const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFD7F2C),
              ),
              child: Container(
                padding:const EdgeInsets.all(10),
                decoration:const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFD9346),
                ),
                child:const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        AppText(
                          "SENDING",
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colorWhite,
                        ),
                       AppText(
                        "Request..",
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

        SizedBox(height: size.height * 0.02),
        IosTapEffect(
          onTap: (){

            controller.cancelHelpRequest();

          },
          child: Container(
            height: 46,
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient:const LinearGradient(
                colors: [Color(0xFFD93A3A), Color(0xFFE94A4A)],
              ),
            ),
            child:const Center(
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
      const  Align(
            child: AppText(
              "Helpers Responding",
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: AppColors.color2Box,
            ),
          ),

        SizedBox(height: size.height * 0.01),
        CustomBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText(
                      "Nearby Helpers",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.color2Box,
                    ),
                    SvgPicture.asset("assets/icon/Frame (1).svg"),
                  ],
                ),
                const SizedBox(height: 12),


                Obx(() {
                  final nearbyList = [
                    {"distance": "Within 1 km", "count": controller.nearbyStats.value.km1 },
                    {"distance": "Within 2 km", "count": controller.nearbyStats.value.km2 },
                  ];

                  return Column(
                    children: List.generate(nearbyList.length, (index) {
                      final item = nearbyList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.iconBg.withOpacity(0.10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "${item["distance"]}",
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.color2Box,
                            ),
                            AppText(
                              "${item["count"]} available",
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.colorIcons,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                }),

              ],
            ),
          )
      ],
    );
  }

  Widget helpComing(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Obx(() {
      if (!controller.hasActiveHelpRequest) {
        return const Center(
          child: AppText("No active help request", color: AppColors.color2Box),
        );
      }

      return Column(
        children: [
          IosTapEffect(
            onTap: () {
              // Keep the circle tap functionality if needed
            },
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          "Help".toUpperCase(),
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colorWhite,
                        ),
                        const AppText(
                          "Coming..",
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colorWhite,
                        ),
                        const SizedBox(height: 10),
                        AppText(
                          "${controller.helperName} is on the way",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colorWhite,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding:const EdgeInsets.symmetric(horizontal: 90),
            child: Column(
              children: [
                GradientButtons(
                  gradientColors: const [Color(0xFFD93A3A), Color(0xFFE94A4A)],
                  onTap: () {
                    controller.cancelHelpRequest();
                  },
                  text: "Cancel Request",
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(height: 10),
                GradientButtons(
                  onTap: (){
                    controller.helpCompleted(controller.currentHelpRequestId.toString());
                  },
                  text: "Work is done",
                  icon: Icons.check,
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.02),

          _buildHelperCard(context),
        ],
      );
    });
  }

  Widget _buildHelperCard(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔥 Get seeker's current location from SeakerLocationsController
    final locationController = Get.find<SeakerLocationsController>();
    final seekerPosition = locationController.currentPosition.value;

    // 🔥 Get helper's (giver's) real-time location from SeakerHomeController
    final helperLat = controller.helperLatitude;
    final helperLng = controller.helperLongitude;
    final LatLng? helperLatLng = (helperLat != null && helperLng != null)
        ? LatLng(helperLat, helperLng)
        : null;

    // 🔥 Create seeker marker (my location)
    final LatLng? seekerLatLng = (seekerPosition != null)
        ? LatLng(seekerPosition.latitude, seekerPosition.longitude)
        : null;

    return IosTapEffect(
      onTap: () {
        // Navigate to full map
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => UniversalMapViewEnhanced(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: CustomBox(
          child: Column(
            children: [
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  controller.helperImage,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Helper Info
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText(
                    "${controller.helperName} is on the way",
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: const Color(0xFF3B82F6),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        "${controller.distance} away",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3B82F6),
                      ),
                      SizedBox(width: size.height * 0.02),
                      const Icon(
                        Icons.directions_walk,
                        size: 12,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      const AppText(
                        "Arriving approximately",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                  AppText(
                    "${controller.eta}",
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Track Live Location Header
              const Align(
                alignment: Alignment.topLeft,
                child: AppText(
                  "Track Live Location",
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.color2Box,
                ),
              ),
              const SizedBox(height: 14),

              // 🔥 REAL MAP PREVIEW (Replace dummy map with this)
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
                    if (seekerLatLng != null && helperLatLng != null)
                      SizedBox(
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                (seekerLatLng.latitude + helperLatLng.latitude) / 2,
                                (seekerLatLng.longitude + helperLatLng.longitude) / 2,
                              ),
                              zoom: 12,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("seeker"),
                                position: seekerLatLng,
                                infoWindow: const InfoWindow(title: "You (Seeker)"),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                              Marker(
                                markerId: const MarkerId("helper"),
                                position: helperLatLng,
                                infoWindow: InfoWindow(title: controller.helperName),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                              ),
                            },
                            onTap: (_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UniversalMapViewEnhanced(),
                                ),
                              );
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                            compassEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // View Map Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IosTapEffect(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UniversalMapViewEnhanced(),
                            ),
                          );
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

              // Address Info (unchanged)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          controller.address,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.color2Box,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          controller.lastUpdated,
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
                          color: AppColors.color2Box,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  CustomBox homeHeader() {

    return CustomBox(
      backgroundColor: AppColors.iconBg.withOpacity(0.01),
      child: Row(
        children: [
          Obx(() =>
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.colorYellow, width: 2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),

                  child: controller.profileImage.value.isNotEmpty
                      ? Image.network(
                    "${controller.profileImage.value}",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "assets/image/8164f733772cbb414dbcbe72a6effd38ed037858.jpg",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      );
                    },
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return AppText(
                    controller.userName.value,
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
              navController.notification();
            },
            child: SizedBox(
              height: 50,
              width: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 16,
                      width: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: const Center(
                        child: AppText(
                          "1",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colorWhite,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    child: SvgPicture.asset(
                      "assets/icon/notifications.svg",
                      height: 30,
                      width: 30,
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
  final String _adUnitId = 'ca-app-pub-3472349079404953/6153930445';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload the ad if the orientation changes to get the correct adaptive banner size.
    _loadAd();
  }

  void _loadAd() async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      debugPrint('Unable to get adaptive banner size');
      return;
    }

    // Dispose the old ad.
    _bannerAd?.dispose();

    // Create and load the new ad.
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$ad loaded successfully.');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
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
      //---====--- shimmer effect here Show a placeholder while the ad is loading. ----====---//
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12)
        ),
      );
    }
  }
}