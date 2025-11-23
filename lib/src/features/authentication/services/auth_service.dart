import 'dart:convert';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Sign in with Google and send Access Token to backend
  // Returns true if successful, false otherwise
  Future<bool> signInWithGoogle() async {
    print('AuthService: signInWithGoogle called');
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Get the authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      
      if (accessToken != null) {
        print('Google Access Token: $accessToken');
        return await _sendTokenToBackend(accessToken, 'google');
      } else {
        print('Failed to get access token');
        return false;
      }

    } catch (error) {
      print('Google Sign-In Error: $error');
      return false;
    }
  }

  Future<bool> _sendTokenToBackend(String accessToken, String provider) async {
    try {
      // For iOS Simulator, use localhost. For physical device, use your computer's IP.
      final Uri url = Uri.parse('http://localhost:8080/api/auth/sign-in');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        print('Backend login success: ${response.body}');
        final data = jsonDecode(response.body);
        final String? backendToken = data['data']['accessToken'];
        
        if (backendToken != null) {
          await StorageService().saveToken(backendToken);
          return true;
        }
        return false; // If backendToken is null despite 200 status
      } else {
        print('Backend login failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Backend Connection Error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await StorageService().deleteToken();
  }
}
