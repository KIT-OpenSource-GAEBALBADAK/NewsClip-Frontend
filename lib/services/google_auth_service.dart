import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import '../screens/home_screen.dart';

class GoogleAuthService {
  // 구글 로그인 인스턴스 생성
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // ⚠️ Web 클라이언트 ID를 입력하세요 (Google Cloud Console에서 확인)
    // TODO: Google Cloud Console → API 및 서비스 → 사용자 인증 정보 → "웹 애플리케이션" 클라이언트 ID
    serverClientId: '577550543507-s99mf2l1jkfo0ov065r7858kt4veu5jp.apps.googleusercontent.com',
  );

  /// 구글 소셜 로그인
  /// 구글 로그인 후 ID Token을 백엔드로 전송하여 JWT 토큰을 받아 저장
  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('🔵 구글 로그인 시작');

      // ✅ 구글 로그인 실행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ 사용자가 구글 로그인을 취소했습니다.');
        return false;
      }

      debugPrint('✅ 구글 계정 선택 완료: ${googleUser.email}');

      // ✅ 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ID Token이 필수 (백엔드에서 검증용)
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('❌ ID Token을 받지 못했습니다.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구글 인증 토큰을 받지 못했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      debugPrint('✅ 구글 ID Token 발급 성공');
      debugPrint('🔑 ID Token (앞 50자): ${idToken.substring(0, idToken.length > 50 ? 50 : idToken.length)}...');

      // ✅ 백엔드 소셜 로그인 API 호출
      final authService = AuthService();
      final success = await authService.socialLogin('google', idToken);

      if (!success) {
        debugPrint('❌ 백엔드 소셜 로그인 실패');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구글 로그인에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      debugPrint('✅ 백엔드 소셜 로그인 성공');

      // ✅ 홈화면으로 이동 (모든 이전 화면 제거)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }

      return true;
    } catch (error) {
      debugPrint('❌ 구글 로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구글 로그인 중 오류가 발생했습니다: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// 구글 로그아웃 (선택적)
  /// 참고: 실제 로그아웃은 AuthService.logout()을 사용하세요.
  /// 이 메서드는 구글 계정 선택 캐시를 지우는 용도입니다.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ 구글 계정 캐시 삭제 완료');
    } catch (error) {
      debugPrint('❌ 구글 로그아웃 실패: $error');
    }
  }

  /// 현재 로그인된 구글 계정 정보 가져오기 (선택적)
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  /// 구글 계정 연결 해제 (선택적)
  /// 앱과 구글 계정의 연결을 완전히 끊습니다.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('✅ 구글 계정 연결 해제 완료');
    } catch (error) {
      debugPrint('❌ 구글 계정 연결 해제 실패: $error');
    }
  }
}
