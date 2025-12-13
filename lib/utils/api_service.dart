import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:saferader/utils/logger.dart';

class ApiService {
  /// ------------------------
  /// HTTP GET
  /// ------------------------
  static Future<http.Response> get(String endpoint,
      {Map<String, String>? headers}) async {
    return _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
    );
  }

  /// ------------------------
  /// HTTP POST
  /// ------------------------
  static Future<http.Response> post(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    return _makeRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
    );
  }

  /// ------------------------
  /// HTTP PUT
  /// ------------------------
  static Future<http.Response> put(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    return _makeRequest(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
    );
  }

  /// ------------------------
  /// HTTP DELETE
  /// ------------------------
  static Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers}) async {
    return _makeRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
    );
  }

  /// ------------------------
  /// Generic request with retry on 401
  /// ------------------------
  static Future<http.Response> _makeRequest({
    required String method,
    required String endpoint,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _sendRequest(
      method: method,
      endpoint: endpoint,
      body: body,
      headers: headers,
    );

    if (response.statusCode != 401) return response;

    Logger.log(
      "🔄 $method request to $endpoint failed with 401 - refreshing token",
      type: "info",
    );

    final refreshSuccess = await AuthService.refreshToken();

    if (refreshSuccess) {
      Logger.log("✅ Token refreshed, retrying $method request", type: "info");
      response = await _sendRequest(
        method: method,
        endpoint: endpoint,
        body: body,
        headers: headers,
      );
    } else {
      Logger.log(
        "❌ Token refresh failed for $method request to $endpoint",
        type: "error",
      );
    }

    return response;
  }

  /// ------------------------
  /// Send actual HTTP request
  /// ------------------------
  static Future<http.Response> _sendRequest({
    required String method,
    required String endpoint,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${AppConstants.BASE_URL}$endpoint');
    final requestHeaders = await _buildHeaders(
      additionalHeaders: headers,
      includeContentType: body != null,
    );

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: requestHeaders);
      case 'POST':
        return http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? (body is String ? body : jsonEncode(body)) : null,
        );
      case 'PUT':
        return http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? (body is String ? body : jsonEncode(body)) : null,
        );
      case 'DELETE':
        return http.delete(uri, headers: requestHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  /// ------------------------
  /// Build headers (Named parameters)
  /// ------------------------
  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeContentType = true,
  }) async {
    final headers = <String, String>{};

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await TokenService().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// ------------------------
  /// Multipart request with token refresh
  /// ------------------------
  static Future<http.StreamedResponse> multipart(
      String endpoint,
      http.MultipartRequest multipartRequest,
      ) async {
    final token = await TokenService().getToken();
    if (token != null && token.isNotEmpty) {
      multipartRequest.headers['Authorization'] = 'Bearer $token';
    }

    var response = await multipartRequest.send();

    if (response.statusCode == 401) {
      Logger.log(
        "🔄 Multipart request to $endpoint failed with 401 - refreshing token",
        type: "info",
      );

      final refreshSuccess = await AuthService.refreshToken();

      if (refreshSuccess) {
        Logger.log("✅ Token refreshed, retrying multipart request", type: "info");
        final newToken = await TokenService().getToken();
        if (newToken != null && newToken.isNotEmpty) {
          multipartRequest.headers['Authorization'] = 'Bearer $newToken';
        }
        response = await multipartRequest.send();
      } else {
        Logger.log(
          "❌ Token refresh failed for multipart request to $endpoint",
          type: "error",
        );
      }
    }

    return response;
  }
}
