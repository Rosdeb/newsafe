import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _refreshTokenKey = 'refresh_token';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences (call this at app startup)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Save access token
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_accessTokenKey, token);
    print("✅ Access token saved");
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_refreshTokenKey, token);
    print("✅ Refresh token saved");
  }

  /// Get access token - ALWAYS reads fresh from SharedPreferences
  /// IMPORTANT: This method is now async to ensure fresh token after refresh
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    final token = prefs.getString(_accessTokenKey);
    return token;
  }

  /// Get refresh token - ALWAYS reads fresh from SharedPreferences
  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  /// Update access token (use this after token refresh)
  Future<void> updateAccessToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_accessTokenKey, token);
    print("🔄 Access token updated");
  }

  /// Remove access token
  Future<void> removeToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(_accessTokenKey);
    print("🗑️ Access token removed");
  }

  /// Remove refresh token
  Future<void> removeRefreshToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(_refreshTokenKey);
    print("🗑️ Refresh token removed");
  }

  /// Save user ID
  Future<void> saveUserId(String id) async {
    final prefs = await _getPrefs();
    await prefs.setString(_userIdKey, id);
  }

  /// Get user ID - made async for consistency
  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userIdKey);
  }

  /// Remove user ID
  Future<void> removeUserId() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userIdKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    print("🗑️ All tokens and data cleared");
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if refresh token exists
  Future<bool> hasRefreshToken() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Force reload from SharedPreferences (useful after token refresh)
  Future<void> reloadTokens() async {
    // Since we always read fresh from SharedPreferences now,
    // this just ensures _prefs is up to date
    _prefs = await SharedPreferences.getInstance();
    print("🔄 Tokens reloaded from SharedPreferences");
  }
}