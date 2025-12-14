import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // DioException 처리를 위해 필요

// [수정] 프로젝트 경로에 맞게 DioService import
import '../../services/dio_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ===== Design Colors (기존 디자인 유지) =====
  static const Color _gradientStart = Color(0xFF8B5CF6); // 보라
  static const Color _gradientEnd = Color(0xFFEC4899);   // 핑크
  static const Color _textTitle = Color(0xFF0A0A0A);
  static const Color _textSub = Color(0xFF697282);
  static const Color _inputBg = Color(0xFFF9FAFB);       // 연한 회색 배경
  static const Color _borderDefault = Color(0xFFD0D5DB); // 기본 테두리
  static const Color _borderFocus = Color(0xFF8B5CF6);   // 포커스 테두리
  static const Color _errorColor = Color(0xFFEF4444);

  // [수정] 컨트롤러 3개 (현재 비밀번호, 새 비밀번호, 확인)
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  // [수정] 가리기 상태 변수 3개
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _touched = false;
  bool _loading = false;

  // 유효성 검사 로직
  // 1. 새 비밀번호가 8자 이상인지
  bool get _isStrong => _newPwController.text.trim().length >= 8;
  // 2. 새 비밀번호와 확인이 일치하는지
  bool get _isSame => _newPwController.text == _confirmPwController.text;
  // 3. 현재 비밀번호가 입력되었는지
  bool get _hasCurrent => _currentPwController.text.isNotEmpty;

  // 전체 제출 가능 여부
  bool get _canSubmit => _isStrong && _isSame && _hasCurrent && !_loading;

  @override
  void initState() {
    super.initState();
    // 상태 실시간 감지
    _currentPwController.addListener(() => setState(() {}));
    _newPwController.addListener(() => setState(() {}));
    _confirmPwController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // [수정] 비밀번호 변경 API 호출 함수
  void _submit() async {
    setState(() => _touched = true);
    if (!_canSubmit) return;

    setState(() => _loading = true);

    try {
      // DioService 인스턴스 가져오기 (토큰 자동 처리)
      final dio = DioService().dio;

      // API 호출: PUT /me/password
      final response = await dio.put(
        '/me/password',
        data: {
          "current_password": _currentPwController.text,
          "new_password": _newPwController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호가 성공적으로 변경되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 설정 화면으로 복귀
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (!mounted) return;

      // 에러 메시지 추출
      String errorMessage = '비밀번호 변경 중 오류가 발생했습니다.';
      if (e.response != null && e.response?.data != null) {
        // 서버에서 보내주는 에러 메시지가 있다면 사용 (예: 현재 비밀번호 불일치)
        errorMessage = e.response?.data['message'] ?? errorMessage;
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
          content: Text('알 수 없는 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // 입력창 데코레이션 팩토리 메서드 (디자인 유지)
  InputDecoration _buildInputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA0A4B8),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderFocus, width: 1.5),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF9CA3AF),
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 에러 메시지 계산
    final strengthError = (_touched && _newPwController.text.isNotEmpty && !_isStrong)
        ? '새 비밀번호는 8자 이상이어야 합니다.'
        : null;
    final matchError = (_touched && _confirmPwController.text.isNotEmpty && !_isSame)
        ? '비밀번호가 일치하지 않습니다.'
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header & Content (Scrollable) =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 네비게이션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.maybePop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back, color: Colors.black),
                          ),
                        ),
                        // 우측 그라데이션 원형 아이콘
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_gradientStart, _gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: const Icon(
                                Icons.lock_outline, // 아이콘 변경 (자물쇠)
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 타이틀
                    const Text(
                      '비밀번호 변경',
                      style: TextStyle(
                        color: _textTitle,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '안전을 위해 현재 비밀번호 확인이 필요합니다.',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // [추가] 1. 현재 비밀번호 입력
                    TextField(
                      controller: _currentPwController,
                      obscureText: _obscureCurrent,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16, color: _textTitle),
                      onChanged: (_) => setState(() => _touched = true),
                      decoration: _buildInputDecoration(
                        hint: '현재 비밀번호',
                        obscure: _obscureCurrent,
                        onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // [기존 수정] 2. 새 비밀번호 입력
                    TextField(
                      controller: _newPwController,
                      obscureText: _obscureNew,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16, color: _textTitle),
                      onChanged: (_) => setState(() => _touched = true),
                      decoration: _buildInputDecoration(
                        hint: '새 비밀번호',
                        obscure: _obscureNew,
                        onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    // 에러 메시지 1
                    if (strengthError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          strengthError,
                          style: const TextStyle(color: _errorColor, fontSize: 13),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // [기존 수정] 3. 새 비밀번호 확인
                    TextField(
                      controller: _confirmPwController,
                      obscureText: _obscureConfirm,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 16, color: _textTitle),
                      onChanged: (_) => setState(() => _touched = true),
                      onSubmitted: (_) => _submit(),
                      decoration: _buildInputDecoration(
                        hint: '새 비밀번호 확인',
                        obscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    // 에러 메시지 2
                    if (matchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          matchError,
                          style: const TextStyle(color: _errorColor, fontSize: 13),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ===== Bottom Button (Fixed) =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: InkWell(
                onTap: _canSubmit ? _submit : () => setState(() => _touched = true),
                borderRadius: BorderRadius.circular(999),
                child: Opacity(
                  opacity: _canSubmit ? 1.0 : 0.4, // 비활성화 시 흐리게
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _gradientStart.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                      '비밀번호 변경',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}