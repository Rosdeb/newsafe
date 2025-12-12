import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/controller/HistoryController/historyController.dart';
import 'package:saferader/views/screen/help_seaker/history/base/history_item.dart';
import 'package:saferader/views/screen/help_seaker/history/base/shimmer.dart';

import '../../../../../utils/app_color.dart';
import '../../../../base/EmptyBox/emptybox.dart';
class Body extends StatelessWidget {
  final ScrollController scrollController;
  Body({super.key, required this.scrollController});
  Historycontroller controller = Get.find<Historycontroller>();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        backgroundColor: AppColors.colorYellow,
        displacement: 60.0,
        edgeOffset: 60.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "Activity History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              Obx(() {
                if (controller.historyList.isEmpty && controller.isLoading.value) {
                  return Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: 6,
                        itemBuilder: (context, index) => const HistoryItemPlaceholder(),
                    ),
                  );
                }

                if (controller.historyList.isEmpty) {
                  return const EmptyHistoryBox(
                      title: "No activity yet",
                      subtitle: "Your emergency history will appear here",
                      iconPath: "assets/icon/Group.svg",
                      height: 200,
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: controller.historyList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < controller.historyList.length) {
                        final item = controller.historyList[index];
                        return HistoryItem(historyModel: item);
                      } else {
                        return controller.isLoading.value
                            ? const HistoryItemPlaceholder()
                            : const SizedBox.shrink();
                      }
                    },
                  ),
                );
              }),


            ],
          ),
        ),
      ),
    );
  }
}
