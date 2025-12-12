import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
class CountryController extends GetxController {

  final TextEditingController searchController = TextEditingController();
  RxList<Country> allCountries = <Country>[].obs;
  RxList<Country> searchResults = <Country>[].obs;
  RxString selectedCountryName = ''.obs;
  RxString selectedCountryFlag = ''.obs;
  RxString selectedCountryCode = ''.obs;
  RxBool selectedField =false.obs;

  void init() {
    allCountries.value = CountryService().getAll();
    searchResults.assignAll(allCountries);
  }

  void initialUpdate() {
    // optional post-frame setup
  }

  void updateSearchResults(String query) {
    if(query.isEmpty){
      searchResults.assignAll(allCountries);
    }else{
      searchResults.assignAll(
        allCountries
            .where((c) =>
        c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.countryCode.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );

    }
  }

  void onCrossPressed() {
    searchController.clear();
    searchResults.assignAll(allCountries);
  }

  void setCountry(BuildContext context, Country country) {
    selectedCountryName.value = country.name;
    Get.back(result: country);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }


}