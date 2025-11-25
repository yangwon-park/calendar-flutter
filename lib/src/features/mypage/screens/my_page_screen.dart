import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:front_flutter/src/features/authentication/services/auth_service.dart';
import 'package:front_flutter/src/features/authentication/services/kakao_auth_service.dart';
import 'package:front_flutter/src/features/couple/services/couple_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // Mock state for demonstration. In real app, fetch from user profile.
  bool _isCouple = false; 
  
  void _showConnectCoupleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return const ConnectCoupleBottomSheet();
          },
        );
      },
    ).then((_) {
      // Refresh parent state if needed when sheet closes
      // For example if we want to update the "Couple Info" visibility immediately if connected
      if (mounted) {
        setState(() {});
      }
    });
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
          if (_isCouple)
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: const Text('커플 정보 보기'),
              onTap: () {
                // TODO: Implement Couple Info
              },
            ),
          if (!_isCouple)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('커플 연결하기'),
              subtitle: const Text('초대 코드를 생성하거나 입력하세요'),
              onTap: () => _showConnectCoupleBottomSheet(context),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Call both logouts to ensure token is cleared and provider session is ended
              try {
                await AuthService().logoutFromBackend();
              } catch (e) {
                print('Backend logout error: $e');
              }
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

class ConnectCoupleBottomSheet extends StatefulWidget {
  const ConnectCoupleBottomSheet({super.key});

  @override
  State<ConnectCoupleBottomSheet> createState() => _ConnectCoupleBottomSheetState();
}

class _ConnectCoupleBottomSheetState extends State<ConnectCoupleBottomSheet> {
  String? _generatedCode;
  DateTime? _generationTime;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadInvitationState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvitationState() async {
    final code = await StorageService().getInvitationCode();
    final time = await StorageService().getCodeGenerationTime();

    if (code != null && time != null) {
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inHours < 24) {
        if (mounted) {
          setState(() {
            _generatedCode = code;
            _generationTime = time;
            _remainingTime = const Duration(hours: 24) - difference;
          });
          _startTimer();
        }
      } else {
        await StorageService().clearInvitationCode();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          } else {
            _timer?.cancel();
            _generatedCode = null;
            _generationTime = null;
            StorageService().clearInvitationCode();
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '연인과 연결해 보세요! 💕',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const TabBar(
            tabs: [
              Tab(text: '내 코드 공유'),
              Tab(text: '상대방 코드 입력'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildShareCodeTab(),
                _buildEnterCodeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCodeTab() {
    // If code exists and is valid (timer running or loaded)
    if (_generatedCode != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '아래 코드를 연인에게 공유하세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _generatedCode!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _generatedCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('코드가 복사되었습니다!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('코드 복사하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '다음 생성까지 남은 시간: ${_formatDuration(_remainingTime)}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Initial State: Show Generate Button
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              '초대 코드를 생성하여\n연인과 연결하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                print('Generate Code Button Pressed');
                try {
                  final code = await CoupleService().generateInvitationCode();
                  print('Code generated: $code');
                  final now = DateTime.now();
                  
                  await StorageService().saveInvitationCode(code, now);
                  
                  if (mounted) {
                    setState(() {
                      _generatedCode = code;
                      _generationTime = now;
                      _remainingTime = const Duration(hours: 24);
                    });
                    _startTimer();
                  }
                } catch (e) {
                  print('Generate Code Error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('코드 생성 실패: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('초대 코드 생성하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterCodeTab() {
    final TextEditingController codeController = TextEditingController();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '연인에게 받은 코드를 입력하세요',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '초대 코드 입력',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(fontSize: 24, letterSpacing: 2.0),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (codeController.text.isEmpty) return;
                          
                          setState(() => isLoading = true);
                          final success = await CoupleService().connectCouple(codeController.text);
                          setState(() => isLoading = false);

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close BottomSheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('커플 연결 성공! 🎉')),
                              );
                              // Note: We can't easily update parent state directly from here without a callback
                              // But since we are popping, the parent's then() block will run if we set it up.
                              // For now, the user just wants the bottom sheet to update.
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('연결 실패. 코드를 확인해주세요.')),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('연결하기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
