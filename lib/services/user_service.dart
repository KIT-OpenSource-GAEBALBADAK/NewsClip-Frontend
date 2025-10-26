// 회원가입, 회원정보 수정, 탈퇴 기능 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// 회원가입, 회원정보 수정, 탈퇴 기능 관리
class UserService {
  final Dio _dio;

  UserService(this._dio); // ✅ 생성자 : AuthService의 Dio 인스턴스를 주입받음

  /// 회원가입
  /// POST https://newsclip.duckdns.org/v1/auth/register
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String password,
    required String nickname,
  }) async {
    try {
      debugPrint('🔵 회원가입 요청 시작');
      debugPrint('🔵 이름: $name');
      debugPrint('🔵 아이디: $username');
      debugPrint('🔵 닉네임: $nickname');

      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'username': username,
          'password': password,
          'nickname': nickname,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('✅ 회원가입 성공 (201 Created)');
      debugPrint('✅ 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('❌ 회원가입 실패');
      debugPrint('❌ DioException 타입: ${e.type}');
      debugPrint('❌ 에러 메시지: ${e.message}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        // 409 Conflict - 이미 사용 중인 아이디
        if (statusCode == 409 && data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        // 기타 서버 에러 (4xx, 5xx)
        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '회원가입에 실패했습니다. (코드: $statusCode)';
      }

      // 네트워크 에러
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
}
