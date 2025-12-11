import 'package:flutter/material.dart';
import 'package:front_flutter/src/core/errors/exceptions.dart';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:front_flutter/src/features/authentication/providers/user_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    // Check if token exists locally
    final token = await StorageService().getToken();
    
    if (token == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // Validate token by fetching data
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.fetchHomeData();
      
      // If fetch was "successful" (no exception) but yielded no data (e.g. silent error), 
      // treat as auth failure.
      if (userProvider.accountInfo == null) {
        print('Splash: fetchHomeData succeeded but accountInfo is null. Treating as auth failure.');
        throw UnauthorizedException('Failed to fetch account info');
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Splash auth check failed: $e');
      // If unauthorized or any other error (generic safety), force login
      // We clear token to ensure next start is clean
      await StorageService().deleteToken();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
