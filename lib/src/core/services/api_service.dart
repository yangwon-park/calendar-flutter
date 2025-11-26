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

    // Check for Token Expiry (4002)
    if (response.statusCode == 4003 || (response.statusCode == 4002)) { // Handling both just in case, user said 4002 but log showed 4003
       // Actually user said 4002, but the log showed {"message":"잘못된 형식의 토큰입니다","status":4003}. 
       // Wait, 4003 usually means Forbidden/Invalid Token structure, 4002 might be specific for Expired.
       // I will check the response body for the status code as well if it's in the body.
       // The user explicitly said "status가 4002로 오면".
       // Let's check the body status.
       
       final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
       if (responseBody is Map && responseBody['status'] == 4002) {
         print('Token expired (4002). Attempting refresh...');
         final success = await _refreshToken();
         if (success) {
           // Retry original request with new token
           accessToken = await StorageService().getToken();
           requestHeaders['Authorization'] = 'Bearer $accessToken';
           response = await http.post(url, headers: requestHeaders, body: body);
         } else {
           // Refresh failed, maybe logout?
           print('Token refresh failed.');
           // throw Exception('Session expired. Please login again.');
         }
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

    // Check for Token Expiry (4002)
    if (response.statusCode == 4003 || (response.statusCode == 4002)) {
       final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
       if (responseBody is Map && responseBody['status'] == 4002) {
         print('Token expired (4002). Attempting refresh...');
         final success = await _refreshToken();
         if (success) {
           // Retry original request with new token
           accessToken = await StorageService().getToken();
           requestHeaders['Authorization'] = 'Bearer $accessToken';
           response = await http.get(url, headers: requestHeaders);
         } else {
           print('Token refresh failed.');
         }
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

    // Check for Token Expiry (4002)
    if (response.statusCode == 4003 || (response.statusCode == 4002)) {
       final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
       if (responseBody is Map && responseBody['status'] == 4002) {
         print('Token expired (4002). Attempting refresh...');
         final success = await _refreshToken();
         if (success) {
           // Retry original request with new token
           accessToken = await StorageService().getToken();
           requestHeaders['Authorization'] = 'Bearer $accessToken';
           response = await http.put(url, headers: requestHeaders, body: body);
         } else {
           print('Token refresh failed.');
         }
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

    // Check for Token Expiry (4002)
    if (response.statusCode == 4003 || (response.statusCode == 4002)) {
       final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
       if (responseBody is Map && responseBody['status'] == 4002) {
         print('Token expired (4002). Attempting refresh...');
         final success = await _refreshToken();
         if (success) {
           // Retry original request with new token
           accessToken = await StorageService().getToken();
           requestHeaders['Authorization'] = 'Bearer $accessToken';
           response = await http.delete(url, headers: requestHeaders, body: body);
         } else {
           print('Token refresh failed.');
         }
       }
    }

    return response;
  }

  Future<bool> _refreshToken() async {
    try {
      final String? refreshToken = await StorageService().getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('$_backendUrl/api/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? newAccessToken = data['data']['accessToken'];
        final String? newRefreshToken = data['data']['refreshToken']; // Optional: if refresh token is rotated

        if (newAccessToken != null) {
          await StorageService().saveToken(newAccessToken);
          if (newRefreshToken != null) {
            await StorageService().saveRefreshToken(newRefreshToken);
          }
          print('Token refreshed successfully.');
          return true;
        }
      }
      print('Refresh failed: ${response.body}');
      return false;
    } catch (e) {
      print('Refresh Error: $e');
      return false;
    }
  }
}
