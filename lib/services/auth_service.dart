import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_service.dart';

/// 로그인, 로그아웃, 토큰 관리를 담당하는 서비스
class AuthService {
  static final AuthService _instance = AuthService._internal();
  late final Dio _dio;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// 싱글톤 팩토리 생성자
  factory AuthService() => _instance;

  /// Private 생성자
  AuthService._internal() {
    // DioService의 싱글톤 인스턴스 사용
    _dio = DioService().dio;
  }

  /// Dio 인스턴스 getter
  Dio get dio => _dio;

  /// 이메일 로그인
  /// POST /auth/login
  Future<bool> login(String email, String password) async {
    try {
      print('🔵 로그인 요청 시작');
      print('🔵 URL: ${_dio.options.baseUrl}/auth/login');

      final response = await _dio.post('/auth/login', data: {
        'username': email,
        'password': password,
      });

      print('✅ 응답 코드: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        await _saveTokens(accessToken, refreshToken);
        return true;
      }
      throw Exception('이메일 또는 비밀번호가 일치하지 않습니다.');
    } on DioException catch (e) {
      print('❌ DioException 타입: ${e.type}');
      print('❌ 응답 코드: ${e.response?.statusCode}');
      print('❌ 응답 데이터: ${e.response?.data}');

      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        throw Exception('이메일 또는 비밀번호가 일치하지 않습니다.');
      }
      throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } catch (e) {
      print('❌ 일반 예외: $e');
      throw Exception('이메일 또는 비밀번호가 일치하지 않습니다.');
    }
  }

  /// 소셜 로그인
  /// POST /auth/social
  Future<bool> socialLogin(String provider, String token) async {
    try {
      print('🔵 소셜 로그인 요청 시작');
      print('🔵 Provider: $provider');

      final response = await _dio.post('/auth/social', data: {
        'provider': provider,
        'token': token,
      });

      print('✅ 응답 코드: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        await _saveTokens(accessToken, refreshToken);
        return true;
      }
      throw Exception('소셜 로그인에 실패했습니다.');
    } on DioException catch (e) {
      print('❌ DioException 타입: ${e.type}');
      print('❌ 응답 코드: ${e.response?.statusCode}');
      print('❌ 응답 데이터: ${e.response?.data}');
      throw Exception('소셜 로그인 중 오류가 발생했습니다.');
    } catch (e) {
      print('❌ 일반 예외: $e');
      throw Exception('소셜 로그인에 실패했습니다.');
    }
  }

  /// 토큰 저장 (private)
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 로그아웃 (토큰 삭제)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 이메일 인증번호 전송 (비밀번호 찾기용)
  /// POST /auth/email/send-code
  /// type: "reset" - 비밀번호 찾기용
  Future<Map<String, dynamic>> sendPasswordResetCode(String email) async {
    try {
      print('🔵 비밀번호 찾기 인증번호 전송 요청');
      print('🔵 email: $email');

      final response = await _dio.post('/auth/email/send-code', data: {
        'email': email,
        'type': 'reset',
      });

      print('✅ 응답 코드: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('인증번호 전송에 실패했습니다.');
    } on DioException catch (e) {
      print('❌ DioException 타입: ${e.type}');
      print('❌ 응답 코드: ${e.response?.statusCode}');
      print('❌ 응답 데이터: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('가입되지 않은 이메일입니다.');
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? '잘못된 요청입니다.';
        throw Exception(message);
      }
      throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } catch (e) {
      print('❌ 일반 예외: $e');
      rethrow;
    }
  }

  /// 이메일 인증번호 검증 (비밀번호 찾기용)
  /// POST /auth/email/verify-code
  /// type: "reset" - 비밀번호 찾기용
  /// 성공 시 reset_token 반환
  Future<String> verifyPasswordResetCode(String email, String code) async {
    try {
      print('🔵 비밀번호 찾기 인증번호 검증 요청');
      print('🔵 email: $email');
      print('🔵 code: $code');

      final response = await _dio.post('/auth/email/verify-code', data: {
        'email': email,
        'code': code,
        'type': 'reset',
      });

      print('✅ 응답 코드: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final resetToken = response.data['data']['reset_token'] as String?;
        if (resetToken == null || resetToken.isEmpty) {
          throw Exception('reset_token을 받지 못했습니다.');
        }
        return resetToken;
      }
      throw Exception('인증번호 검증에 실패했습니다.');
    } on DioException catch (e) {
      print('❌ DioException 타입: ${e.type}');
      print('❌ 응답 코드: ${e.response?.statusCode}');
      print('❌ 응답 데이터: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        throw Exception('인증번호가 일치하지 않습니다.');
      }
      if (e.response?.statusCode == 410) {
        throw Exception('인증번호가 만료되었습니다. 재발송해주세요.');
      }
      throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } catch (e) {
      print('❌ 일반 예외: $e');
      rethrow;
    }
  }

  /// 비밀번호 재설정 (비로그인 상태)
  /// POST /auth/password/reset
  Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      print('🔵 비밀번호 재설정 요청');
      print('🔵 email: $email');

      final response = await _dio.post('/auth/password/reset', data: {
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      });

      print('✅ 응답 코드: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      }
      throw Exception('비밀번호 재설정에 실패했습니다.');
    } on DioException catch (e) {
      print('❌ DioException 타입: ${e.type}');
      print('❌ 응답 코드: ${e.response?.statusCode}');
      print('❌ 응답 데이터: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? '잘못된 요청입니다.';
        throw Exception(message);
      }
      if (e.response?.statusCode == 401) {
        throw Exception('유효하지 않은 인증 토큰입니다.');
      }
      throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } catch (e) {
      print('❌ 일반 예외: $e');
      rethrow;
    }
  }
}

// ========== 편의 함수들 ==========

Future<bool> login_check(String email, String password) =>
    AuthService().login(email, password);

Future<bool> socialLogin(String provider, String token) =>
    AuthService().socialLogin(provider, token);

Future<void> logout() => AuthService().logout();

Future<bool> isLoggedIn() => AuthService().isLoggedIn();

Future<String?> getAccessToken() => AuthService().getAccessToken();

// 비밀번호 찾기/재설정 관련
Future<Map<String, dynamic>> sendPasswordResetCode(String email) =>
    AuthService().sendPasswordResetCode(email);

Future<String> verifyPasswordResetCode(String email, String code) =>
    AuthService().verifyPasswordResetCode(email, code);

Future<bool> resetPassword({
  required String email,
  required String resetToken,
  required String newPassword,
}) =>
    AuthService().resetPassword(
      email: email,
      resetToken: resetToken,
      newPassword: newPassword,
    );

