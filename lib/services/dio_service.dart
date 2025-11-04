import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 중앙 집중식 Dio 인스턴스 관리 서비스
/// 모든 HTTP 요청에 사용되는 Dio 인스턴스를 싱글톤으로 제공
class DioService {
  static final DioService _instance = DioService._internal();
  late final Dio _dio;

  /// 싱글톤 팩토리 생성자
  factory DioService() => _instance;

  /// Private 생성자
  DioService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://newsclip.duckdns.org/v1',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 인터셉터: 모든 요청에 자동으로 토큰 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
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

  /// 액세스 토큰 가져오기 (private)
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}

