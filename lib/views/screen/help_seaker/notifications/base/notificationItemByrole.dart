import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import '../../../../../controller/UserController/userController.dart';
import 'givernotificationShimmer.dart';



class NotificationShimmerByRole extends StatelessWidget {
  const NotificationShimmerByRole({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Get.find<UserController>().userRole.value;

    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) {
        if (role == "giver") {
          return const GiverNotificationItemShimmer();
        }
        return const GiverNotificationItemShimmer(); // receiver shimmer later
      },
    );
  }
}
