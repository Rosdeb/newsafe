import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppController extends GetxController{

  Future<void> openChatSMS() async {
    final smsUri = Uri.parse("sms:?body=Check this app: https://yourlink.com");
    await launchUrl(smsUri, mode: LaunchMode.externalApplication);
  }

  Future<void> openTelegram() async {
    final telegramUri = Uri.parse("tg://msg?text=Check this app: https://yourlink.com");

    if (await canLaunchUrl(telegramUri)) {
      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
    } else {
      // open telegram web fallback
      await launchUrl(
          Uri.parse("https://t.me/share/url?url=https://yourlink.com"));
    }
  }

  Future<void> openTwitter() async {
    final tweetUri = Uri.parse("twitter://post?message=Check this app: https://yourlink.com");

    if (await canLaunchUrl(tweetUri)) {
      await launchUrl(tweetUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse("https://twitter.com/intent/tweet?text=Check this app: https://yourlink.com"));
    }
  }

  Future<void> openWhatsApp() async {
    final waUri = Uri.parse("whatsapp://send?text=Check this app: https://yourlink.com");

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse("https://wa.me/?text=Check this app: https://yourlink.com"));
    }
  }

  Future<void> openEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: '',
      query: 'subject=Check this app&body=Install now: https://yourlink.com',
    );

    await launchUrl(emailUri);
  }
}