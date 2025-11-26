import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/authentication/providers/user_provider.dart';
import 'package:front_flutter/src/features/couple/services/couple_service.dart';
import 'package:provider/provider.dart';

class CoupleInfoScreen extends StatefulWidget {
  const CoupleInfoScreen({super.key});

  @override
  State<CoupleInfoScreen> createState() => _CoupleInfoScreenState();
}

class _CoupleInfoScreenState extends State<CoupleInfoScreen> {
  bool _isDisconnecting = false;

  Future<void> _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커플 연결 끊기'),
        content: const Text('정말로 커플 연결을 끊으시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('끊기'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDisconnecting = true);
      try {
        final success = await CoupleService().disconnectCouple();
        if (success && mounted) {
          // Refresh user data to reflect disconnected state
          await context.read<UserProvider>().fetchHomeData();
          
          if (mounted) {
            Navigator.pop(context); // Go back to MyPage
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('커플 연결이 해제되었습니다.')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결 해제에 실패했습니다. 다시 시도해주세요.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDisconnecting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커플 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 주 커플 일정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Schedule Placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '일정 리스트가 여기에 표시됩니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDisconnecting ? null : _handleDisconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDisconnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('커플 끊기'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
