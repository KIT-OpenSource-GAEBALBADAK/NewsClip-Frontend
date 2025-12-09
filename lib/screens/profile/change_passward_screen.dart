import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/login/email_login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ===== Design Colors =====
  static const Color _gradientStart = Color(0xFF8B5CF6); // 보라
  static const Color _gradientEnd = Color(0xFFEC4899);   // 핑크
  static const Color _textTitle = Color(0xFF0A0A0A);
  static const Color _textSub = Color(0xFF697282);
  static const Color _inputBg = Color(0xFFF9FAFB);       // 연한 회색 배경
  static const Color _borderDefault = Color(0xFFD0D5DB); // 기본 테두리
  static const Color _borderFocus = Color(0xFF8B5CF6);   // 포커스 테두리
  static const Color _errorColor = Color(0xFFEF4444);

  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _touched = false;
  bool _loading = false;

  // 유효성 검사 로직
  bool get _isStrong => _pwController.text.trim().length >= 8;
  bool get _isSame => _pwController.text == _pwConfirmController.text;
  bool get _canSubmit => _isStrong && _isSame && _pwController.text.isNotEmpty && !_loading;

  @override
  void initState() {
    super.initState();
    _pwController.addListener(() => setState(() {}));
    _pwConfirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _touched = true);
    if (!_canSubmit) return;

    setState(() => _loading = true);

    try {
      // POST /auth/password/reset
      await resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        newPassword: _pwController.text,
      );

      if (!mounted) return;

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 성공적으로 변경되었습니다. 다시 로그인해주세요.'),
          backgroundColor: Colors.green,
        ),
      );

      // 로그인 화면으로 이동 (모든 이전 화면 제거)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // 입력창 데코레이션 팩토리 메서드
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
    final strengthError = (_touched && _pwController.text.isNotEmpty && !_isStrong)
        ? '비밀번호는 8자 이상이어야 합니다.'
        : null;
    final matchError = (_touched && _pwConfirmController.text.isNotEmpty && !_isSame)
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
                                Icons.attach_file,
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
                      '새 비밀번호 설정',
                      style: TextStyle(
                        color: _textTitle,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '새로운 비밀번호를 입력해주세요',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // [입력 1] 새 비밀번호
                    TextField(
                      controller: _pwController,
                      obscureText: _obscurePw,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16, color: _textTitle),
                      onChanged: (_) => setState(() => _touched = true),
                      decoration: _buildInputDecoration(
                        hint: '새 비밀번호',
                        obscure: _obscurePw,
                        onToggle: () => setState(() => _obscurePw = !_obscurePw),
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

                    // [입력 2] 비밀번호 확인
                    TextField(
                      controller: _pwConfirmController,
                      obscureText: _obscureConfirm,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 16, color: _textTitle),
                      onChanged: (_) => setState(() => _touched = true),
                      onSubmitted: (_) => _submit(),
                      decoration: _buildInputDecoration(
                        hint: '비밀번호 확인',
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
                      '비밀번호 재설정',
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