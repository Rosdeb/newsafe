import 'package:get/get.dart';
import '../SeakerLocation/seakerLocationsController.dart';

class BottomNavController extends GetxController{
  final SeakerLocationsController controller = Get.put(SeakerLocationsController());
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    controller.startLiveLocation();
  }


  void selectTab(int index) {
    selectedIndex.value = index;
  }

  void notification(int index){
    selectedIndex.value = index;
  }

}