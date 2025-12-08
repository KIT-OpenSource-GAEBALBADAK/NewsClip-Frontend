import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'reset_password_screen.dart';
import '../../services/user_service.dart';

class ForgotPasswordVerifyCodeScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordVerifyCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPasswordVerifyCodeScreen> createState() =>
      _ForgotPasswordVerifyCodeScreenState();
}

class _ForgotPasswordVerifyCodeScreenState
    extends State<ForgotPasswordVerifyCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool isFilled = false;
  bool _loading = false;
  bool _resending = false;
  int _remainingSeconds = 180; // 3분 = 180초
  int _resendCooldown = 0; // 재전송 쿨다운 (60초)
  Timer? _timer;
  Timer? _resendTimer;

  // 디자인 토큰 (기존 코드 색상 기반)
  static const Color _gradientStart = Color(0xFF8B5CF6);
  static const Color _gradientEnd = Color(0xFFEC4899);
  static const Color _borderDefault = Color(0xFFD0D5DB);
  static const Color _bgInput = Color(0xFFF9FAFB);
  static const Color _textPlaceholder = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startResendCooldown(); // 화면 진입 시 바로 1분 재전송 제한 시작
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  // 3분 타이머 시작
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
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

  // 시간을 MM:SS 형식으로 변환
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더 (뒤로가기 + 로고)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).pop(),
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
                        alignment: Alignment.center,
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
                "인증 코드 입력",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard Variable',
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "이메일로 전송된 6자리 인증 코드를 입력해주세요", // 스크린샷 텍스트 반영
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF697282),
                  fontFamily: 'Pretendard Variable',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // [수정됨] 단일 TextField로 변경 (디자인 시안 반영)
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6, // 6자리 제한
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 가능
                ],
                onChanged: (value) {
                  setState(() => isFilled = value.length == 6);
                },
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  letterSpacing: 4.0, // 숫자 간 간격 넓힘
                ),
                decoration: InputDecoration(
                  counterText: "", // 하단 글자수 카운터 숨김
                  hintText: "인증 코드 6자리",
                  hintStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: _textPlaceholder,
                    letterSpacing: 0.0, // 힌트는 간격 정상
                  ),
                  filled: true,
                  fillColor: _bgInput,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
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
                    borderSide: const BorderSide(color: _gradientStart, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 타이머 표시
              Center(
                child: Text(
                  _remainingSeconds > 0
                      ? '남은 시간: ${_formatTime(_remainingSeconds)}'
                      : '인증 시간이 만료되었습니다. 재전송 버튼을 눌러주세요.',
                  style: TextStyle(
                    color: _remainingSeconds > 0 ? const Color(0xFF697282) : const Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
              const SizedBox(height: 8),


              // 재전송 버튼
              Center(
                child: InkWell(
                  onTap: (_resending || _resendCooldown > 0) ? null : () async {
                    setState(() => _resending = true);

                    try {
                      print('🔵 [비밀번호 찾기] 인증 코드 재전송 시작');
                      print('🔵 [비밀번호 찾기] email: ${widget.email}');
                      print('🔵 [비밀번호 찾기] type: reset');

                      // POST /auth/email/send-code (type: "reset") 재전송
                      final result = await UserService().sendVerificationCode(
                        email: widget.email,
                        type: 'reset',
                      );

                      if (!mounted) return;

                      // 타이머 재시작 (3분)
                      setState(() {
                        _remainingSeconds = result['data']['expiration_time'] ?? 180;
                      });
                      _startTimer();

                      // 재전송 쿨다운 시작 (1분)
                      _startResendCooldown();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("인증 코드가 재전송되었습니다"),
                          backgroundColor: Colors.green,
                        ),
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
                        setState(() => _resending = false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF980FFA)),
                            ),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? "재전송 (${_resendCooldown}초)"
                                : "인증 코드 재전송",
                            style: TextStyle(
                              color: _resendCooldown > 0
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF980FFA),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard Variable',
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),

              const Spacer(),

              // 인증하기 버튼
              InkWell(
                onTap: isFilled && !_loading
                    ? () async {
                        setState(() => _loading = true);

                        try {
                          print('🔵 [비밀번호 찾기] 인증 코드 검증 시작');
                          print('🔵 [비밀번호 찾기] email: ${widget.email}');
                          print('🔵 [비밀번호 찾기] code: ${_pinController.text.trim()}');
                          print('🔵 [비밀번호 찾기] type: reset (명시적 전달)');

                          // POST /auth/email/verify-code (type: "reset")
                          // 명시적으로 UserService 인스턴스 생성하여 호출
                          final result = await UserService().verifyCode(
                            email: widget.email,
                            code: _pinController.text.trim(),
                            type: 'reset', // 명시적으로 reset 전달
                          );

                          print('✅ [비밀번호 찾기] 인증 성공, reset_token 추출 중...');

                          // reset_token 추출 (필수!)
                          final resetToken = result['data']['reset_token'] as String;

                          print('✅ [비밀번호 찾기] reset_token 획득: ${resetToken.substring(0, 10)}...');

                          if (!mounted) return;

                          // 비밀번호 재설정 화면으로 이동하며 reset_token 전달
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ResetPasswordScreen(
                                email: widget.email,
                                resetToken: resetToken,
                              ),
                            ),
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
                    : null,
                borderRadius: BorderRadius.circular(40),
                child: Opacity(
                  opacity: isFilled && !_loading ? 1 : 0.4,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                      ),
                    ),
                    child: Center(
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
                              "인증하기",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                    ),
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