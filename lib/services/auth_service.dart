import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 로그인 로그아웃 토큰 관련 처리

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late final Dio _dio;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // ✅ factory 생성자 추가 (싱글톤 패턴)
  factory AuthService() => _instance;

  // ✅ private 생성자
  AuthService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://newsclip.duckdns.org/v1',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Dio get dio => _dio;

  Future<bool> login(String email, String password) async {
    try {
      print('🔵 로그인 요청 시작');
      print('🔵 URL: ${_dio.options.baseUrl}/auth/login');
      print('🔵 요청 데이터: username=$email');

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
      print('❌ 에러 메시지: ${e.message}');
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

  /// 토큰 저장
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

  /// 로그아웃
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
}

// ✅ 편의 함수들 (싱글톤 인스턴스 사용)
Future<bool> login_check(String email, String password) =>
    AuthService().login(email, password);

Future<void> logout() => AuthService().logout();

Future<bool> isLoggedIn() => AuthService().isLoggedIn();

Future<String?> getAccessToken() => AuthService().getAccessToken();
