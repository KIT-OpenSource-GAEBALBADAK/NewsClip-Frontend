// components/LoginScreen.tsx 변환
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section (LoginScreen.tsx의 로고 부분)
                _buildLogo(),
                
                const SizedBox(height: 48),
                
                // Description
                Text(
                  '소셜 계정으로 간편 로그인',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Kakao Login Button
                _SocialLoginButton(
                  onPressed: () {
                    context.read<AppProvider>().login('kakao');
                  },
                  backgroundColor: const Color(0xFFFEE500),
                  textColor: Colors.black,
                  icon: const Icon(Icons.chat_bubble, size: 20),
                  label: '카카오로 계속하기',
                ),
                
                const SizedBox(height: 12),
                
                // Google Login Button
                _SocialLoginButton(
                  onPressed: () {
                    context.read<AppProvider>().login('google');
                  },
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  borderColor: Colors.grey[300],
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: 'Google로 계속하기',
                ),

                const SizedBox(height: 12),

                // e-mail Login Button
                _SocialLoginButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder:  (_) => const EmailLoginScreen()),
                    );
                  },
                  backgroundColor: Colors.purpleAccent,
                  textColor: Colors.white,
                  borderColor: Colors.grey[300],
                  icon: const Icon(Icons.mail_outline_rounded, size: 24),
                  label: '이메일로 계속하기',
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    // LoginScreen.tsx의 그라데이션 로고
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'NewsClip',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '뉴스를 클립하다',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
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
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
