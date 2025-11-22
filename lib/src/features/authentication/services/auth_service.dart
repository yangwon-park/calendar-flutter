import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Sign in with Google and send Access Token to backend
  // Returns true if successful, false otherwise
  Future<bool> signInWithGoogle() async {
    print('AuthService: signInWithGoogle called'); // Debug log
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

    } catch (e) {
      print('Google Sign In Error: $e');
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
        // TODO: Handle successful login (e.g., save JWT token)
        return true;
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
  }
}
