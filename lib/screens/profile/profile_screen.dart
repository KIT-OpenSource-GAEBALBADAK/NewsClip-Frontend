// components/ProfileScreen.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../login/login_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // API 호출 결과를 저장할 Future 변수
  late final Future<Map<String, dynamic>> _profileFuture;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // initState에서는 Future를 할당만 하고, 직접 await하지 않습니다.
    // 이렇게 하면 API 호출이 단 한 번만 실행됩니다.
    _profileFuture = _profileService.getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면
            },
          ),
        ],
      ),
      // FutureBuilder를 사용하여 UI를 구성합니다.
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러가 발생했을 때
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('프로필을 불러올 수 없습니다.'),
                  Text('(${snapshot.error})', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // 재시도를 위해 Future를 다시 할당합니다.
                        _profileFuture = _profileService.getMyProfile();
                      });
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 데이터가 없을 때 (정상적이지 않은 경우)
          if (!snapshot.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          // 성공적으로 데이터를 가져왔을 때
          final data = snapshot.data!['data'];
          final nickname = data['nickname'] as String?;
          final role = data['role'] as String? ?? 'user';
          final profileImage = data['profile_image'] as String?;

          // 최초 사용자로, 닉네임 설정이 필요할 때
          // FutureBuilder 안에서 화면 전환 시에는 렌더링 완료 후 실행되도록 합니다.
          if (nickname == null || nickname.trim().isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
              // 프로필 설정이 완료되면, 화면을 다시 로드합니다.
              if (result == true) {
                setState(() {
                  _profileFuture = _profileService.getMyProfile();
                });
              }
            });
            // 프로필 설정 화면으로 이동하는 동안에는 로딩 인디케이터를 보여줍니다.
            return const Center(child: CircularProgressIndicator());
          }
          
          // 정상적으로 프로필이 표시될 때
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryStart,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null || profileImage.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nickname,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await AuthService().logout();

                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
