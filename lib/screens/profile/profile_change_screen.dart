import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // dio 패키지

// 🔥 DioService 위치에 맞게 경로 수정 필요
import '../../services/dio_service.dart';
import 'category_change_screen.dart';

class ProfileChangeScreen extends StatefulWidget {
  const ProfileChangeScreen({super.key});

  @override
  State<ProfileChangeScreen> createState() => _ProfileChangeScreenState();
}

class _ProfileChangeScreenState extends State<ProfileChangeScreen> {
  final _nicknameCtrl = TextEditingController();
  XFile? _image;
  bool _loading = false;

  bool get _canNext => _nicknameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
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
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  // ✅ DioService를 이용한 전송 로직
  Future<void> _submit() async {
    if (!_canNext) return;

    setState(() => _loading = true);

    try {
      final dio = DioService().dio;

      // 파일명 추출 로직
      String? fileName;
      if (_image != null) {
        fileName = _image!.path.split('/').last;
      }

      // FormData 생성
      final formData = FormData.fromMap({
        'nickname': _nicknameCtrl.text.trim(),
        // 이미지가 있을 때만 file 필드 추가
        if (_image != null)
          'file': await MultipartFile.fromFile(
            _image!.path,
            filename: fileName,
          ),
      });

      print('🔵 전송 데이터 확인: 닉네임=${_nicknameCtrl.text.trim()}, 파일=$fileName');

      // 3. 요청 전송 (POST /me/avatar)
      final response = await dio.post(
        '/me/avatar',
        data: formData,
        // 🔥 [중요 수정] JSON 헤더를 덮어쓰기 위해 Options 추가
        options: Options(
          contentType: 'multipart/form-data',
          // (참고: Dio가 FormData를 감지하면 자동으로 boundary를 붙여줍니다)
        ),
      );

      // --- 디버깅 로그 ---
      print('📥 [DEBUG] 응답 상태코드: ${response.statusCode}');
      print('📥 [DEBUG] 응답 데이터: ${response.data}');
      // ----------------

      // 4. 성공 처리
      if (response.statusCode == 200) {
        if (!mounted) return;

        // ✅ 수정됨: 파라미터 없이 화면만 이동
        await Navigator.of(context).push(
          MaterialPageRoute(
            // 괄호 안에 아무것도 넣지 마세요
            builder: (context) => const CategoryChangeScreen(),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;

      // 에러 로그 자세히 출력
      print('❌ DioException 상세: ${e.response?.data}');
      print('❌ DioException 헤더: ${e.requestOptions.headers}');

      String errorMessage = '오류가 발생했습니다.';
      if (e.response != null) {
        // 500 에러일 경우 보통 메시지가 없거나 깁니다. 단순화.
        if (e.response!.statusCode == 500) {
          errorMessage = '서버 내부 오류입니다. (500)\n잠시 후 다시 시도해주세요.';
        } else {
          errorMessage = e.response?.data['message'] ?? e.message;
        }
      } else {
        errorMessage = e.message ?? '서버와 연결할 수 없습니다.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
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
                  onSubmitted: (_) => _submit(),
                ),
                const Spacer(),
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