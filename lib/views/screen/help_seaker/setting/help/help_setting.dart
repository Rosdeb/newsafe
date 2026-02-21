import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../../../help_giver/help_giver_home/giverHome.dart';
import '../base/headers.dart';

class HelpSetting extends StatelessWidget {
  HelpSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
          child: Column(
            children: [
              SizedBox(height: size.height * 0.07),
              Headers(
                iconPath: "assets/icon/Vector.svg",
                title: "Help",
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE047).withOpacity(0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.colorYellow,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "${index + 1}. ${item["title"]}",
                              // concatenate number and title
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['subtitle'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                letterSpacing: 0,
                                color: AppColors.colorStroke,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // const Padding(
              //   padding:  EdgeInsets.symmetric(horizontal: 18.0),
              //   child: BannerAds(),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> items = [
    {
      "title": "What is this app used for?",
      "subtitle":
          "This app is designed to connect people in emergencies with nearby helpers. By pressing the panic button, your live location is shared, and a notification is sent to individuals within your area who can assist.",
    },
    {
      "title": "How far does the emergency alert reach?",
      "subtitle":
          "This app is designed to connect people in emergencies with nearby helpers. By pressing the panic button, your live location is shared, and a notification is sent to individuals within your area who can assist.",
    },
    {
      "title": "Do I need internet to use the app?",
      "subtitle":
          "Yes, the app requires an active internet connection (WiFi or mobile data) to send alerts and share your live location with nearby helpers",
    },
    {
      "title": "Who will receive my emergency alert?",
      "subtitle":
          "Your alert will be sent to people nearby within the set radius who are available and willing to help.",
    },
    {
      "title": "Is my data location safe?",
      "subtitle":
          "Absolutely. Your location is only shared when you press the panic button, and it is visible only to verified nearby helpers.",
    },
  ];
}
