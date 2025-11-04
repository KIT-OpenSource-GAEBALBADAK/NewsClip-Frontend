// 회원가입, 회원정보 수정, 탈퇴 기능 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';

// 회원가입, 회원정보 수정, 탈퇴 기능 관리
class UserService {
  late final Dio _dio;

  UserService() {
    // DioService의 싱글톤 인스턴스 사용
    _dio = DioService().dio;
  }

  /// 회원가입
  /// POST https://newsclip.duckdns.org/v1/auth/register
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('🔵 회원가입 요청 시작');
      debugPrint('🔵 요청 URL: ${_dio.options.baseUrl}/auth/register');
      debugPrint('🔵 username: $username');
      debugPrint('🔵 password 길이: ${password.length}');

      final requestData = {
        'username': username,
        'password': password,
      };

      debugPrint('🔵 요청 데이터: $requestData');

      final response = await _dio.post(
        '/auth/register',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('✅ 응답 상태 코드: ${response.statusCode}');
      debugPrint('✅ 응답 데이터: ${response.data}');

      // ✅ 201 Created: 회원가입 성공
      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }

      // ✅ 409 Conflict: 이미 사용 중인 아이디
      if (response.statusCode == 409) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? '이미 사용 중인 아이디입니다.')
            : '이미 사용 중인 아이디입니다.';
        throw errorMessage;
      }

      // ✅ 400 Bad Request: 잘못된 요청
      if (response.statusCode == 400) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? '잘못된 요청 형식입니다')
            : '잘못된 요청 형식입니다';
        throw errorMessage;
      }

      throw '회원가입에 실패했습니다. (코드: ${response.statusCode})';
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생');
      debugPrint('❌ 타입: ${e.type}');
      debugPrint('❌ 메시지: ${e.message}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 헤더: ${e.response?.headers}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');
      debugPrint('❌ 요청 헤더: ${e.requestOptions.headers}');
      debugPrint('❌ 요청 데이터: ${e.requestOptions.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 400) {
          if (data is Map) {
            throw data['message'] ?? data['error'] ?? '잘못된 요청 형식입니다';
          }
          throw '잘못된 요청 형식입니다';
        }

        if (statusCode == 409 && data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '회원가입에 실패했습니다. (코드: $statusCode)';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '회원가입 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 이메일(username) 중복 확인
  /// POST https://newsclip.duckdns.org/v1/auth/check-username
  Future<bool> checkUsername({
    required String username,
  }) async {
    try {
      debugPrint('🔵 이메일 중복확인 요청 시작');
      debugPrint('🔵 요청 URL: ${_dio.options.baseUrl}/auth/check-username');
      debugPrint('🔵 username: $username');

      final requestData = {
        'username': username,
      };

      debugPrint('🔵 요청 데이터: $requestData');

      final response = await _dio.post(
        '/auth/check-username',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('✅ 응답 상태 코드: ${response.statusCode}');
      debugPrint('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final isAvailable = data['data']['isAvailable'] as bool;
        debugPrint('✅ 이메일 사용 가능 여부: $isAvailable');
        return isAvailable;
      }

      throw '이메일 중복확인에 실패했습니다. (코드: ${response.statusCode})';
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생');
      debugPrint('❌ 타입: ${e.type}');
      debugPrint('❌ 메시지: ${e.message}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 400) {
          if (data is Map) {
            throw data['message'] ?? data['error'] ?? '잘못된 요청 형식입니다';
          }
          throw '잘못된 요청 형식입니다';
        }

        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '이메일 중복확인에 실패했습니다. (코드: $statusCode)';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '이메일 중복확인 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }
}
