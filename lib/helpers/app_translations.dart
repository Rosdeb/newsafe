import 'package:get/get.dart';

/// Wraps the loaded locale -> key -> value map for GetMaterialApp translations.
class AppTranslations extends Translations {
  @override
  final Map<String, Map<String, String>> keys;

  AppTranslations(this.keys);
}
