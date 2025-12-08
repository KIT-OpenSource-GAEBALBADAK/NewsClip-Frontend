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

  /// 이메일 인증번호 전송
  /// POST https://newsclip.duckdns.org/v1/auth/email/send-code
  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    String type = 'signup',
  }) async {
    try {
      debugPrint('🔵 이메일 인증번호 전송 요청 시작');
      debugPrint('🔵 요청 URL: ${_dio.options.baseUrl}/auth/email/send-code');
      debugPrint('🔵 email: $email');
      debugPrint('🔵 type: $type');

      final requestData = {
        'email': email,
        'type': type,
      };

      debugPrint('🔵 요청 데이터: $requestData');

      final response = await _dio.post(
        '/auth/email/send-code',
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
        return response.data as Map<String, dynamic>;
      }

      // 409 Conflict: 이미 가입된 이메일 (signup 타입)
      if (response.statusCode == 409) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? '이미 가입된 이메일입니다.')
            : '이미 가입된 이메일입니다.';
        throw errorMessage;
      }

      // 404 Not Found: 가입되지 않은 이메일 (reset 타입)
      if (response.statusCode == 404) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? '가입되지 않은 이메일입니다.')
            : '가입되지 않은 이메일입니다.';
        throw errorMessage;
      }

      // 400 Bad Request
      if (response.statusCode == 400) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? '잘못된 요청 형식입니다')
            : '잘못된 요청 형식입니다';
        throw errorMessage;
      }

      throw '인증번호 전송에 실패했습니다. (코드: ${response.statusCode})';
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생');
      debugPrint('❌ 타입: ${e.type}');
      debugPrint('❌ 메시지: ${e.message}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 409) {
          if (data is Map) {
            throw data['message'] ?? '이미 가입된 이메일입니다.';
          }
          throw '이미 가입된 이메일입니다.';
        }

        if (statusCode == 404) {
          if (data is Map) {
            throw data['message'] ?? '가입되지 않은 이메일입니다.';
          }
          throw '가입되지 않은 이메일입니다.';
        }

        if (statusCode == 400) {
          if (data is Map) {
            throw data['message'] ?? data['error'] ?? '잘못된 요청 형식입니다';
          }
          throw '잘못된 요청 형식입니다';
        }

        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '인증번호 전송에 실패했습니다. (코드: $statusCode)';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '인증번호 전송 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 이메일 인증번호 검증
  /// POST https://newsclip.duckdns.org/v1/auth/email/verify-code
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
    String type = 'signup',
  }) async {
    try {
      debugPrint('🔵 이메일 인증번호 검증 요청 시작');
      debugPrint('🔵 요청 URL: ${_dio.options.baseUrl}/auth/email/verify-code');
      debugPrint('🔵 email: $email');
      debugPrint('🔵 code: $code');
      debugPrint('🔵 type: $type');

      final requestData = {
        'email': email,
        'code': code,
        'type': type,
      };

      debugPrint('🔵 요청 데이터: $requestData');

      final response = await _dio.post(
        '/auth/email/verify-code',
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
        return response.data as Map<String, dynamic>;
      }

      // 400 Bad Request: 잘못된 인증번호
      if (response.statusCode == 400) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? '인증번호가 일치하지 않습니다')
            : '인증번호가 일치하지 않습니다';
        throw errorMessage;
      }

      // 410 Gone: 만료된 인증번호
      if (response.statusCode == 410) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ?? '인증번호가 만료되었습니다. 재발송해주세요.')
            : '인증번호가 만료되었습니다. 재발송해주세요.';
        throw errorMessage;
      }

      throw '인증번호 검증에 실패했습니다. (코드: ${response.statusCode})';
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
            throw data['message'] ?? data['error'] ?? '인증번호가 일치하지 않습니다';
          }
          throw '인증번호가 일치하지 않습니다';
        }

        if (statusCode == 410) {
          if (data is Map) {
            throw data['message'] ?? '인증번호가 만료되었습니다. 재발송해주세요.';
          }
          throw '인증번호가 만료되었습니다. 재발송해주세요.';
        }

        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '인증번호 검증에 실패했습니다. (코드: $statusCode)';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '인증번호 검증 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }
}

// ========== 편의 함수들 ==========

/// 회원가입
Future<Map<String, dynamic>> register({
  required String username,
  required String password,
}) =>
    UserService().register(username: username, password: password);

/// 이메일(username) 중복 확인
Future<bool> checkUsername({required String username}) =>
    UserService().checkUsername(username: username);

/// 이메일 인증번호 전송 (회원가입용 또는 비밀번호 찾기용)
/// type: 'signup' (기본값) 또는 'reset'
Future<Map<String, dynamic>> sendVerificationCode({
  required String email,
  String type = 'signup',
}) =>
    UserService().sendVerificationCode(email: email, type: type);

/// 이메일 인증번호 검증 (회원가입용 또는 비밀번호 찾기용)
/// type: 'signup' (기본값) 또는 'reset'
/// reset 타입일 경우 response의 data에 reset_token이 포함됨
Future<Map<String, dynamic>> verifyCode({
  required String email,
  required String code,
  String type = 'signup',
}) =>
    UserService().verifyCode(email: email, code: code, type: type);

