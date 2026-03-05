import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import '../../utils/token_service.dart';
import '../controller/networkService/networkService.dart';
import 'app_constant.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final TokenService _tokenService = TokenService();


  // lib/Service/auth/Api_Services.dart - ADD THIS METHOD
  Future<String?> getRawBody({
    required String endpoint,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();
    if (!networkController.isOnline.value) throw Exception('No internet connection');

    String url = '${AppConstants.BASE_URL}$endpoint';
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      String? token = await _tokenService.getToken();
      if (token == null || token.isEmpty) throw Exception('No access token');
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    if (headers != null) requestHeaders.addAll(headers);

    final response = await http.get(Uri.parse(url), headers: requestHeaders);

    if (response.statusCode == 200) return response.body;
    if (response.statusCode == 401) {
      bool refreshed = await _handleTokenRefresh();
      if (refreshed) {
        String? newToken = await _tokenService.getToken();
        if (newToken != null) requestHeaders['Authorization'] = 'Bearer $newToken';
        final retry = await http.get(Uri.parse(url), headers: requestHeaders);
        return retry.statusCode == 200 ? retry.body : null;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> get({
    required String endpoint,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      Map<String, String> requestHeaders = {};
      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      requestHeaders['Content-Type'] = 'application/json';

      Logger.log('Making GET request to: $url', type: 'info');

      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      Logger.log('GET Response Status: ${response.statusCode}', type: 'info');
      Logger.log('GET Response Body: ${response.body}', type: 'info');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          Map<String, String> retryHeaders = {};
          if (requiresAuth) {
            String? newToken = await _tokenService.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
          }

          if (headers != null) {
            retryHeaders.addAll(headers);
          }
          retryHeaders['Content-Type'] = 'application/json';

          final retryResponse = await http.get(
            Uri.parse(url),
            headers: retryHeaders,
          );

          Logger.log('Retry GET Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          } else {
            _handleErrorResponse(retryResponse.statusCode, response.body);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, response.body);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, response.body);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making GET request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> post({
    required String endpoint,
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      Map<String, String> requestHeaders = {};
      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      requestHeaders['Content-Type'] = 'application/json';

      String bodyString = body != null ? json.encode(body) : '';

      Logger.log('Making POST request to: $url', type: 'info');
      Logger.log('POST Request Body: $bodyString', type: 'info');

      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: bodyString,
      );

      Logger.log('POST Response Status: ${response.statusCode}', type: 'info');
      Logger.log('POST Response Body: ${response.body}', type: 'info');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          Map<String, String> retryHeaders = {};
          if (requiresAuth) {
            String? newToken = await _tokenService.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
          }

          if (headers != null) {
            retryHeaders.addAll(headers);
          }
          retryHeaders['Content-Type'] = 'application/json';

          final retryResponse = await http.post(
            Uri.parse(url),
            headers: retryHeaders,
            body: bodyString,
          );

          Logger.log('Retry POST Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          } else {
            _handleErrorResponse(retryResponse.statusCode, response.body);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, response.body);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, response.body);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making POST request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> put({
    required String endpoint,
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      Map<String, String> requestHeaders = {};
      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      requestHeaders['Content-Type'] = 'application/json';

      String bodyString = body != null ? json.encode(body) : '';

      Logger.log('Making PUT request to: $url', type: 'info');
      Logger.log('PUT Request Body: $bodyString', type: 'info');

      final response = await http.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: bodyString,
      );

      Logger.log('PUT Response Status: ${response.statusCode}', type: 'info');
      Logger.log('PUT Response Body: ${response.body}', type: 'info');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          Map<String, String> retryHeaders = {};
          if (requiresAuth) {
            String? newToken = await _tokenService.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
          }

          if (headers != null) {
            retryHeaders.addAll(headers);
          }
          retryHeaders['Content-Type'] = 'application/json';

          final retryResponse = await http.put(
            Uri.parse(url),
            headers: retryHeaders,
            body: bodyString,
          );

          Logger.log('Retry PUT Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          } else {
            _handleErrorResponse(retryResponse.statusCode, response.body);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, response.body);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, response.body);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making PUT request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> delete({
    required String endpoint,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      Map<String, String> requestHeaders = {};
      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      requestHeaders['Content-Type'] = 'application/json';

      Logger.log('Making DELETE request to: $url', type: 'info');

      final response = await http.delete(
        Uri.parse(url),
        headers: requestHeaders,
      );

      Logger.log('DELETE Response Status: ${response.statusCode}', type: 'info');
      Logger.log('DELETE Response Body: ${response.body}', type: 'info');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          Map<String, String> retryHeaders = {};
          if (requiresAuth) {
            String? newToken = await _tokenService.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
          }

          if (headers != null) {
            retryHeaders.addAll(headers);
          }
          retryHeaders['Content-Type'] = 'application/json';

          final retryResponse = await http.delete(
            Uri.parse(url),
            headers: retryHeaders,
          );

          Logger.log('Retry DELETE Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200 || response.statusCode ==201) {
            return true;
          } else {
            _handleErrorResponse(retryResponse.statusCode, response.body);
            return false;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, response.body);
          return false;
        }
      } else {
        _handleErrorResponse(response.statusCode, response.body);
        return false;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making DELETE request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> _handleTokenRefresh() async {
    Logger.log('Attempting to refresh token using AuthService...', type: 'info');

    // Use the enhanced AuthService to handle token validation and refresh
    bool result = await AuthService.validateAndRefreshToken();

    if (result) {
      Logger.log('Token validated and/or refreshed successfully via AuthService', type: 'success');
      return true;
    } else {
      Logger.log('Failed to validate and refresh token via AuthService', type: 'error');
      return false;
    }
  }

  /// Handle 401 unauthorized error
  /// This typically means we need to log out the user
  Future<void> _handleUnauthorized() async {
    Logger.log('401 Unauthorized - Logging out user', type: 'warning');

    // Clear all stored tokens and user data
    await AuthService.logout();

    // For now, we'll just log it
    Logger.log('User logged out due to unauthorized access', type: 'info');
  }

  /// Helper method to handle error responses
  void _handleErrorResponse(int statusCode, String responseBody) {
    Logger.log('Request failed with status: $statusCode', type: 'error');
    Logger.log('Response body: $responseBody', type: 'error');

    switch (statusCode) {
      case 400:
        Logger.log('Bad Request', type: 'error');
        break;
      case 401:
        Logger.log('Unauthorized - Invalid or expired token', type: 'error');
        break;
      case 403:
        Logger.log('Forbidden', type: 'error');
        break;
      case 404:
        Logger.log('Not Found', type: 'error');
        break;
      case 500:
        Logger.log('Internal Server Error', type: 'error');
        break;
      default:
        Logger.log('Unknown error with status code: $statusCode', type: 'error');
    }
  }

  Future<dynamic> getRaw({
    required String endpoint,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      Map<String, String> requestHeaders = {};
      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      requestHeaders['Content-Type'] = 'application/json';

      Logger.log('Making GET request to: $url', type: 'info');

      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      Logger.log('GET Response Status: ${response.statusCode}', type: 'info');
      Logger.log('GET Response Body: ${response.body}', type: 'info');

      if (response.statusCode == 200) {
        // Return either Map or List depending on the response
        var decoded = json.decode(response.body);
        return decoded;
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          Map<String, String> retryHeaders = {};
          if (requiresAuth) {
            String? newToken = await _tokenService.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              retryHeaders['Authorization'] = 'Bearer $newToken';
            }
          }

          if (headers != null) {
            retryHeaders.addAll(headers);
          }
          retryHeaders['Content-Type'] = 'application/json';

          final retryResponse = await http.get(
            Uri.parse(url),
            headers: retryHeaders,
          );

          Logger.log('Retry GET Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200) {
            var decoded = json.decode(retryResponse.body);
            return decoded;
          } else {
            _handleErrorResponse(retryResponse.statusCode, response.body);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, response.body);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, response.body);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making GET request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> patchWithMultipart({
    required String endpoint,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      var request = http.MultipartRequest('PATCH', Uri.parse(url));

      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        request.headers.addAll(headers);
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      Logger.log('Making PATCH multipart request to: $url', type: 'info');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      Logger.log('PATCH multipart Response Status: ${response.statusCode}', type: 'info');
      Logger.log('PATCH multipart Response Body: $responseBody', type: 'info');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          var retryRequest = http.MultipartRequest('PATCH', Uri.parse(url));

          String? newToken = await _tokenService.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          }

          if (headers != null) {
            retryRequest.headers.addAll(headers);
          }

          if (fields != null) {
            retryRequest.fields.addAll(fields);
          }

          if (files != null) {
            retryRequest.files.addAll(files);
          }

          final retryResponse = await retryRequest.send();
          final retryResponseBody = await retryResponse.stream.bytesToString();

          Logger.log('Retry PATCH multipart Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
            return json.decode(retryResponseBody);
          } else {
            _handleErrorResponse(retryResponse.statusCode, retryResponseBody);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, responseBody);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, responseBody);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making PATCH multipart request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> putWithMultipart({
    required String endpoint,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      throw Exception('No internet connection');
    }

    String url = '${AppConstants.BASE_URL}$endpoint';

    try {
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      if (requiresAuth) {
        String? token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('No access token available');
        }
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (headers != null) {
        request.headers.addAll(headers);
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      Logger.log('Making PATCH multipart request to: $url', type: 'info');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      Logger.log('PATCH multipart Response Status: ${response.statusCode}', type: 'info');
      Logger.log('PATCH multipart Response Body: $responseBody', type: 'info');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else if (response.statusCode == 401) {
        bool refreshed = await _handleTokenRefresh();
        if (refreshed) {
          var retryRequest = http.MultipartRequest('PATCH', Uri.parse(url));

          String? newToken = await _tokenService.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            retryRequest.headers['Authorization'] = 'Bearer $newToken';
          }

          if (headers != null) {
            retryRequest.headers.addAll(headers);
          }

          if (fields != null) {
            retryRequest.fields.addAll(fields);
          }

          if (files != null) {
            retryRequest.files.addAll(files);
          }

          final retryResponse = await retryRequest.send();
          final retryResponseBody = await retryResponse.stream.bytesToString();

          Logger.log('Retry PATCH multipart Response Status: ${retryResponse.statusCode}', type: 'info');

          if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
            return json.decode(retryResponseBody);
          } else {
            _handleErrorResponse(retryResponse.statusCode, retryResponseBody);
            return null;
          }
        } else {
          await _handleUnauthorized();
          _handleErrorResponse(response.statusCode, responseBody);
          return null;
        }
      } else {
        _handleErrorResponse(response.statusCode, responseBody);
        return null;
      }
    } on SocketException {
      Logger.log('Socket exception (no internet connection)', type: 'error');
      throw Exception('No internet connection');
    } on HttpException {
      Logger.log('HTTP exception occurred', type: 'error');
      throw Exception('HTTP error occurred');
    } catch (e) {
      Logger.log('Error making PATCH multipart request: $e', type: 'error');
      throw Exception('Network error: $e');
    }
  }


}