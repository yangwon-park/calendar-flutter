import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  // TODO: Replace with your actual Spring Backend URL
  // For Android Emulator, use 'http://10.0.2.2:8080'
  // For iOS Simulator, use 'http://localhost:8080'
  // For Real Device, use your computer's IP address
  static const String _backendUrl = 'http://localhost:8080/api/auth/sign-in';

  Future<bool> loginWithKakao() async {
    try {
      OAuthToken token;
      
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return false;
          }
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('Kakao Access Token: ${token.accessToken}');

      // Call Spring Backend to verify Access Token
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': token.accessToken,
          'provider': 'kakao',
        }),
      );

      if (response.statusCode == 200) {
        print('Backend login success: ${response.body}');
        final data = jsonDecode(response.body);
        final String? backendToken = data['data']['accessToken'];
        final String? refreshToken = data['data']['refreshToken'];
        
        if (backendToken != null) {
          await StorageService().saveToken(backendToken);
          if (refreshToken != null) {
            await StorageService().saveRefreshToken(refreshToken);
          }
          return true;
        }
        return false;
      } else {
        print('Backend login failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Kakao Login Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      print('Kakao Logout Error: $e');
    }
    await StorageService().deleteToken();
  }
}
