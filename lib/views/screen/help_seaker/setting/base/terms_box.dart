import 'package:flutter/material.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';

import '../../../help_giver/help_giver_home/giverHome.dart';

class TermsBox extends StatelessWidget {
  const TermsBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE047).withOpacity(0.20),
        border: Border.all(
          width: 2,
          color: AppColors.colorYellow,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child:const  SingleChildScrollView(
        child: Column(
          children: [
            AppText(
              '''
**End User License Agreement & Terms of Use**
_Last updated: 2 April 2026_

**IMPORTANT: Please read this agreement carefully before using Saferadar.**

**1. Acceptance of Terms**
By downloading, installing, or using the Saferadar application ("App"), you agree to be bound by this End User License Agreement ("EULA"). If you do not agree, do not use the App.

**2. Emergency Services Disclaimer**
SAFERADAR IS NOT AN EMERGENCY SERVICE AND DOES NOT REPLACE OFFICIAL EMERGENCY SERVICES.

- This App connects individuals in distress ("Seekers") with nearby volunteers ("Givers"). It is a supplementary tool only.
- In any life-threatening situation, you must first contact your local official emergency services (e.g. 112 in Europe, 999 in the UK, 911 in North America).
- Saferadar does not dispatch police, ambulance, or fire services.
- Saferadar does not guarantee that a Giver will be available, nearby, or qualified to assist.
- Response times are not guaranteed. Do not rely solely on this App in an emergency.
- When you press the help button, your real-time GPS location is shared with nearby Givers through the App. This location data is not automatically transmitted to official emergency services. If you need emergency services to know your location, you must contact them separately.

**3. Eligibility**
You must be at least 18 years of age to use this App. By using the App, you confirm that you are 18 years of age or older. If you are under 18, do not use this App.

**4. License Grant**
Saferadar grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes, subject to this EULA.

**5. User Responsibilities**
- You agree to use the App only for genuine emergency or assistance situations.
- You will not misuse the help request feature for false alerts or non-emergency purposes.
- You are responsible for ensuring your device's location services are enabled and accurate.
- You agree not to impersonate other users or provide false information.
- Misuse of the App (including false alerts) may result in immediate account termination.

**6. Location Data**
- Your real-time GPS coordinates are shared with nearby Givers only when you actively request help.
- Location sharing stops automatically when a help request is completed.
- For full details on how we collect, use, and store location data, see our Privacy Policy at saferadarapp.com/privacy.

**7. Volunteer Helpers (Givers)**
- Givers are independent volunteers, not employees or agents of Saferadar.
- Saferadar does not vet, train, certify, or guarantee the qualifications of any Giver.
- All assistance is provided voluntarily and independently.
- Saferadar is not responsible for the conduct, actions, or omissions of any Giver.

**8. Limitation of Liability**
To the maximum extent permitted by applicable law:
- Saferadar is not liable for any direct, indirect, incidental, or consequential damages arising from use or inability to use the App.
- Saferadar is not liable for failure to connect a Seeker with a Giver, or for the quality of any assistance provided.
- Saferadar is not liable for any injury, loss, or damage resulting from reliance on this App as an alternative to official emergency services.

**9. No Medical or Professional Services**
This App does not provide medical, police, fire, or any other professional emergency services. Users act voluntarily and independently.

**10. Intellectual Property**
All content, trademarks, and technology within the App are the property of Saferadar or its licensors. You may not copy, modify, or distribute any part of the App without written permission.

**11. Account Suspension**
We may suspend or terminate accounts that misuse the App, send false alerts, or violate this EULA, without prior notice.

**12. Changes to This Agreement**
We may update this EULA at any time. Continued use of the App after changes are posted constitutes your acceptance of the revised terms. Material changes will be communicated via in-app notification or email.

**13. Governing Law**
This EULA is governed by the laws of the Netherlands. Any disputes shall be subject to the exclusive jurisdiction of the courts of Amsterdam, the Netherlands.

**14. Contact**
Saferadar B.V. | Amsterdam, Netherlands
Email: saferadarapp@gmail.com
Support: Settings > Help & Support in the App

By tapping "I Agree", you confirm you have read, understood, and accepted this EULA.
''',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.color2Box,
            ),
           // BannerAds(),
          ],
        ),
      ),
    );
  }
}
