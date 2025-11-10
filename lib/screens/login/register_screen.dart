import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../services/user_service.dart';
import 'email_login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Colors
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _pink = Color(0xFFEC4899);

  // Controllers
  final _usernameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  // States
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // 이메일 중복확인 관련 상태
  bool _isCheckingEmail = false;
  bool _isEmailAvailable = false;
  String? _checkedEmail;

  // 약관 동의 상태
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  // 서비스 인스턴스
  late final UserService _userService;


  @override
  void initState() {
    super.initState();
    _userService = UserService();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  bool get _allRequired => _agreeTerms && _agreePrivacy;

  bool get _canSubmit =>
      _usernameCtrl.text.trim().isNotEmpty &&
      _pwCtrl.text.isNotEmpty &&
      _pwConfirmCtrl.text.isNotEmpty &&
      _pwCtrl.text == _pwConfirmCtrl.text &&
      _allRequired &&
      _isEmailAvailable;

  void _toggleAgreeAll() {
    final newVal = !(_agreeTerms && _agreePrivacy && _agreeMarketing);
    setState(() {
      _agreeTerms = newVal;
      _agreePrivacy = newVal;
      _agreeMarketing = newVal;
    });
  }

  void _toast(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade600 : Colors.black87,
      ),
    );
  }

  static OutlineInputBorder _outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.15),
      );

  // ✅ 이메일 중복확인
  Future<void> _checkEmailDuplicate() async {
    final email = _usernameCtrl.text.trim();

    // ✅ 1단계: 이메일 형식 검증
    final emailError = validateEmail(email);
    if (emailError != null) {
      _toast(emailError);
      return;
    }

    // ✅ 2단계: 형식이 올바르면 중복확인 진행
    setState(() => _isCheckingEmail = true);

    try {
      final isAvailable = await _userService.checkUsername(username: email);

      if (!mounted) return;

      setState(() {
        _isEmailAvailable = isAvailable;
        _checkedEmail = email;
      });

      _toast(
        isAvailable ? '사용 가능한 이메일입니다' : '이미 사용 중인 이메일입니다',
        success: isAvailable,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEmailAvailable = false;
        _checkedEmail = null;
      });
      _toast('중복확인 실패: $e');
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _submit() async {
    // ✅ 비밀번호 검증
    final pwError = validatePassword(_pwCtrl.text);
    if (pwError != null) {
      _toast(pwError);
      return;
    }

    // ✅ 비밀번호 확인 검증
    if (_pwCtrl.text != _pwConfirmCtrl.text) {
      _toast('비밀번호가 일치하지 않습니다');
      return;
    }

    // ✅ 이메일 중복확인 검증
    final currentEmail = _usernameCtrl.text.trim();
    if (_checkedEmail != currentEmail || !_isEmailAvailable) {
      _toast('이메일 중복확인을 해주세요');
      return;
    }

    // ✅ 약관 동의 검증
    if (!_allRequired) {
      _toast('필수 약관에 동의해주세요');
      return;
    }

    setState(() => _loading = true);

    try {
      final username = _usernameCtrl.text.trim();
      final password = _pwCtrl.text;

      // ✅ 회원가입 API 호출
      final result = await _userService.register(
        username: username,
        password: password,
      );

      if (!mounted) return;

      // ✅ 회원가입 성공 메시지 표시
      final message = result['message'] ?? '회원가입이 완료되었습니다. 로그인해주세요.';
      _toast(message, success: true);

      // ✅ 이메일 로그인 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double padX = 24;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_purple, _pink],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: const Icon(Icons.attach_file,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Content =====
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(padX, 20, padX, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        '이메일로\n가입하기',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '뉴스를 더 스마트하게 읽어보세요',
                        style: TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 이메일
                      const _FieldLabel('이메일'),
                      Row(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextField(
                                  controller: _usernameCtrl,
                                  onChanged: (_) {
                                    if (_isEmailAvailable) {
                                      setState(() => _isEmailAvailable = false);
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const <String>[],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    hintText: 'example@email.com',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F7FF),
                                    border: _outline(Colors.grey.shade300),
                                    enabledBorder: _outline(
                                      _isEmailAvailable
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                    ),
                                    focusedBorder: _outline(
                                      _isEmailAvailable ? Colors.green : _purple,
                                    ),
                                  ),
                                ),
                                if (_isEmailAvailable)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GradientButton(
                            text: _isCheckingEmail
                                ? '확인 중...'
                                : _isEmailAvailable
                                    ? '확인완료'
                                    : '중복확인',
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            bgOverride: _isEmailAvailable ? Colors.green : null,
                            onTap: (!_isCheckingEmail &&
                                    !_isEmailAvailable &&
                                    _usernameCtrl.text.trim().isNotEmpty)
                                ? _checkEmailDuplicate
                                : null,
                          ),
                        ],
                      ),
                      if (!_isEmailAvailable && _usernameCtrl.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '이메일 중복 확인이 필요합니다',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 비밀번호
                      const _FieldLabel('비밀번호'),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: _obscure,
                        autofillHints: const <String>[],
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: '8자 이상 입력해주세요',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8F7FF),
                          border: _outline(Colors.grey.shade300),
                          enabledBorder: _outline(Colors.grey.shade300),
                          focusedBorder: _outline(_purple),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // 비밀번호 확인
                      const _FieldLabel('비밀번호 확인'),
                      TextField(
                        controller: _pwConfirmCtrl,
                        obscureText: _obscureConfirm,
                        autofillHints: const <String>[],
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 다시 입력해주세요',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8F7FF),
                          border: _outline(Colors.grey.shade300),
                          enabledBorder: _outline(Colors.grey.shade300),
                          focusedBorder: _outline(_purple),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_pwConfirmCtrl.text.isNotEmpty &&
                          _pwCtrl.text != _pwConfirmCtrl.text)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '비밀번호가 일치하지 않습니다',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),

                      // 약관
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _toggleAgreeAll,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('전체 동의',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            _GradientCheck(
                              checked: _agreeTerms &&
                                  _agreePrivacy &&
                                  _agreeMarketing,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AgreeRow(
                        label: '(필수) 서비스 이용약관',
                        checked: _agreeTerms,
                        onChanged: (v) => setState(() => _agreeTerms = v),
                      ),
                      const SizedBox(height: 8),
                      _AgreeRow(
                        label: '(필수) 개인정보 처리방침',
                        checked: _agreePrivacy,
                        onChanged: (v) => setState(() => _agreePrivacy = v),
                      ),
                      const SizedBox(height: 8),
                      _AgreeRow(
                        label: '(선택) 마케팅 정보 수신 동의',
                        checked: _agreeMarketing,
                        onChanged: (v) => setState(() => _agreeMarketing = v),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
              child: _GradientButton(
                text: _loading ? '가입 중...' : '가입하기',
                onTap: (!_loading && _canSubmit) ? _submit : null,
                height: 56,
                radius: 999,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 작은 필드 라벨
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF495565)),
      ),
    );
  }
}

/// 그라데이션 버튼
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    this.onTap,
    this.height = 48,
    this.padding,
    this.radius = 12,
    this.bgOverride,
  });

  final String text;
  final VoidCallback? onTap;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? bgOverride;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: bgOverride != null
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _RegisterScreenState._purple,
                      _RegisterScreenState._pink
                    ],
                  ),
            color: bgOverride,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// 체크 박스(그라데이션 배경)
class _GradientCheck extends StatelessWidget {
  const _GradientCheck({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: checked ? null : Border.all(color: const Color(0xFFD1D5DB), width: 2),
        gradient: checked
            ? const LinearGradient(
                colors: [
                  _RegisterScreenState._purple,
                  _RegisterScreenState._pink
                ],
              )
            : null,
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}

/// 약관 행
class _AgreeRow extends StatelessWidget {
  const _AgreeRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF374151), fontSize: 14)),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: checked ? null : Border.all(color: const Color(0xFFD1D5DB), width: 2),
              gradient: checked
                  ? const LinearGradient(
                      colors: [
                        _RegisterScreenState._purple,
                        _RegisterScreenState._pink
                      ],
                    )
                  : null,
            ),
            child: checked
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
