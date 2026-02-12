import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../base/countices.dart';

class CountryPage extends StatelessWidget {
  CountryPage({super.key});

  final controller = Get.put(CountryController());

  @override
  Widget build(BuildContext context) {
    controller.init();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0.0,
        title: Text('Choose a country'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // ✅ Search box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a country'.tr,
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: controller.onCrossPressed,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: controller.updateSearchResults,
            ),
          ),


          Expanded(
            child: Obx(() {
              if (controller.searchResults.isEmpty) {
                return const Center(
                  child: Text('No matches found', style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.separated(
                itemCount: controller.searchResults.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey[700]),
                itemBuilder: (context, index) {
                  final country = controller.searchResults[index];
                  return ListTile(
                    onTap: () => controller.setCountry(context, country),
                    leading: Text(country.flagEmoji, style: const TextStyle(fontSize: 24)),
                    title: Text(country.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      country.displayName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Obx(
                          () => Icon(
                        Icons.check,
                        color: controller.selectedCountryName.value == country.name
                            ? Colors.green
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}