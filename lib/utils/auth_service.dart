import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:saferader/utils/logger.dart';

class AuthService {
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenService().getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        Logger.log(" No refresh token available", type: "error");
        return false;
      }

      final url = "${AppConstants.BASE_URL}/api/auth/refresh-token";

      Logger.log("🔄 Attempting to refresh token...", type: "info");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      Logger.log("Refresh Response Status: ${response.statusCode}", type: "info");
      Logger.log("Refresh Response Body: ${response.body}", type: "info");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final newAccessToken = data["accessToken"] ?? data["access_token"];
        final newRefreshToken = data["refreshToken"] ?? data["refresh_token"];

        if (newAccessToken != null && newRefreshToken != null) {
          await TokenService().saveToken(newAccessToken);
          await TokenService().saveRefreshToken(newRefreshToken);
          await TokenService().reloadTokens();

          Logger.log("Token refreshed and reloaded successfully!", type: "info");
          return true;
        } else {
          Logger.log("New tokens not found in response", type: "warning");
          return false;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await TokenService().clearAll();
        return false;
      } else {
        Logger.log("❌ Token refresh failed with status: ${response.statusCode}", type: "error");
        return false;
      }
    } catch (e, stackTrace) {
      Logger.log("Stack trace: $stackTrace", type: "error");
      return false;
    }
  }

  static Future<void> logout() async {
    await TokenService().clearAll();
    Logger.log("✅ User logged out successfully", type: "info");
  }
}