import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:newsclip/screens/login/register_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/kakao_auth_service.dart';
import '../../services/google_auth_service.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Expanded(
                // This Column centers the main login content vertically
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 48),
                    Text(
                      '소셜 계정으로 간편 로그인',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _SocialLoginButton(
                      onPressed: () async {
                        final kakaoService = KakaoAuthService();
                        await kakaoService.signInWithKakao(context);
                        // signInWithKakao 내부에서 성공/실패 처리 및 화면 이동 처리됨
                      },
                      backgroundColor: const Color(0xFFFEE500),
                      textColor: Colors.black,
                      icon: const Icon(Icons.chat_bubble, size: 20),
                      label: '카카오로 계속하기',
                    ),
                    const SizedBox(height: 12),
                    _SocialLoginButton(
                      onPressed: () async {
                        final googleService = GoogleAuthService();
                        await googleService.signInWithGoogle(context);
                        // signInWithGoogle 내부에서 성공/실패 처리 및 화면 이동 처리됨
                      },
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.grey[300],
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: 'Google로 계속하기',
                    ),
                    const SizedBox(height: 24),
                    _buildOrDivider(), // New divider from your snippet
                    const SizedBox(height: 24),
                    _SocialLoginButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EmailLoginScreen()),
                        );
                      },
                      // Updated style based on your snippet
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.grey[300],
                      icon:
                      const Icon(Icons.mail_outline_rounded, size: 24),
                      label: '이메일로 로그인', // Updated text
                    ),
                  ],
                ),
              ),
              _buildFooter(context), // New footer from your snippet
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the logo widget from the original code
  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'NewsClip',
            style: TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text('뉴스를 클립하다',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  /// Builds the "또는" divider from your new snippet
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey[300])),
      ],
    );
  }

  /// Builds the footer section from your new snippet
  Widget _buildFooter(BuildContext context) {
    return Column(
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
                    // TODO: Handle Terms of Service tap
                    print('Terms of Service tapped');
                  },
              ),
              const TextSpan(text: ' 과 '),
              TextSpan(
                text: '개인정보 처리방침',
                style: const TextStyle(
                    color: Colors.purpleAccent, fontWeight: FontWeight.w500),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: Handle Privacy Policy tap
                    print('Privacy Policy tapped');
                  },
              ),
              const TextSpan(text: '에\n동의하는 것으로 간주됩니다.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            // TODO: Handle Sign Up tap
            print('Sign Up tapped');
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
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
