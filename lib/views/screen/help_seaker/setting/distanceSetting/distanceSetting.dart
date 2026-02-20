import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/utils/logger.dart';

import '../../../../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../../../../controller/profile/profile.dart';
import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../../../help_giver/help_giver_home/giverHome.dart';
import '../../locations/seaker_location.dart';
import '../base/headers.dart';
class Distancesetting extends StatelessWidget {
  Distancesetting({super.key});

  final List<String> distance  = ["1", "1.5", "2", "2.5"];


  ProfileController controller = Get.put(ProfileController());
  final SeakerLocationsController locationController = Get.find<SeakerLocationsController>();


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
                title: "Distance Settings",
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: size.height * 0.02),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0,),
                child: CustomBox(
                  backgroundColor: AppColors.iconBg.withOpacity(0.20),
                  padding:const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
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
                        "Notification range",
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: AppColors.color2Box.withOpacity(0.50),
                      ),
                      SizedBox(height: size.height * 0.012),
                      buildDistanceSelector(controller, distance),
                      SizedBox(height: size.height * 0.012),
                      AppText(
                        "Live location sharing",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.color2Box.withOpacity(0.50),
                      ),
                      Row(
                        children: [
                          AppText(
                            "Automatically set your location",
                            fontSize: 14,
                            fontWeight: FontWeight.w100,
                            color: AppColors.color2Box.withOpacity(0.50),
                          ),
                          const Spacer(),
                          Obx(() => Transform.scale(
                            scale: 0.8,
                            child: CupertinoSwitch(
                              value: locationController.isSharingLocation.value,
                              onChanged: (v) {
                                _handleAutoLocationToggle(v);
                              },
                              activeColor: AppColors.colorYellow,
                              trackColor: Colors.grey.shade300,
                              thumbColor: Colors.white,
                              inactiveThumbColor: Colors.white,
                            ),
                          )),


                        ],
                      ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25,),
              // const Padding(
              //   padding:  EdgeInsets.symmetric(horizontal: 18.0),
              //   child: BannerAds(),
              // ),
            ],
          ),
        ),
      ),
    );
  }


  void _handleAutoLocationToggle(bool enable) async {

    try{
      if(enable){
        final hasPermission = await locationController.handlePermission();
        if(!hasPermission){
          Get.snackbar(
            "Permission Required",
            "Location permission is needed for automatic location sharing",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
        await locationController.startLiveLocation();
        locationController.startLocationSharing();


      }else{
        locationController.stopLocationSharing();

      }
    }catch(e){
      Logger.log("❌ Error toggling auto location: $e", type: "error");
    }
  }
  Widget buildDistanceSelector(ProfileController controller, List<String> distances) {
    return Obx(() => PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        controller.setDistance(value);
        final distanceValue = double.tryParse(value)?.toInt() ?? 1;
        controller.preferableSetting(distanceValue);
        debugPrint("Selected Distance: $value");

      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: AppText(
            "Select Distance",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xff71717A),
          ),
        ),
        ...distances.map((dis) => PopupMenuItem<String>(
          value: dis,
          child: Row(
            children: [
              if (controller.distance.value == dis)
                const Icon(Icons.check, color: Colors.green, size: 16),
              if (controller.distance.value == dis)
                const SizedBox(width: 6),
              AppText(
                dis,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.black,
              ),
            ],
          ),
        )),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.colorYellow.withOpacity(0.10),
          border: Border.all(width: 1, color: AppColors.colorYellow),
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            AppText(
              "${controller.distance.value} Km (City)", // use .value
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.black,
            ),
            const Spacer(),
            SvgPicture.asset(
              "assets/icon/Frame (2).svg",
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    ));
  }


}
