import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/controller/bothhomeController/bothHomeController.dart';
import 'package:saferader/views/screen/help_giver/help_giver_home/giverHome.dart';
import 'package:saferader/views/screen/help_seaker/home/seaker_home.dart';

import '../../../controller/SeakerHome/seakerHomeController.dart';
import '../../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../../utils/app_color.dart';
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        padding:const EdgeInsets.symmetric(horizontal: 16),
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
          homeHeader(),

          const SizedBox(height: 70),

          IosTapEffect(
             onTap: (){
               if (Get.isRegistered<SeakerHomeController>()) {
                 Get.delete<SeakerHomeController>();
               }
               if (Get.isRegistered<SeakerLocationsController>()) {
                 Get.delete<SeakerLocationsController>();
               }

               Navigator.push(context, MaterialPageRoute(builder: (context) => SeakerHome()));

             },
             child:  CustomBox(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 child: Column(
              children: [
                 const AppText("Help Seeker",fontSize: 18,fontWeight: FontWeight.w500,color:  Colors.black,),
                 AppText("If you need help click here",fontSize: 14,fontWeight: FontWeight.w400,color: AppColors.color2Box.withOpacity(0.50),),
              ],
                       )),
           ),

          const SizedBox(height: 20,),

          IosTapEffect(
            onTap: (){
              if (Get.isRegistered<GiverHomeController>()) {
                Get.delete<GiverHomeController>();
              }
              if (Get.isRegistered<SeakerLocationsController>()) {
                Get.delete<SeakerLocationsController>();
              }

              Navigator.push(context, MaterialPageRoute(builder: (context)=>Giverhome()));
            },
            child:  CustomBox(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
              children: [
                const AppText("Help Giver",fontSize: 18,fontWeight: FontWeight.w500,color: Colors.black,),
                 AppText("If you want to help click here",fontSize: 15,fontWeight: FontWeight.w400,color: AppColors.color2Box.withOpacity(0.50),),
              ],
            )),
          ),
        ],
      ),
      )
    );
  }

  CustomBox homeHeader() {
    return CustomBox(
      backgroundColor: AppColors.iconBg.withOpacity(0.01),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.colorYellow, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                "assets/image/8164f733772cbb414dbcbe72a6effd38ed037858.jpg",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              const AppText(
                "John Doe",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.color2Box,
              ),
              Row(
                children: [
                  Obx(
                        () => AppText(
                      "Help ${userController.userRole}",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.color2Box,
                    ),
                  ),
                  const SizedBox(width: 5),
                  IosTapEffect(
                    onTap: (){

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
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 50,
              width: 32,
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: -0,
                    child: Container(
                      height: 16,
                      width: 16,
                      decoration:const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child:const Center(
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
