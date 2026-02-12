import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/screen/help_seaker/locations/live.dart';

import '../../../../utils/app_color.dart';
import '../../../base/EmptyBox/emptybox.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import '../setting/UserRole/user_role.dart';
class SeakerLocation extends StatefulWidget {
  SeakerLocation({super.key});

  @override
  State<SeakerLocation> createState() => _SeakerLocationState();
}

class _SeakerLocationState extends State<SeakerLocation> {
  final SeakerLocationsController controller = Get.find();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration:const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xFFFFF1A9),
                Color(0xFFFFFFFF),
                Color(0xFFFFF1A9),
              ],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
          child: Padding(padding:const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 60,),
              Text(
                "Live Location".tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              CustomBox(
                padding:const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText("Location Sharing".tr, fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.color2Box),
                    const SizedBox(height: 10),
                    AppText("Enable Live location".tr, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.color2Box),
                    Row(
                      children: [
                        AppText("Share your live location".tr, fontSize: 14, fontWeight: FontWeight.w200, color: AppColors.color2Box),
                        const Spacer(),
                        LabeledSwitch(
                          title: "",
                          value: controller.liveLocation,
                          onChanged: (v) async {
                            controller.liveLocation.value = v; // Update the toggle

                            if (v) {
                              // Start live location and auto-sharing
                              await controller.startLiveLocation();
                              controller.startLocationSharing();
                            } else {
                              // Stop live location and auto-sharing
                              controller.stopLocationSharing();
                              controller.liveLocation.value = false;
                            }
                          },
                        ),

                      ],
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 14),
              Obx(() {
                if (!controller.liveLocation.value){
                  return EmptyHistoryBox(
                    title: "Location sharing is disabled".tr,
                    subtitle: "Enable your live location with others".tr,
                    iconPath: "assets/icon/weui_location-filled.svg",
                    height: 200,
                  );
                }
                else{
                  return CustomBox(
                    padding:const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Your Location".tr,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.color2Box,
                        ),
                        const SizedBox(height: 14),
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
                              Obx(() {
                                final pos = controller.currentPosition.value;

                                if (pos == null) {
                                  return const SizedBox(
                                    height: 160,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                return SizedBox(
                                  height: 200,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(pos.latitude, pos.longitude),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId("preview_marker"),
                                          position: LatLng(pos.latitude, pos.longitude),
                                        ),
                                      },
                                      onTap: (LatLng tappedPosition) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => MapScreensssss()),
                                        );
                                      },
                                      zoomControlsEnabled: false,
                                      myLocationButtonEnabled: false,
                                      liteModeEnabled: true, // ⭐ MAKE IT LIKE A STATIC PREVIEW
                                    ),
                                  ),
                                );
                              }),


                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IosTapEffect(
                                  onTap: (){

                                  },
                                  child: Container(
                                    height: 32,
                                    width: 83,
                                    decoration: BoxDecoration(
                                        color:const Color(0xFFFDE047).withOpacity(0.80),
                                        borderRadius:const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(8)
                                        )
                                    ),
                                    child:const Center(
                                      child: AppText("View map",fontSize: 14,fontWeight: FontWeight.w500,color: AppColors.color2Box,),
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
                                children: const [
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
                                      controller.addressText.value.isEmpty
                                          ? "Fetching address..."
                                          : controller.addressText.value,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w200,
                                      color: AppColors.color2Box,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    AppText(
                                      controller.currentPosition.value == null
                                          ? "--/--/----"
                                          : controller.currentPosition.value!.latitude.toString(),
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
                      ],
                    ),
                  );
                }
              }),

              // TextButton(onPressed: ()async{
              //   await http.post(
              //     Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
              //     headers: {
              //       'Content-Type': 'application/json',
              //       'X-Goog-Api-Key': 'YOUR_API_KEY',
              //       'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
              //     },
              //     body: jsonEncode({
              //       "origin": {"location": {"latLng": {"latitude": 23.8103, "longitude": 90.4125}}},
              //       "destination": {"location": {"latLng": {"latitude": 23.7912, "longitude": 90.3995}}},
              //       "travelMode": "DRIVE",
              //     }),
              //   );
              // }, child:Text("hello")),

            ],
          ),
          ),
        )
    );
  }
}

class CustomBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  const CustomBox({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (backgroundColor ?? AppColors.iconBg).withOpacity(0.10),
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        border: Border.all(
          width: borderWidth ?? 1.2,
          color: borderColor ?? AppColors.colorYellow,
        ),
      ),
      child: child,
    );
  }


}





