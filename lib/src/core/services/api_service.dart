import 'dart:convert';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // TODO: Replace with your actual Spring Backend URL
  static const String _backendUrl = 'http://localhost:8080';

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$_backendUrl$endpoint');
    String? accessToken = await StorageService().getToken();

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
    
    print('ApiService: POST $url');
    print('ApiService: Headers: $requestHeaders');

    var response = await http.post(url, headers: requestHeaders, body: body);

    // Check for Token Expiry (4002) or Unauthorized (401)
    if (response.statusCode == 4003 || response.statusCode == 4002 || response.statusCode == 401) {
       print('ApiService: Caught status ${response.statusCode}. Checking body for 4002...');
       try {
         final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
         // Check if it's actually the specific expiration error (4002)
         // If status is 401, we assume it might be expired too, or we check the body if available.
         // Adjust logic: if 4002 is explicitly in body OR status is 401 (standard unauthorized)
         bool isExpired = false;
         if (responseBody is Map && responseBody['status'] == 4002) {
           isExpired = true;
         } else if (response.statusCode == 401) {
           // Assume 401 means expired for now, or check message?
           print('ApiService: Status is 401. Assuming token expired.');
           isExpired = true;
         }

         if (isExpired) {
           print('Token expired. Attempting refresh...');
           final success = await _refreshToken();
           if (success) {
             // Retry original request with new token
             accessToken = await StorageService().getToken();
             requestHeaders['Authorization'] = 'Bearer $accessToken';
             print('Retrying POST $url with new token');
             response = await http.post(url, headers: requestHeaders, body: body);
           } else {
             print('Token refresh failed. Logout might be needed.');
           }
         }
       } catch (e) {
         print('Error parsing error response: $e');
       }
    }

    return response;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$_backendUrl$endpoint');
    String? accessToken = await StorageService().getToken();

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
    
    print('ApiService: GET $url');
    print('ApiService: Headers: $requestHeaders');

    var response = await http.get(url, headers: requestHeaders);

    // Check for Token Expiry (4002) or Unauthorized (401)
    if (response.statusCode == 4003 || response.statusCode == 4002 || response.statusCode == 401) {
       print('ApiService: Caught status ${response.statusCode}. Checking body for 4002...');
       try {
         final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
         bool isExpired = false;
         if (responseBody is Map && responseBody['status'] == 4002) {
           isExpired = true;
         } else if (response.statusCode == 401) {
           isExpired = true;
         }

         if (isExpired) {
           print('Token expired. Attempting refresh...');
           final success = await _refreshToken();
           if (success) {
             accessToken = await StorageService().getToken();
             requestHeaders['Authorization'] = 'Bearer $accessToken';
             print('Retrying GET $url with new token');
             response = await http.get(url, headers: requestHeaders);
           } else {
             print('Token refresh failed.');
           }
         }
       } catch (e) {
         print('Error parsing error response: $e');
       }
    }

    return response;
  }

  Future<http.Response> put(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$_backendUrl$endpoint');
    String? accessToken = await StorageService().getToken();

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
    
    print('ApiService: PUT $url');
    print('ApiService: Headers: $requestHeaders');

    var response = await http.put(url, headers: requestHeaders, body: body);

    // Check for Token Expiry (4002) or Unauthorized (401)
    if (response.statusCode == 4003 || response.statusCode == 4002 || response.statusCode == 401) {
       print('ApiService: Caught status ${response.statusCode}. Checking body for 4002...');
       try {
         final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
         bool isExpired = false;
         if (responseBody is Map && responseBody['status'] == 4002) {
           isExpired = true;
         } else if (response.statusCode == 401) {
           isExpired = true;
         }

         if (isExpired) {
           print('Token expired. Attempting refresh...');
           final success = await _refreshToken();
           if (success) {
             accessToken = await StorageService().getToken();
             requestHeaders['Authorization'] = 'Bearer $accessToken';
             print('Retrying PUT $url with new token');
             response = await http.put(url, headers: requestHeaders, body: body);
           } else {
             print('Token refresh failed.');
           }
         }
       } catch (e) {
         print('Error parsing error response: $e');
       }
    }

    return response;
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$_backendUrl$endpoint');
    String? accessToken = await StorageService().getToken();

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
    
    print('ApiService: DELETE $url');
    print('ApiService: Headers: $requestHeaders');

    var response = await http.delete(url, headers: requestHeaders, body: body);

    // Check for Token Expiry (4002) or Unauthorized (401)
    if (response.statusCode == 4003 || response.statusCode == 4002 || response.statusCode == 401) {
       print('ApiService: Caught status ${response.statusCode}. Checking body for 4002...');
       try {
         final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
         bool isExpired = false;
         if (responseBody is Map && responseBody['status'] == 4002) {
           isExpired = true;
         } else if (response.statusCode == 401) {
           isExpired = true;
         }

         if (isExpired) {
           print('Token expired. Attempting refresh...');
           final success = await _refreshToken();
           if (success) {
             accessToken = await StorageService().getToken();
             requestHeaders['Authorization'] = 'Bearer $accessToken';
             print('Retrying DELETE $url with new token');
             response = await http.delete(url, headers: requestHeaders, body: body);
           } else {
             print('Token refresh failed.');
           }
         }
       } catch (e) {
         print('Error parsing error response: $e');
       }
    }

    return response;
  }

  Future<bool> _refreshToken() async {
    try {
      final String? refreshToken = await StorageService().getRefreshToken();
      if (refreshToken == null) {
        print('No refresh token available');
        return false;
      }

      final url = Uri.parse('$_backendUrl/api/auth/refresh');
      print('Attempting to refresh token...');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Try to get tokens from root level first (as per user request)
        String? newAccessToken = data['accessToken'];
        String? newRefreshToken = data['refreshToken'];

        // Fallback to 'data' wrapper if not found at root
        if (newAccessToken == null && data['data'] != null) {
          newAccessToken = data['data']['accessToken'];
          newRefreshToken = data['data']['refreshToken'];
        }

        if (newAccessToken != null && newRefreshToken != null) {
          await StorageService().saveToken(newAccessToken);
          await StorageService().saveRefreshToken(newRefreshToken);
          print('Token refreshed successfully.');
          return true;
        } else {
          print('Failed to parse new tokens from refresh response');
        }
      }
      return false;
    } catch (e) {
      print('Refresh Error: $e');
      return false;
    }
  }
}
