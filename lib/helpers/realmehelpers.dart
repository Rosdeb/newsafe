import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class RealmeHelper {
  static Future<void> showRealmeSetupGuide() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Setup Required for Realme Devices'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To ensure SafeRader works properly on your Realme device, please complete these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildStep('1', 'Enable Auto-Start',
                  'Settings → App Management → SafeRader → Auto-Start → Enable'),
              const SizedBox(height: 10),
              _buildStep('2', 'Disable Battery Optimization',
                  'Settings → Battery → More → Optimise Battery Use → SafeRader → Don\'t Optimize'),
              const SizedBox(height: 10),
              _buildStep('3', 'Allow Background Running',
                  'Settings → App Management → SafeRader → App Battery Usage → No restrictions'),
              const SizedBox(height: 10),
              _buildStep('4', 'Lock App in Recent Apps',
                  'Open Recent Apps → Find SafeRader → Pull down to lock'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Permission.ignoreBatteryOptimizations.request();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration:const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const  SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const  SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}