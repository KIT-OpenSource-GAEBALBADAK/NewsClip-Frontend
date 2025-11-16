import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ✅ 1. CommunityService 임포트
import 'package:newsclip/services/community_service.dart';

import '../../widgets/common/bottom_navigation.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  // UI 색깔 상수
  static const Color purple = Color(0xFF8B5CF6);
  static const Color grayText = Color(0xFF6B6B84);
  static const Color fieldBg = Color(0xFFF8F7FF);
  static const Color borderPurple = Color(0x268B5CF6);

  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();

  // ✅ 2. CommunityService 인스턴스 생성
  final CommunityService _communityService = CommunityService();

  final List<String> _categories = [
    '기술',
    '경제',
    '사회',
    '문화',
    '스포츠',
    '정치',
    '과학',
    '교육',
    '건강',
    '라이프스타일',
    '고민',
    '기타',
  ];

  final List<String> _hashtags = [
    '#트렌드',
    '#젊은세대',
    '#소통',
    '#의견나눔',
    '#정보공유',
  ];

  String? selectedCategory;
  bool isSubmitting = false;
  File? selectedImage;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _title.text.trim().isNotEmpty &&
          _content.text.trim().isNotEmpty &&
          selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ 공통 네비게이션 위젯 사용 (currentIndex 고정 1 = 커뮤니티)
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          // TODO: 탭 이동 로직 여기서 라우팅으로 연결하면 됨
          // 예시:
          // if (index == 0) Navigator.pushReplacementNamed(context, '/news');
          // if (index == 1) Navigator.pop(context); // 커뮤니티
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    const SizedBox(height: 20),
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildContentSection(),
                    const SizedBox(height: 20),
                    _buildTipsCard(),
                    const SizedBox(height: 20),
                    _buildHashtagSection(),
                    const SizedBox(height: 20),
                    _buildBottomWriteInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: borderPurple, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '새 글 작성',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  Text(
                    '커뮤니티와 생각을 나누어보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: grayText,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _canSubmit && !isSubmitting ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(70, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: _canSubmit ? purple : purple.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '발행',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CATEGORY ----------------
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(
            color: grayText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down, color: grayText),
              isExpanded: true,
              hint: const Text(
                '카테고리를 선택해주세요',
                style: TextStyle(
                  color: grayText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 16, color: grayText),
                      const SizedBox(width: 6),
                      Text(
                        c,
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
              onChanged: (v) {
                setState(() => selectedCategory = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- TITLE ----------------
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '제목',
              style: TextStyle(
                color: grayText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
              ),
            ),
            Text(
              '${_title.text.length}/100',
              style: const TextStyle(
                color: grayText,
                fontSize: 12,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _title,
            maxLength: 100,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: '어떤 이야기를 들려주고 싶으신가요?',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ---------------- IMAGE ----------------
  Widget _buildImageSection() {
    if (selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => setState(() => selectedImage = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '제거',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final file = await picker.pickImage(source: ImageSource.gallery);
            if (file != null) {
              setState(() => selectedImage = File(file.path));
            }
          },
          child: _imageButton(Icons.image_outlined, '사진'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final file = await picker.pickImage(source: ImageSource.camera);
            if (file != null) {
              setState(() => selectedImage = File(file.path));
            }
          },
          child: _imageButton(Icons.camera_alt_outlined, '카메라'),
        ),
      ],
    );
  }

  Widget _imageButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: grayText),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: grayText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard Variable',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CONTENT ----------------
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '내용',
              style: TextStyle(
                color: grayText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
              ),
            ),
            Text(
              '${_content.text.length}/2000',
              style: const TextStyle(
                color: grayText,
                fontSize: 12,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _content,
            maxLines: null,
            maxLength: 2000,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: '자유롭게 의견을 나누어보세요. 서로 존중하며 소통하는 공간입니다.',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ---------------- TIPS ----------------
  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fieldBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ 좋은 글 작성 팁',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A0A0A),
              fontFamily: 'Pretendard Variable',
            ),
          ),
          SizedBox(height: 8),
          _TipText('• 구체적이고 명확한 제목을 작성해보세요'),
          _TipText('• 개인 정보나 민감한 정보는 피해주세요'),
          _TipText('• 서로 다른 의견을 존중하며 건설적으로 소통해요'),
          _TipText('• 사실과 의견을 구분해서 표현해주세요'),
        ],
      ),
    );
  }

  // ---------------- HASHTAG ----------------
  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 태그',
          style: TextStyle(
            color: grayText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hashtags.map((tag) {
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                side: const BorderSide(color: borderPurple, width: 1.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 24),
              ),
              onPressed: () {
                final current = _content.text;
                final next = current.isEmpty ? tag : '$current $tag';
                if (next.length <= 2000) {
                  setState(() => _content.text = next);
                }
              },
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------- BOTTOM INFO ----------------
  Widget _buildBottomWriteInfo() {
    final done = _canSubmit;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border.all(color: borderPurple, width: 1.15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text(
                '익명으로 작성됩니다',
                style: TextStyle(
                  fontSize: 12,
                  color: grayText,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.alternate_email, size: 12, color: grayText),
              SizedBox(width: 4),
              Text(
                '멘션 가능',
                style: TextStyle(
                  fontSize: 12,
                  color: grayText,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 4,
                backgroundColor: done ? Colors.green : fieldBg,
              ),
              const SizedBox(width: 4),
              const Text(
                '작성 완료',
                style: TextStyle(
                  fontSize: 12,
                  color: grayText,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- SUBMIT ----------------
  // ✅ 3. _handleSubmit 함수를 실제 서버 통신 로직으로 수정
  Future<void> _handleSubmit() async {
    setState(() => isSubmitting = true);

    // 서비스에 전달할 데이터 준비
    final String title = _title.text.trim();
    final String content = _content.text.trim();
    final String category = selectedCategory!; // _canSubmit이 true이므로 null이 아님

    // filePaths 리스트 준비
    final List<String> filePaths = [];
    if (selectedImage != null) {
      filePaths.add(selectedImage!.path);
    }

    try {
      // 서비스 호출
      await _communityService.createPost(
        category: category,
        title: title,
        content: content,
        filePaths: filePaths,
      );

      // 성공 처리
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 글이 성공적으로 작성되었습니다!')),
      );
      Navigator.pop(context);

    } catch (e) {
      // 에러 처리
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 글 작성 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 로딩 상태 해제 (성공/실패 여부와 관계없이)
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}

// 작은 Tip 텍스트용 위젯
class _TipText extends StatelessWidget {
  final String text;
  const _TipText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _NewPostScreenState.grayText,
          fontFamily: 'Pretendard Variable',
        ),
      ),
    );
  }
}