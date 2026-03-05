import 'package:saferader/utils/token_service.dart';
import 'package:saferader/utils/logger.dart';
import 'api_service.dart';
import 'package:get/get.dart';
import '../../views/screen/welcome/welcome_sreen.dart';

class AuthService {
  // Prevent infinite refresh loops
  static int _refreshAttempts = 0;
  static DateTime? _lastRefreshAttempt;
  static const int _maxRefreshAttempts = 3;
  static const Duration _refreshCooldown = Duration(seconds: 5);

  static Future<bool> refreshToken() async {
    try {
      // Check for infinite loop protection
      final now = DateTime.now();
      if (_refreshAttempts >= _maxRefreshAttempts) {
        if (_lastRefreshAttempt == null ||
            now.difference(_lastRefreshAttempt!) < _refreshCooldown) {
          Logger.log("🛑 Too many refresh attempts, forcing logout", type: "error");
          await _forceLogout();
          return false;
        }
        // Reset counter after cooldown
        _refreshAttempts = 0;
      }

      _refreshAttempts++;
      _lastRefreshAttempt = now;

      final refreshToken = await TokenService().getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        Logger.log(" No refresh token available", type: "error");
        await _forceLogout();
        return false;
      }

      Logger.log("🔄 Attempting to refresh token... (attempt $_refreshAttempts/$_maxRefreshAttempts)", type: "info");

      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/refresh-token',
        body: {"refreshToken": refreshToken},
        requiresAuth: false,
      );

      if (response != null) {
        final newAccessToken = response["accessToken"] ?? response["access_token"];
        final newRefreshToken = response["refreshToken"] ?? response["refresh_token"];

        if (newAccessToken != null && newRefreshToken != null) {
          await TokenService().saveToken(newAccessToken);
          await TokenService().saveRefreshToken(newRefreshToken);
          await TokenService().reloadTokens();

          Logger.log("Token refreshed and reloaded successfully!", type: "success");
          _refreshAttempts = 0; // Reset on success
          return true;
        } else {
          Logger.log("New tokens not found in response", type: "warning");
          await _forceLogout();
          return false;
        }
      } else {
        Logger.log("Token refresh failed", type: "error");
        await _forceLogout();
        return false;
      }
    } catch (e, stackTrace) {
      Logger.log("Stack trace: $stackTrace", type: "error");
      await _forceLogout();
      return false;
    }
  }

  /// Force logout and navigate to welcome screen
  static Future<void> _forceLogout() async {
    Logger.log("🚪 Forcing logout due to unrecoverable auth error", type: "warning");
    await TokenService().clearAll();

    // Navigate to welcome screen if we have a navigator context
    if (Get.context != null) {
      Get.offAll(() => WelcomeSreen());
    }
  }

  static Future<bool> validateToken() async {
    try {
      final token = await TokenService().getToken();

      if (token == null || token.isEmpty) {
        Logger.log('No token available for validation', type: 'warning');
        return false;
      }

      // Test the token by making a simple API call that requires authentication
      final apiService = ApiService();
      final response = await apiService.get(
        endpoint: '/api/users/me',
        requiresAuth: true,
      );

      if (response != null) {
        final isValid = response['isValid'] ?? response['success'] ?? false;
        Logger.log('Token validation result: $isValid', type: 'info');
        return isValid;
      } else {
        Logger.log('Token validation failed - 401 Unauthorized', type: 'warning');
        return false;
      }
    } catch (e) {
      Logger.log('Error during token validation: $e', type: 'error');
      return false;
    }
  }

  /// Validates the token and attempts to refresh if invalid
  /// Returns true if token is valid or successfully refreshed, false otherwise
  static Future<bool> validateAndRefreshToken() async {
    Logger.log('Starting token validation and refresh process', type: 'info');

    // First, try to validate the current token
    bool isValid = await validateToken();

    if (isValid) {
      Logger.log('Token is valid, no refresh needed', type: 'success');
      return true;
    }

    Logger.log('Token is invalid or expired, attempting refresh', type: 'info');

    // Token is invalid, try to refresh it
    bool refreshSuccess = await refreshToken();

    if (refreshSuccess) {
      Logger.log('Token successfully refreshed', type: 'success');
      return true;
    } else {
      Logger.log('Failed to refresh token', type: 'error');
      return false;
    }
  }


  static Future<void> logout() async {
    await TokenService().clearAll();
    Logger.log("✅ User logged out successfully", type: "info");
  }
}