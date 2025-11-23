import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_flutter/src/features/authentication/services/auth_service.dart';
import 'package:front_flutter/src/features/authentication/services/kakao_auth_service.dart';
import 'package:front_flutter/src/features/couple/services/couple_service.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  Future<void> _generateInvitationCode(BuildContext context) async {
    try {
      final code = await CoupleService().generateInvitationCode();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Couple Invitation Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Share this code with your partner.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Page'),
      ),
      body: ListView(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("User Name"), // Placeholder
            accountEmail: Text("user@example.com"), // Placeholder
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('내 정보 보기'),
            onTap: () {
              // TODO: Implement My Info
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('커플 정보 보기'),
            onTap: () {
              // TODO: Implement Couple Info
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('커플 초대 코드 생성'),
            onTap: () => _generateInvitationCode(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Call both logouts to ensure token is cleared and provider session is ended
              await AuthService().signOut();
              await KakaoAuthService().logout();
              
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
