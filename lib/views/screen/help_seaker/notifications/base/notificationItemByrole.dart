import 'package:flutter/material.dart';
import 'givernotificationShimmer.dart';



class NotificationShimmerByRole extends StatelessWidget {
  const NotificationShimmerByRole({super.key});

  @override
  Widget build(BuildContext context) {
    // Unified role: all users can be seeker and giver; show same notification list
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const GiverNotificationItemShimmer(),
    );
  }
}
