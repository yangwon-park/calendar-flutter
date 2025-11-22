import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/authentication/services/auth_service.dart';
import 'package:front_flutter/src/features/authentication/services/kakao_auth_service.dart';
import 'package:front_flutter/src/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _kakaoAuthService = KakaoAuthService();
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    print('LoginScreen: _loginWithGoogle button pressed'); // Debug log
    setState(() {
      _isLoading = true;
    });
    try {
      print('LoginScreen: Calling AuthService.signInWithGoogle'); // Debug log
      final success = await _authService.signInWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Login failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithKakao() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final success = await _kakaoAuthService.loginWithKakao();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kakao Login failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kakao Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loginWithGoogle,
                        icon: const Icon(Icons.login), // TODO: Use Google Icon
                        label: const Text('Sign in with Google'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loginWithKakao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: const Color(0xFF000000),
                        ),
                        icon: const Icon(Icons.chat_bubble), // TODO: Use Kakao Icon
                        label: const Text('Login with Kakao'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
