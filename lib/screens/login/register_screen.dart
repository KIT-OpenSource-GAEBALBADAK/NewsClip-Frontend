import 'dart:async'; // Timer 사용을 위해 추가
import 'dart:math' as math;

import 'package:flutter/material.dart';
// 아래 import 경로들은 프로젝트 상황에 맞게 유지해주세요.
import '../../core/utils/validators.dart';
import '../../services/user_service.dart';
import 'email_login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ===== Design Token Colors =====
  static const Color _gradientStart = Color(0xFFCC6FF3);
  static const Color _gradientEnd = Color(0xFFFF8ACB);
  static const Color _primarySolid = Color(0xFFB95AED);
  static const Color _success = Color(0xFF22C55E);
  static const Color _error = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textPlaceholder = Color(0xFFA0A4B8);
  static const Color _borderDefault = Color(0xFFE5E7EB);
  static const Color _borderFocus = Color(0xFFCC6FF3);
  static const Color _borderSuccess = Color(0xFF22C55E);
  static const Color _bgInput = Color(0xFFF9FAFB);
  static const Color _toastBg = Color(0xFF111827);

  // Controllers
  final _emailCtrl = TextEditingController();
  final _verificationCodeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  // States
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // 이메일 인증 상태
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isEmailVerified = false;
  bool _showVerificationField = false;
  int _remainingSeconds = 0;
  int _resendCooldown = 0; // 재전송 쿨다운 (60초)
  String? _verificationToken;
  Timer? _resendTimer;

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
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _verificationCodeCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  bool get _allRequired => _agreeTerms && _agreePrivacy;

  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty &&
          _pwCtrl.text.isNotEmpty &&
          _pwConfirmCtrl.text.isNotEmpty &&
          _pwCtrl.text == _pwConfirmCtrl.text &&
          _allRequired &&
          _isEmailVerified;

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
        content: Text(
          msg,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? _success : _toastBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 76, left: 20, right: 20),
      ),
    );
  }

  static OutlineInputBorder _outline(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: 1.15),
  );

  // 이메일 인증번호 발송
  // 이메일 인증번호 발송 (중복확인 포함)
  Future<void> _sendVerificationCode() async {
    final email = _emailCtrl.text.trim();

    // 이메일 형식 검증
    final emailError = validateEmail(email);
    if (emailError != null) {
      _toast(emailError);
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      // ✅ 1단계: 이메일 중복확인 (checkUsername API 호출)
      debugPrint('🔵 Step 1: 이메일 중복확인 시작');
      final isAvailable = await _userService.checkUsername(username: email);

      if (!mounted) return;

      if (!isAvailable) {
        // 중복된 이메일
        _toast('이미 사용 중인 이메일입니다');
        return;
      }

      debugPrint('✅ Step 1: 이메일 사용 가능 확인됨');

      // ✅ 2단계: 인증번호 발송 (sendVerificationCode API 호출)
      debugPrint('🔵 Step 2: 인증번호 발송 시작');
      final response = await _userService.sendVerificationCode(
        email: email,
        type: 'signup',
      );

      if (!mounted) return;

      // 응답에서 유효시간 추출
      final expirationTime = response['data']?['expiration_time'] ?? 180;

      setState(() {
        _showVerificationField = true;
        _remainingSeconds = expirationTime;
      });

      _startTimer();
      _startResendCooldown(); // 재전송 쿨다운 시작 (1분)
      _toast('인증번호가 발송되었습니다', success: true);

      debugPrint('✅ Step 2: 인증번호 발송 완료 (유효시간: ${expirationTime}초)');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ 인증번호 발송 실패: $e');
      _toast('$e');
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  // 타이머 시작
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }
      });

      return _remainingSeconds > 0 &&
          _showVerificationField &&
          !_isEmailVerified;
    });
  }

  // 재전송 쿨다운 타이머 시작 (1분)
  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 60); // 1분 = 60초

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // 인증번호 확인
  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final code = _verificationCodeCtrl.text.trim();

    if (code.isEmpty) {
      _toast('인증번호를 입력해주세요');
      return;
    }

    setState(() => _isVerifyingCode = true);

    try {
      // ✅ 인증번호 검증 API 호출
      debugPrint('🔵 인증번호 검증 시작');
      final response = await _userService.verifyCode(
        email: email,
        code: code,
        type: 'signup',
      );

      if (!mounted) return;

      // 응답에서 인증 성공 여부 확인
      final isVerified = response['data']?['is_verified'] ?? false;

      if (isVerified) {
        setState(() {
          _isEmailVerified = true;
          _showVerificationField = false;
          _remainingSeconds = 0;
        });
        _toast('이메일 인증이 완료되었습니다', success: true);
        debugPrint('✅ 이메일 인증 완료');
      } else {
        _toast('인증번호가 일치하지 않습니다');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ 인증번호 검증 실패: $e');
      _toast('$e');
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _submit() async {
    final pwError = validatePassword(_pwCtrl.text);
    if (pwError != null) {
      _toast(pwError);
      return;
    }

    if (_pwCtrl.text != _pwConfirmCtrl.text) {
      _toast('비밀번호가 일치하지 않습니다');
      return;
    }

    if (!_isEmailVerified) {
      _toast('이메일 인증을 완료해주세요');
      return;
    }

    if (!_allRequired) {
      _toast('필수 약관에 동의해주세요');
      return;
    }

    setState(() => _loading = true);

    try {
      final username = _emailCtrl.text.trim();
      final password = _pwCtrl.text;

      final result = await _userService.register(
        username: username,
        password: password,
      );

      if (!mounted) return;

      final message = result['message'] ?? '회원가입이 완료되었습니다. 로그인해주세요.';
      _toast(message, success: true);

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
                        colors: [_gradientStart, _gradientEnd],
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

                      const SizedBox(height: 24),

                      // 이메일
                      const _FieldLabel('이메일'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailCtrl,
                              // 인증번호 발송 후 또는 인증 완료 시 수정 불가
                              enabled: !_showVerificationField && !_isEmailVerified,
                              onChanged: (_) {
                                setState(() {});
                              },
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const <String>[],
                              enableSuggestions: false,
                              autocorrect: false,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'example@email.com',
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: _textPlaceholder,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: _bgInput,
                                border: _outline(_borderDefault),
                                enabledBorder: _outline(
                                  _isEmailVerified
                                      ? _borderSuccess
                                      : _borderDefault,
                                ),
                                focusedBorder: _outline(
                                  _isEmailVerified
                                      ? _borderSuccess
                                      : _borderFocus,
                                ),
                                disabledBorder: _outline(
                                  _isEmailVerified
                                      ? _borderSuccess
                                      : _borderDefault,
                                ),
                                suffixIcon: _isEmailVerified
                                    ? const Icon(Icons.check_circle,
                                        color: _success, size: 20)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 우측 버튼 (상태에 따라 변경)
                          if (_isEmailVerified)
                            Container(
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: _success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _success),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '인증완료',
                                style: TextStyle(
                                  color: _success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else if (_showVerificationField)
                            _SideButton(
                              text: _resendCooldown > 0
                                  ? '재발송 (${_resendCooldown}초)'
                                  : '재발송',
                              onTap: (_isSendingCode || _resendCooldown > 0)
                                  ? null
                                  : _sendVerificationCode,
                              isSolid: _resendCooldown == 0,
                            )
                          else
                            _SideButton(
                              text: '인증하기',
                              onTap: (_emailCtrl.text.isNotEmpty &&
                                      !_isSendingCode)
                                  ? _sendVerificationCode
                                  : null,
                              isSolid: true,
                            ),
                        ],
                      ),

                      // 인증번호 입력 (인증 중)
                      if (_showVerificationField) ...[
                        const SizedBox(height: 12),
                        const _FieldLabel('인증번호'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _verificationCodeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: '인증번호 6자리',
                                  hintStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: _textPlaceholder,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  filled: true,
                                  fillColor: _bgInput,
                                  border: _outline(_borderDefault),
                                  enabledBorder: _outline(_borderDefault),
                                  focusedBorder: _outline(_borderFocus),
                                  suffixIcon: _remainingSeconds > 0
                                      ? Padding(
                                    padding:
                                    const EdgeInsets.only(right: 16),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SideButton(
                              text: '확인',
                              onTap: _isVerifyingCode ? null : _verifyCode,
                              isSolid: true,
                            ),
                          ],
                        ),
                        if (_remainingSeconds == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              '인증시간이 만료되었습니다. 재발송해주세요.',
                              style: TextStyle(fontSize: 12, color: _error),
                            ),
                          ),
                      ],

                      const SizedBox(height: 12),

                      // 비밀번호
                      const _FieldLabel('비밀번호'),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: _obscure,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '8자 이상 입력해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: _textPlaceholder,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: _bgInput,
                          border: _outline(_borderDefault),
                          enabledBorder: _outline(_borderDefault),
                          focusedBorder: _outline(_borderFocus),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 12),

                      // 비밀번호 확인
                      const _FieldLabel('비밀번호 확인'),
                      TextField(
                        controller: _pwConfirmCtrl,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '비밀번호를 다시 입력해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: _textPlaceholder,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: _bgInput,
                          border: _outline(_borderDefault),
                          enabledBorder: _outline(_borderDefault),
                          focusedBorder: _outline(_borderFocus),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
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
              padding: const EdgeInsets.symmetric(horizontal: 24)
                  .copyWith(bottom: 24),
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
                Color(0xFFCC6FF3), // gradientStart
                Color(0xFFFF8ACB), // gradientEnd
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

/// 작은 버튼 ("재발송", "확인" - suffixIcon 내부용)
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.text,
    required this.onTap,
    required this.isGradient,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isGradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isGradient
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFCC6FF3), Color(0xFFFF8ACB)],
                  )
                : null,
            color: isGradient ? null : const Color(0xFFB95AED),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 메인 버튼 ("인증하기")
class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.text,
    required this.onTap,
    required this.height,
  });

  final String text;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFCC6FF3), Color(0xFFFF8ACB)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 입력창 우측에 붙는 사이드 버튼
class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.text,
    required this.onTap,
    this.isSolid = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isSolid;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52, // TextField 높이와 맞춤
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSolid
                ? const LinearGradient(
                    colors: [Color(0xFFCC6FF3), Color(0xFFFF8ACB)],
                  )
                : null,
            color: isSolid ? null : Colors.white,
            border: isSolid ? null : Border.all(
              color: const Color(0xFFCC6FF3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSolid ? Colors.white : const Color(0xFFCC6FF3),
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
        border: checked
            ? null
            : Border.all(color: const Color(0xFFD1D5DB), width: 2),
        gradient: checked
            ? const LinearGradient(
          colors: [Color(0xFFCC6FF3), Color(0xFFFF8ACB)],
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
          Text(label,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 14)),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: checked
                  ? null
                  : Border.all(color: const Color(0xFFD1D5DB), width: 2),
              gradient: checked
                  ? const LinearGradient(
                colors: [Color(0xFFCC6FF3), Color(0xFFFF8ACB)],
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