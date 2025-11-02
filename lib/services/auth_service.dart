import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _dio = Dio(BaseOptions(
      baseUrl: 'https://newsclip.duckdns.org/v1',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 인터셉터: 모든 요청에 자동으로 토큰 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 토큰 추가: Bearer ${token.substring(0, 20)}...');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        print('❌ API 에러 발생: ${error.response?.statusCode}');
        print('❌ 에러 데이터: ${error.response?.data}');
        return handler.next(error);
      },
    ));
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
}

// ========== 편의 함수들 ==========

Future<bool> login_check(String email, String password) =>
    AuthService().login(email, password);

Future<bool> socialLogin(String provider, String token) =>
    AuthService().socialLogin(provider, token);

Future<void> logout() => AuthService().logout();

Future<bool> isLoggedIn() => AuthService().isLoggedIn();

Future<String?> getAccessToken() => AuthService().getAccessToken();

