import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(); // ✅ 이름 필드
  final _usernameCtrl = TextEditingController(); // ✅ 아이디 필드
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // ✅ 서비스 인스턴스 추가
  late final UserService _userService;
  late final AuthService _authService;

  final Color _fieldBorderColor = Colors.white;
  final Color _buttonColor = Colors.purpleAccent;

  // 앞으로 백엔드와 통신시 AuthService의 Dio 인스턴스를 재사용!!!!!!!!!
  @override
  void initState() {
    super.initState();
    // ✅ 서비스 초기화
    _authService = AuthService(); // ✅ 싱글톤 인스턴스
    _userService = UserService(_authService.dio); // ✅ 동일한 Dio
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _pwCtrl.text;
    final nickname = _nicknameCtrl.text.trim();

    try {
      // ✅ 회원가입 API 호출
      final result = await _userService.register(
        name: name,
        username: username,
        password: password,
        nickname: nickname,
      );

      if (!mounted) return;

      final message = result['message'] ?? '회원가입이 완료되었습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
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
              const SizedBox(height: 20),
              // ✅ 이름 필드 추가
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('이름'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // ✅ 아이디 필드 (이메일 → 아이디로 변경)
              TextFormField(
                controller: _usernameCtrl,
                decoration: _inputDecoration('이메일'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이메일을 입력하세요';
                  }
                  return null;
                },
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameCtrl,
                decoration: _inputDecoration('닉네임'),
                validator: validateNickname,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    disabledBackgroundColor: _buttonColor.withOpacity(0.5),
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
