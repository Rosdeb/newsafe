import 'package:get/get.dart';

class WelcomeController extends GetxController{
  final RxInt selectedIndex = 0.obs;
  void tapSelected(int index){
    selectedIndex.value = index;
  }
}