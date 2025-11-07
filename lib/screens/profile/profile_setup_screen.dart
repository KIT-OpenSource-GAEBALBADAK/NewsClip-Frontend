import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameCtrl = TextEditingController();
  XFile? _image;
  bool _loading = false;

  late final ProfileService _profileService;

  bool get _canNext => _nicknameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _nicknameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (!mounted) return;
      if (img != null) setState(() => _image = img);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택에 실패했어요: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_canNext) return;

    setState(() => _loading = true);

    try {
      // ✅ 프로필 설정 API 호출
      final nickname = _nicknameCtrl.text.trim();
      final result = await _profileService.setupProfile(
        nickname: nickname,
        profileImagePath: _image?.path,
      );

      if (!mounted) return;

      // 성공 메시지 표시
      final message = result['message'] ?? '프로필 설정이 완료되었습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ 프로필 설정 완료 후 이전 화면으로 돌아가기 (true 반환)
      Navigator.of(context).pop(true);
    } catch (e) {
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
    const grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // 상단: 우측 작은 클립
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: const Icon(Icons.attach_file, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 타이틀
                const Text(
                  '사진과 닉네임을',
                  style: TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const Text(
                  '등록해주세요',
                  style: TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                // 아바타 + 카메라
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(120),
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF99A1AF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 닉네임 입력 (언더라인 스타일)
                TextField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(
                    hintText: '김금공',
                    hintStyle: TextStyle(color: Color(0x7F0A0A0A)),
                    isDense: true,
                    filled: false,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD0D5DB), width: 1),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD0D5DB), width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[],
                  enableSuggestions: false,
                  autocorrect: false,
                  onSubmitted: (_) => _submit(),
                ),

                const Spacer(),

                // 다음 버튼 (비활성 40% 불투명)
                Opacity(
                  opacity: (_canNext && !_loading) ? 1.0 : 0.40,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: (_canNext && !_loading) ? _submit : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '다음',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_image == null) {
      return const Center(
        child: Icon(Icons.person_outline, size: 64, color: Color(0xFFB8BDC5)),
      );
    }
    if (kIsWeb) return Image.network(_image!.path, fit: BoxFit.cover);
    return Image.file(File(_image!.path), fit: BoxFit.cover);
  }
}
