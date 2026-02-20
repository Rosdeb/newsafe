import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:saferader/controller/SocketService/socket_service.dart';
import 'package:saferader/utils/logger.dart';

import '../../utils/token_service.dart';
import '../GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../SeakerHome/seakerHomeController.dart';
import '../SeakerLocation/seakerLocationsController.dart';
import '../networkService/networkService.dart';
import '../profile/profile.dart';

class SettingController extends GetxController{
  final RxInt selectedIndex = 0.obs;
  void tapSelected(int index){
    selectedIndex.value = index;
  }

  Future<void> logoutUser(BuildContext context) async {
    try {

      if (Get.isRegistered<SeakerLocationsController>()) {
        final locCtrl = Get.find<SeakerLocationsController>();
        locCtrl.stopLocationSharing();
        locCtrl.dispose();
        Get.delete<SeakerLocationsController>();
        Logger.log("✅ Location controller disposed", type: "info");
      }

      if (Get.isRegistered<SeakerHomeController>()) {
        final seekerCtrl = Get.find<SeakerHomeController>();
        if (seekerCtrl.socketService?.isConnected.value == true) {
          seekerCtrl.socketService!.socket.disconnect();
        }
        seekerCtrl.removeAllListeners();
        seekerCtrl.dispose();
        Get.delete<SeakerHomeController>();
        Logger.log("✅ Seeker controller & socket disposed", type: "info");
      }

      if (Get.isRegistered<GiverHomeController>()) {
        final giverCtrl = Get.find<GiverHomeController>();
        if (giverCtrl.socketService?.isConnected.value == true) {
          giverCtrl.socketService!.socket.disconnect();
        }
        giverCtrl.removeAllListeners();
        giverCtrl.dispose();
        Get.delete<GiverHomeController>();
        Logger.log("✅ Giver controller & socket disposed", type: "info");
      }

      if (Get.isRegistered<ProfileController>()) {
        Get.delete<ProfileController>();
      }
      await Hive.box('userProfileBox').clear();
      await TokenService().clearAll();

      Logger.log("✅ User logged out successfully", type: "success");

    }on Exception catch (e) {
      Logger.log(" Error during logout: $e", type: "error");
    }
  }


}