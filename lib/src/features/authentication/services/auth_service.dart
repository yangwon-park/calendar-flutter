import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // TODO: Replace with your Web Client ID
  final String _serverClientId = '853592160074-gebseh04j9dneoga5if3t4oa21g6lvi2.apps.googleusercontent.com';
  
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId,
    scopes: ['email', 'profile'],
  );

  // Sign in with Google and send code to backend
  Future<void> signInWithGoogle() async {
    print('AuthService: signInWithGoogle called'); // Debug log
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Get the auth code
      final String? authCode = googleUser.serverAuthCode;
      
      if (authCode != null) {
        print('Auth Code: $authCode');
        await _sendAuthCodeToBackend(authCode, 'google');
      } else {
        print('Failed to get auth code');
        throw Exception('Failed to get auth code');
      }

    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> _sendAuthCodeToBackend(String code, String provider) async {
    try {
      // For iOS Simulator, use localhost. For physical device, use your computer's IP.
      final Uri url = Uri.parse('http://localhost:8080/api/auth/sign-in');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        print('Backend login success: ${response.body}');
        // TODO: Handle successful login (e.g., save JWT token)
      } else {
        print('Backend login failed: ${response.statusCode} - ${response.body}');
        throw Exception('Backend login failed');
      }
    } catch (e) {
      print('Backend Connection Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
