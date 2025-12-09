import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';
import '../../services/profile_service.dart';

class CategorySelectScreen extends StatefulWidget {
  final String nickname;
  final String? profileImagePath;

  const CategorySelectScreen({
    super.key,
    required this.nickname,
    this.profileImagePath,
  });

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  final List<Map<String, String>> categories = [
    {"icon": "🏛️", "label": "정치"},
    {"icon": "💰", "label": "경제"},
    {"icon": "🎭", "label": "문화"},
    {"icon": "🌍", "label": "환경"},
    {"icon": "💻", "label": "기술"},
    {"icon": "⚽", "label": "스포츠"},
    {"icon": "✨", "label": "라이프스타일"},
    {"icon": "💪", "label": "건강"},
    {"icon": "📚", "label": "교육"},
    {"icon": "🍜", "label": "음식"},
    {"icon": "✈️", "label": "여행"},
    {"icon": "👗", "label": "패션"},
  ];

  final Set<int> _selectedIndices = {};
  final ProfileService _profileService = ProfileService();
  bool _loading = false;

  bool get _canSubmit => _selectedIndices.length == 3 && !_loading;

  void _toggleCategory(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length < 3) {
          _selectedIndices.add(index);
        }
      }
    });
  }

  Future<void> _goToHome() async {
    if (!_canSubmit) return;

    setState(() => _loading = true);

    try {
      // 선택된 카테고리 정보
      final selectedCategories = _selectedIndices
          .map((i) => categories[i]["label"]!)
          .toList();

      debugPrint('🔵 선택된 카테고리: $selectedCategories');
      debugPrint('🔵 닉네임: ${widget.nickname}');
      debugPrint('🔵 프로필 이미지: ${widget.profileImagePath}');

      // 1️⃣ 프로필 설정 API 호출
      debugPrint('🔵 프로필 설정 API 호출 시작');
      await _profileService.setupProfile(
        nickname: widget.nickname,
        profileImagePath: widget.profileImagePath,
      );
      debugPrint('✅ 프로필 설정 완료');

      // 2️⃣ 선호 카테고리 설정 API 호출
      debugPrint('🔵 선호 카테고리 설정 API 호출 시작');
      await _profileService.updatePreferredCategories(
        categories: selectedCategories,
      );
      debugPrint('✅ 선호 카테고리 설정 완료');

      if (!mounted) return;

      // 🔥 프로필 캐시 무효화 (새로운 데이터를 다시 불러오도록)
      ProfileCache.clearCache();

      // 🔥 전역 프로필 업데이트 알림
      profileUpdateNotifier.value++;

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 설정이 완료되었습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      debugPrint('✅ 홈 화면으로 이동');

      // 🔥 두 번 pop하여 프로필 설정 화면과 카테고리 선택 화면 모두 닫기
      Navigator.of(context).pop(true); // 카테고리 선택 완료
      Navigator.of(context).pop(true); // 프로필 설정 완료
    } catch (e) {
      debugPrint('❌ 에러 발생: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "어떤 소식을 들려드릴까요?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndices.contains(index);
                  return _buildCategoryTile(
                    icon: categories[index]["icon"]!,
                    label: categories[index]["label"]!,
                    isSelected: isSelected,
                    onTap: () => _toggleCategory(index),
                  );
                },
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Text(icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final remaining = 3 - _selectedIndices.length;
    final buttonText = _canSubmit
        ? "완료"
        : "관심사를 ${remaining}개 더 선택해주세요";

    return Container(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: _canSubmit ? _goToHome : null,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: _canSubmit ? 1.0 : 0.5,
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFCC9DF5), Color(0xFFFF9AD5)],
              ),
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

