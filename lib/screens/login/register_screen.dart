import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../services/user_service.dart';
import 'email_login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(); // ✅ 아이디 필드
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // ✅ 이메일 중복확인 관련 상태
  bool _isCheckingEmail = false; // 중복확인 로딩 중
  bool? _isEmailAvailable; // null: 미확인, true: 사용가능, false: 사용불가
  String? _checkedEmail; // 중복확인한 이메일

  // ✅ 서비스 인스턴스 추가
  late final UserService _userService;

  final Color _fieldBorderColor = Colors.white;
  final Color _buttonColor = Colors.purpleAccent;

  @override
  void initState() {
    super.initState();
    // ✅ 서비스 초기화 - DioService를 중앙에서 관리하므로 직접 생성
    _userService = UserService();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        borderSide: BorderSide(color: _fieldBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        borderSide: BorderSide(color: _buttonColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 다시 입력하세요';
    }
    if (value != _pwCtrl.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  // ✅ 이메일 중복확인
  Future<void> _checkEmailDuplicate() async {
    final email = _usernameCtrl.text.trim();

    // ✅ 1단계: 이메일 형식 검증
    final emailError = validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable ? '사용 가능한 이메일입니다.' : '이미 사용 중인 이메일입니다.',
          ),
          backgroundColor: isAvailable ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEmailAvailable = null;
        _checkedEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('중복확인 실패: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ 이메일 중복확인 검증
    final currentEmail = _usernameCtrl.text.trim();
    if (_checkedEmail != currentEmail || _isEmailAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 중복확인을 해주세요'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final username = _usernameCtrl.text.trim();
      final password = _pwCtrl.text;

      // ✅ 1단계: 회원가입 API 호출
      final result = await _userService.register(
        username: username,
        password: password,
      );

      if (!mounted) return;

      // ✅ 회원가입 성공 메시지 표시
      final message = result['message'] ?? '회원가입이 완료되었습니다. 로그인해주세요.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ 이메일 로그인 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // ✅ 이메일 필드 + 중복확인 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usernameCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('이메일').copyWith(
                        suffixIcon: _isEmailAvailable != null
                            ? Icon(
                                _isEmailAvailable! ? Icons.check_circle : Icons.cancel,
                                color: _isEmailAvailable! ? Colors.green : Colors.red,
                              )
                            : null,
                      ),
                      validator: validateEmail,
                      onChanged: (value) {
                        // 이메일이 변경되면 중복확인 상태 초기화
                        if (_checkedEmail != null && value.trim() != _checkedEmail) {
                          setState(() {
                            _isEmailAvailable = null;
                            _checkedEmail = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCheckingEmail ? null : _checkEmailDuplicate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        disabledBackgroundColor: _buttonColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isCheckingEmail
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '중복확인',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwCtrl,
                obscureText: _obscure,
                decoration: _inputDecoration('비밀번호').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: validatePassword,
                onChanged: (_) {
                  if (_pwConfirmCtrl.text.isNotEmpty) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwConfirmCtrl,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration('비밀번호 확인').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validatePasswordConfirm,
                onChanged: (_) {
                  setState(() {});
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    disabledBackgroundColor: _buttonColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
