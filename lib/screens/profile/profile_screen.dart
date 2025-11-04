// components/ProfileScreen.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;

  String _nickname = '사용자';
  String _role = '';
  String? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ 서비스 초기화 - DioService를 중앙에서 관리하므로 직접 생성
    _profileService = ProfileService();
    _loadProfile();
  }

  /// GET /me API로 프로필 정보 로드
  Future<void> _loadProfile() async {
    try {
      final response = await _profileService.getMyProfile();

      if (!mounted) return;

      final data = response['data'];
      setState(() {
        _nickname = data['nickname'] ?? '사용자';
        _role = data['role'] ?? 'user';
        _profileImage = data['profile_image'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 프로필 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryStart,
                      backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                          ? NetworkImage(_profileImage!)
                          : null,
                      child: _profileImage == null || _profileImage!.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // 닉네임
                    Text(
                      _nickname,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // 역할
                    Text(
                      _role,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 48),
                    // 로그아웃 버튼
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
            ),
    );
  }
}

