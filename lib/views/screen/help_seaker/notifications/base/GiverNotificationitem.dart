import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:saferader/utils/app_color.dart';
import '../../../../../controller/notifications/notifications_controller.dart';
import '../../../../base/AppText/appText.dart';

class GiverNotificationItem extends StatelessWidget {
  final String? title;
  final String? name;
  final String? distance;
  final String? profileImage;
  final bool isRead;
  final DateTime? timestamp;

  const GiverNotificationItem({
    Key? key,
    this.title,
    this.name,
    this.distance,
    this.profileImage,
    this.isRead = false,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: profileImage != null && profileImage!.isNotEmpty
                    ? Image.network(
                  profileImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30),
                    );
                  },
                )
                    : Container(
                  color: AppColors.colorYellow,
                  child: const Icon(Icons.person, size: 30),
                ),
              ),
            ),
            if (!isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                name ?? "Someone wants help",
                fontSize: 16,
                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                color: Colors.black87,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (distance != null) ...[
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      "${distance} km",
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      _formatTime(timestamp!),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = Get.find<NotificationsController>().currentNow.value;
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
