import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  // TODO: Replace with your actual Spring Backend URL
  // For Android Emulator, use 'http://10.0.2.2:8080'
  // For iOS Simulator, use 'http://localhost:8080'
  // For Real Device, use your computer's IP address
  static const String _backendUrl = 'http://localhost:8080/api/auth/kakao';

  Future<void> loginWithKakao() async {
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return;
          }
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('Kakao Access Token: ${token.accessToken}');

      // Call Spring Backend to verify token and get custom token
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': token.accessToken}),
      );

      if (response.statusCode == 200) {
        print('Backend login success: ${response.body}');
        // TODO: Handle backend response (e.g., save JWT token)
      } else {
        throw Exception('Failed to verify token with backend: ${response.body}');
      }
    } catch (e) {
      print('Kakao Login Error: $e');
      rethrow;
    }
  }
}
