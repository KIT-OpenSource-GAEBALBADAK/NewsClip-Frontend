import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'auth_service.dart';
import '../screens/home_screen.dart';

class KakaoAuthService {
  /// 카카오 웹 로그인 (앱 내부 WebView 사용)
  /// 백엔드 소셜 로그인 API와 연동하여 JWT 토큰을 받아 저장
  Future<bool> signInWithKakao(BuildContext context) async {
    try {
      // ✅ 카카오 OAuth URL 생성
      final authUrl = Uri.https(
        'kauth.kakao.com',
        '/oauth/authorize',
        {
          'client_id': '25c7ef75b2b00474bc1603a180884255', // TODO: 네이티브 앱 키
          'redirect_uri': 'kakao25c7ef75b2b00474bc1603a180884255://oauth',
          'response_type': 'code',
        },
      ).toString();

      // ✅ WebView로 로그인 페이지 표시
      final authCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => _KakaoWebViewScreen(url: authUrl),
        ),
      );

      if (authCode == null) {
        print('⚠️ 사용자가 로그인을 취소했습니다.');
        return false;
      }

      // ✅ 인증 코드로 카카오 토큰 발급
      final tokenResponse = await AuthApi.instance.issueAccessToken(authCode: authCode);
      await TokenManagerProvider.instance.manager.setToken(tokenResponse);
      print('✅ 카카오 토큰 발급 성공: ${tokenResponse.accessToken}');

      // ✅ 백엔드 소셜 로그인 API 호출
      final authService = AuthService();
      final success = await authService.socialLogin('kakao', tokenResponse.accessToken);

      if (!success) {
        print('❌ 백엔드 소셜 로그인 실패');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카카오 로그인에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      print('✅ 백엔드 소셜 로그인 성공');

      // ✅ 홈화면으로 이동 (모든 이전 화면 제거)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }

      return true;
    } catch (error) {
      print('❌ 카카오 로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카카오 로그인 중 오류가 발생했습니다: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // 참고: 로그아웃은 AuthService.logout()을 사용하세요.
  // 카카오 토큰은 백엔드로 전달 후 사용하지 않으므로 별도 로그아웃 불필요
}

/// 앱 내부 WebView 화면
class _KakaoWebViewScreen extends StatefulWidget {
  final String url;

  const _KakaoWebViewScreen({required this.url});

  @override
  State<_KakaoWebViewScreen> createState() => _KakaoWebViewScreenState();
}

class _KakaoWebViewScreenState extends State<_KakaoWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // ✅ 리다이렉트 URL에서 인증 코드 추출
            if (request.url.startsWith('kakao25c7ef75b2b00474bc1603a180884255://oauth')) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];

              if (code != null) {
                Navigator.pop(context, code); // 인증 코드 반환
              } else {
                Navigator.pop(context); // 로그인 취소
              }

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카카오 로그인'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

