// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:saferader/controller/UserController/userController.dart';
// import 'package:saferader/controller/notifications/notifications_controller.dart';
// import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
// import 'package:saferader/views/screen/help_seaker/notifications/base/seakerNotification.dart';
// import '../../../../Models/notification.dart';
// import '../../../base/EmptyBox/emptybox.dart';
// import '../../../../utils/app_color.dart';
// import '../../../../views/base/AppText/appText.dart';
// import '../../../base/Ios_effect/iosTapEffect.dart';
// import 'base/GiverNotificationitem.dart';
// import 'base/givernotificationShimmer.dart';
// import 'base/notificationItemByrole.dart';
//
// class SeakerNotifications extends StatelessWidget {
//   SeakerNotifications({super.key});
//
//   final notificationsController = Get.put(NotificationsController());
//   final userController = Get.put(UserController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.centerRight,
//             end: Alignment.centerLeft,
//             colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
//             stops: [0.0046, 0.5005, 0.9964],
//           ),
//         ),
//         child: RefreshIndicator(
//           backgroundColor: AppColors.colorYellow,
//           displacement: 60.0,
//           edgeOffset: 60.0,
//           onRefresh:()=> notificationsController.fetchNotifications(context: context),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 18.0),
//             child: Column(
//               children: [
//
//                 const SizedBox(height: 60),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Notification",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black,
//                       ),
//                     ),
//
//
//                     Row(
//                       children: [
//                         Obx(() {
//                           final unreadCount = notificationsController.unreadCount;
//                           if (unreadCount > 0) {
//                             return Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 '$unreadCount',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         }),
//
//                         const SizedBox(width: 8),
//
//                       ],
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 14),
//               Obx(() {
//                 // 1️⃣ LOADING STATE → SHIMMER
//                 if (notificationsController.isLoading.value) {
//                   return const Expanded(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 16),
//                       child: NotificationShimmerByRole(),
//                     ),
//                   );
//                 }
//
//                   if (notificationsController.notifications.isEmpty) {
//                     return const EmptyHistoryBox(
//                         title: "No notification yet",
//                         subtitle: "Your notification will appear here",
//                         iconPath: "assets/icon/notifications.svg",
//                         height: 200,
//                     );
//                   }
//
//
//                   if (userController.userRole.value == "giver") {
//                     return Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         itemCount: notificationsController.notifications.length,
//                         itemBuilder: (_, index) {
//                           final notification = notificationsController.notifications[index];
//                           return Dismissible(
//                             key: Key(notification.id),
//                             background: Container(
//                               margin: const EdgeInsets.symmetric(vertical: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               alignment: Alignment.centerRight,
//                               padding: const EdgeInsets.only(right: 20),
//                               child: const Icon(
//                                 Icons.delete,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             direction: DismissDirection.endToStart,
//                             onDismissed: (direction) {
//                               notificationsController.deleteNotification(notification.id);
//                             },
//                             child: GestureDetector(
//                               onTap: () {
//                                 notificationsController.markAsRead(notification.id);
//                                 _showNotificationDetails(context,notification);
//                               },
//                               child: SeakernotificationItem(
//                                 notification: notification,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   } else {
//                     return Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(vertical: 8.0),
//                         itemCount: notificationsController.notifications.length,
//                         itemBuilder: (_, index) {
//                           final notification = notificationsController.notifications[index];
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Dismissible(
//                               key: Key(notification.id),
//                               background: Container(
//                                 margin: const EdgeInsets.symmetric(vertical: 8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 alignment: Alignment.centerRight,
//                                 padding: const EdgeInsets.only(right: 20),
//                                 child: const Icon(
//                                   Icons.delete,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               direction: DismissDirection.endToStart,
//                               onDismissed: (direction) {
//                                 notificationsController.deleteNotification(notification.id);
//                               },
//                               child: GestureDetector(
//                                 onTap: () {
//                                   notificationsController.markAsRead(notification.id);
//                                   _showNotificationDetails(context,notification);
//                                 },
//                                 child: CustomBox(
//                                   child: GiverNotificationItem(
//                                     title: notification.title,
//                                     name: notification.body,
//                                     distance: notification.distance,
//                                     profileImage: notification.userImage,
//                                     isRead: notification.isRead,
//                                     timestamp: notification.timestamp,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   }
//                 }),
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   void _showNotificationDetails(BuildContext context, NotificationItemModel notification) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.transparent,
//       builder: (context) => AlertDialog(
//         title: Text(notification.title),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(notification.body),
//             const SizedBox(height: 16),
//             if (notification.distance != null)
//               Row(
//                 children: [
//                   const Icon(Icons.location_on, size: 16),
//                   const SizedBox(width: 4),
//                   Text('${notification.distance} km away'),
//                 ],
//               ),
//             const SizedBox(height: 8),
//             Text(
//               _formatTimestamp(notification.timestamp),
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);
//
//     if (difference.inMinutes < 1) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
//     }
//   }
// }
//
//
//
//
// class GradientButtons extends StatelessWidget {
//   final VoidCallback onTap;
//   final String text;
//   final IconData? icon;
//   final double height;
//   final double borderRadius;
//   final List<Color>? gradientColors;
//
//   const GradientButtons({
//     super.key,
//     required this.onTap,
//     required this.text,
//     this.icon,
//     this.height = 48,
//     this.borderRadius = 10,
//     this.gradientColors,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return IosTapEffect(
//       onTap: onTap,
//       child: Container(
//         height: height,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(borderRadius),
//           gradient: LinearGradient(
//             begin:const Alignment(0,0),
//             end:const Alignment(0.0,0.0),
//             colors:
//             gradientColors ?? const [Color(0xFF0DB17B), Color(0xFF06996B)],
//           ),
//         ),
//         child: Center(
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (icon != null) ...[
//                 Icon(icon, color: Colors.white),
//                 const SizedBox(width: 8),
//               ],
//               AppText(
//                 text,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.colorWhite,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/controller/notifications/notifications_controller.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/base/seakerNotification.dart';
import '../../../../Models/notification.dart';
import '../../../base/EmptyBox/emptybox.dart';
import '../../../../utils/app_color.dart';
import '../../../../views/base/AppText/appText.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import 'base/GiverNotificationitem.dart';
import 'base/givernotificationShimmer.dart';
import 'base/notificationItemByrole.dart';

class SeakerNotifications extends StatelessWidget {
  SeakerNotifications({super.key});

  final notificationsController = Get.put(NotificationsController());
  final userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Notification",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Obx(() {
                        final unreadCount = notificationsController.unreadCount;
                        if (unreadCount > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: Obx(() {
                  // LOADING STATE → SHIMMER
                  if (notificationsController.isLoading.value &&
                      notificationsController.notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: NotificationShimmerByRole(),
                    );
                  }

                  // EMPTY STATE with RefreshIndicator
                  if (notificationsController.notifications.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            EmptyHistoryBox(
                              title: "No notification yet",
                              subtitle: "Your notification will appear here",
                              iconPath: "assets/icon/notifications.svg",
                              height: 200,
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  }

                  // GIVER ROLE NOTIFICATIONS
                  if (userController.userRole.value == "giver") {
                    return RefreshIndicator(
                      color: AppColors.colorYellow,
                      backgroundColor: Colors.white,
                      onRefresh: () => notificationsController.fetchNotifications(
                        context: context,
                      ),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: notificationsController.notifications.length,
                        itemBuilder: (_, index) {
                          final notification =
                              notificationsController.notifications[index];
                          return Dismissible(
                            key: Key(notification.id),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              notificationsController.deleteNotification(
                                notification.id,
                              );
                            },
                            child: GestureDetector(
                              onTap: () {
                                notificationsController.markAsRead(
                                  notification.id,
                                );
                                _showNotificationDetails(context, notification);
                              },
                              child: SeakernotificationItem(
                                notification: notification,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  // SEEKER ROLE NOTIFICATIONS
                  return RefreshIndicator(
                    color: AppColors.colorYellow,
                    backgroundColor: Colors.white,
                    onRefresh: () => notificationsController.fetchNotifications(
                      context: context,
                    ),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: notificationsController.notifications.length,
                      itemBuilder: (_, index) {
                        final notification =
                            notificationsController.notifications[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Dismissible(
                            key: Key(notification.id),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              notificationsController.deleteNotification(
                                notification.id,
                              );
                            },
                            child: GestureDetector(
                              onTap: () {
                                notificationsController.markAsRead(
                                  notification.id,
                                );
                                _showNotificationDetails(context, notification);
                              },
                              child: CustomBox(
                                child: GiverNotificationItem(
                                  title: notification.title,
                                  name: notification.body,
                                  distance: notification.distance,
                                  profileImage: notification.userImage,
                                  isRead: notification.isRead,
                                  timestamp: notification.timestamp,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationItemModel notification,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            if (notification.distance != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text('${notification.distance} km away'),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class GradientButtons extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final List<Color>? gradientColors;

  const GradientButtons({
    super.key,
    required this.onTap,
    required this.text,
    this.icon,
    this.height = 48,
    this.borderRadius = 10,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: const Alignment(0, 0),
            end: const Alignment(0.0, 0.0),
            colors:
                gradientColors ?? const [Color(0xFF0DB17B), Color(0xFF06996B)],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
              ],
              AppText(
                text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.colorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
