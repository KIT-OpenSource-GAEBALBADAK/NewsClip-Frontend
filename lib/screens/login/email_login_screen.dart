import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _canSubmit => _email.text.isNotEmpty && _password.text.isNotEmpty && !_loading;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final emailError = validateEmail(_email.text.trim());
    final passwordError = validatePassword(_password.text);

    if (emailError != null || passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ?? passwordError ?? '입력값을 확인해주세요.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final email = _email.text.trim();
    final password = _password.text;

    try {
      final bool success = await login_check(email, password);
      if (!mounted) return;

      if (success) {
        // 모든 이전 화면을 제거하고 홈 화면으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 또는 비밀번호가 일치하지 않습니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: _GradientText(
                                'NewsClip',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontFamily: 'Pretendard Variable',
                                  fontWeight: FontWeight.w700,
                                  height: 1.11,
                                ),
                                colors: const [Color(0xFFAC46FF), Color(0xFFF6329A)],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                '뉴스를 클립하다',
                                style: TextStyle(
                                  color: Color(0xFF697282),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard Variable',
                                  fontWeight: FontWeight.w400,
                                  height: 1.43,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Center(
                              child: Text(
                                '이메일 로그인',
                                style: TextStyle(
                                  color: Color(0xFF495565),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard Variable',
                                  fontWeight: FontWeight.w400,
                                  height: 1.43,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _FieldShell(
                              child: TextField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  hintText: '이메일',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const <String>[],
                                enableSuggestions: false,
                                autocorrect: false,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldShell(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _password,
                                      obscureText: _obscure,
                                      decoration: const InputDecoration(
                                        hintText: '비밀번호',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      autofillHints: const <String>[],
                                      enableSuggestions: false,
                                      autocorrect: false,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF6B6B84),
                                      size: 20,
                                    ),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Text(
                                    '비밀번호 찾기',
                                    style: TextStyle(
                                      color: Color(0xFF697282),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w500,
                                      height: 1.33,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Opacity(
                              opacity: _canSubmit ? 1.0 : 0.40,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _canSubmit ? _submit : null,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [Color(0xFFAC46FF), Color(0xFFF6329A)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
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
                                          '로그인',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Pretendard Variable',
                                            fontWeight: FontWeight.w600,
                                            height: 1.43,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => Navigator.of(context).pop(),
                              child: const SizedBox(
                                height: 48,
                                child: Center(
                                  child: Text(
                                    '다른 방법으로 로그인',
                                    style: TextStyle(
                                      color: Color(0xFF495565),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w500,
                                      height: 1.43,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 200),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                              child: Column(
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      children: [
                                        const TextSpan(text: '로그인하시면 NewsClip의 '),
                                        TextSpan(
                                          text: '서비스 약관',
                                          style: const TextStyle(
                                              color: Colors.purpleAccent, fontWeight: FontWeight.w500),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              debugPrint('서비스 약관 클릭됨');
                                            },
                                        ),
                                        const TextSpan(text: ' 과 '),
                                        TextSpan(
                                          text: '개인정보 처리방침',
                                          style: const TextStyle(
                                              color: Colors.purpleAccent, fontWeight: FontWeight.w500),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              debugPrint('개인정보 처리방침 클릭됨');
                                            },
                                        ),
                                        const TextSpan(text: '에\n동의하는 것으로 간주됩니다.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      debugPrint('Sign Up tapped');
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('계정이 없으신가요? ',
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => const RegisterScreen())
                                            );
                                          },
                                          child: const Text(
                                            '가입하기',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purpleAccent,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                color: const Color(0xFF495565),
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  final Widget child;
  const _FieldShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8F7FF),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.15, color: Color(0xFFD0D5DB)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;
  const _GradientText(this.text, {required this.style, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}


