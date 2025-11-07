import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:newsclip/screens/login/register_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _valid = false;

  static const _purple = Color(0xFF8B5CF6);
  static const _pink = Color(0xFFEC4899);

  bool _checkEmail(String v) {
    final t = v.trim();
    return t.isNotEmpty && t.contains('@') && t.contains('.') && t.length > 5;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
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
              // ─── 상단 영역 ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
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

              // ─── 본문 영역 ─────────────────────────────
              const Text(
                '비밀번호 찾기',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '가입한 이메일 주소를 입력해주세요',
                style: TextStyle(
                  color: Color(0xFF697282),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // 이메일 입력 필드
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: ShapeDecoration(
                  color: const Color(0xFFF8F7FF),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1.15, color: Color(0xFFD0D5DB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _email,
                  onChanged: (v) => setState(() => _valid = _checkEmail(v)),
                  decoration: const InputDecoration(
                    hintText: '이메일',
                    hintStyle: TextStyle(color: Color(0xFF6B6B84), fontSize: 16),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[],
                  enableSuggestions: false,
                  autocorrect: false,
                ),
              ),

              const SizedBox(height: 32),

              // 인증 버튼
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _valid ? 1.0 : 0.40,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _valid
                      ? () {
                          final email = _email.text.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('인증 코드 전송: $email')),
                          );
                        }
                      : null,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_purple, _pink],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '인증 코드 전송',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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