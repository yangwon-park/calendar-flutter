import 'package:flutter/material.dart';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:front_flutter/src/features/authentication/screens/login_screen.dart';
import 'package:front_flutter/src/features/home/screens/home_screen.dart';
import 'package:front_flutter/src/features/mypage/screens/my_page_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting();
  KakaoSdk.init(nativeAppKey: '92146bf0744fd09558e95de9c9f4249a');

  // Check for stored token
  final String? token = await StorageService().getToken();
  final String initialRoute = token != null ? '/home' : '/login';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/mypage': (context) => const MyPageScreen(),
      },
    );
  }
}