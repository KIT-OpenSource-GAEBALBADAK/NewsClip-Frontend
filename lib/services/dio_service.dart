import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// AuthService의 logout 함수를 사용하기 위해 import
import 'auth_service.dart';
import '../main.dart'; // navigatorKey 접근을 위해 import
import '../screens/login/login_screen.dart';

/// 중앙 집중식 Dio 인스턴스 관리 서비스
/// 모든 HTTP 요청에 사용되는 Dio 인스턴스를 싱글톤으로 제공
class DioService {
  static final DioService _instance = DioService._internal();
  late final Dio _dio;

  // 토큰 키 상수화
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // 🔥 토큰 재발급 중복 방지를 위한 플래그
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshCallbacks = [];

  /// 싱글톤 팩토리 생성자
  factory DioService() => _instance;

  /// Private 생성자
  DioService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://newsclip.duckdns.org/v1',

      headers: {'Content-Type': 'application/json'},
      // 타임아웃 시간을 30초로 늘립니다.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // 인터셉터: 모든 요청에 자동으로 토큰 추가 및 401 에러 시 토큰 재발급
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // 401 에러이고, 재발급 요청이 아닌 경우에만 토큰 재발급 시도
        if (error.response?.statusCode == 401 && error.requestOptions.path != '/auth/refresh') {
          print('▶️ 401 에러 감지. 토큰 재발급을 시도합니다.');

          final refreshToken = await _getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            print('⏹️ 리프레시 토큰이 없어 로그아웃 처리합니다.');
            await logout();
            _navigateToLogin();
            return handler.next(error);
          }

          // 🔥 이미 토큰 재발급 중이라면 대기
          if (_isRefreshing) {
            print('⏸️ 토큰 재발급 중... 대기열에 추가');

            // 재발급 완료를 기다렸다가 새로운 토큰으로 요청 재시도
            String? newToken;
            await Future.delayed(Duration.zero, () async {
              // 콜백 등록 방식으로 대기
              final completer = Completer<String>();
              _refreshCallbacks.add((token) => completer.complete(token));
              newToken = await completer.future;
            });

            if (newToken != null) {
              // 원래 요청을 새 토큰으로 재시도
              final originalRequestOptions = error.requestOptions;
              originalRequestOptions.headers['Authorization'] = 'Bearer $newToken';

              print('🔄 대기 완료. 새로운 토큰으로 원래 요청을 재시도합니다: ${originalRequestOptions.path}');
              try {
                final retryResponse = await _dio.fetch(originalRequestOptions);
                return handler.resolve(retryResponse);
              } catch (e) {
                return handler.next(error);
              }
            }
            return handler.next(error);
          }

          // 🔥 토큰 재발급 시작
          _isRefreshing = true;

          try {
            // 토큰 재발급 요청
            final refreshResponse = await _dio.post(
              '/auth/refresh',
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode == 200 && refreshResponse.data['status'] == 'success') {
              // 새로운 액세스 토큰 추출 및 저장
              final newAccessToken = refreshResponse.data['data']['accessToken'] as String;
              await _saveAccessToken(newAccessToken);
              print('✅ 토큰 재발급 성공.');

              // 🔥 대기 중인 모든 요청에 새 토큰 전달
              for (var callback in _refreshCallbacks) {
                callback(newAccessToken);
              }
              _refreshCallbacks.clear();
              _isRefreshing = false;

              // 실패했던 원래 요청의 헤더를 새로운 토큰으로 업데이트
              final originalRequestOptions = error.requestOptions;
              originalRequestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              // 원래 요청 재시도
              print('🔄 새로운 토큰으로 원래 요청을 재시도합니다: ${originalRequestOptions.path}');
              final retryResponse = await _dio.fetch(originalRequestOptions);
              return handler.resolve(retryResponse);
            } else {
              // 재발급은 성공했으나 응답 형식이 예상과 다를 경우
              _isRefreshing = false;
              _refreshCallbacks.clear();
              await logout();
              _navigateToLogin();
              return handler.next(error);
            }
          } on DioException catch (_) {
             print('❌ 토큰 재발급 실패. 사용자를 로그아웃 처리합니다.');
             _isRefreshing = false;
             _refreshCallbacks.clear();
             await logout();
             _navigateToLogin();
             return handler.next(error);
          }
        }
        
        return handler.next(error);
      },
    ));
  }

  /// Dio 인스턴스 getter
  Dio get dio => _dio;

  /// 로그인 화면으로 이동 (private)
  void _navigateToLogin() {
    // WidgetsBinding을 사용하여 다음 프레임에서 네비게이션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null && navigatorKey.currentState != null) {
        // 모든 화면을 제거하고 로그인 화면으로 이동
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  /// 액세스 토큰 가져오기 (private)
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// 리프레시 토큰 가져오기 (private)
  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  /// 새로운 액세스 토큰 저장 (private)
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
  }
}
