import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../controller/notifications/notifications_controller.dart';
import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../../../../base/Ios_effect/iosTapEffect.dart';
import '../../locations/seaker_location.dart';
class SeakernotificationItem extends StatelessWidget {
  final NotificationItemModel notification;

  const SeakernotificationItem({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBox(child:  Row(
      children: [
        if (!notification.isRead)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText(
                      notification.title,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.color2Box,
                    ),
                  ),
                  AppText(
                    _formatDate(notification.timestamp),
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                    color: AppColors.color2Box,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText(
                      notification.body,
                      fontSize: 14,
                      fontWeight: FontWeight.w100,
                      color: AppColors.color2Box,
                    ),
                  ),
                  AppText(
                    _formatTime(notification.timestamp),
                    fontSize: 14,
                    fontWeight: FontWeight.w100,
                    color: AppColors.color2Box,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (notification.distance != null) ...[
                    SvgPicture.asset("assets/icon/mi_location.svg"),
                    AppText(
                      '${notification.distance} Km distance',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.color2Box,
                    ),
                  ],
                  const Spacer(),
                  IosTapEffect(
                    onTap: () {
                      // Navigate to details page
                      // Get.snackbar(
                      //   'View Details',
                      //   'Opening details for ${notification.title}',
                      //   snackPosition: SnackPosition.BOTTOM,
                      // );
                    },
                    child: Container(
                      height: 32,
                      width: 102,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.2,
                          color: AppColors.colorYellow,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.colorYellow.withOpacity(0.40),
                      ),
                      child:const Center(
                        child: AppText(
                          "View details",
                          color: AppColors.color2Box,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ],
    ),
    );
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
