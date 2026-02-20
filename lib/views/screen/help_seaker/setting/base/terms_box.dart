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
**Terms of Use & Privacy Policy**  
_Last updated: 15 September 2025_

**1. Introduction**  
Welcome to “Safe Rader”. By downloading, installing, or using this app, you agree to the following Terms of Use and Privacy Policy.  
If you do not agree, please do not use the app.

**2. Purpose of the App**  
This app is designed to connect individuals in emergency situations with nearby people who may be able to assist.  
It is not a substitute for contacting official emergency services (such as 999/911).  
In life-threatening situations, always contact official authorities first.

**3. Eligibility**  
You must be at least 13 years old to use this app.  
By using the app, you confirm that you meet this requirement.

**4. User Responsibilities**  
- You agree to use the app only for genuine emergency or assistance needs.  
- You will not misuse the panic button for false alerts or non-emergency purposes.  
- You are responsible for the accuracy of your location and personal information.

**5. Privacy and Data Use**  
- Your location is shared only when you press the panic button.  
- Location data is used solely to connect you with nearby helpers during emergencies.  
- We do not sell or share your personal data with third parties.  
- Personal information is stored securely and used only for providing app functionality.

**6. Limitation of Liability**  
We are not responsible for the actions of users (helpers or those requesting help).  
We cannot guarantee that help will always be available.  
All assistance is provided by independent individuals, not by Safe Rader.  
We are not liable for any damages, injuries, losses, or disputes that may arise from the use of this app.

**7. No Medical or Professional Guarantee**  
This app does not provide medical, police, or professional emergency services. Users act voluntarily and independently.

**8. Account Suspension or Termination**  
We may suspend or terminate accounts that misuse the app, send false alerts, or violate these Terms.

**9. Changes to Terms and Policy**  
We may update these Terms of Use and Privacy Policy at any time.  
Continued use of the app means you accept the updated terms.

**10. Governing Law**  
These Terms are governed by the laws of [Your Country].  
Any disputes will be handled under the jurisdiction of local courts.
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
