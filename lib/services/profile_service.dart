// 프로필 조회, 수정 기능 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';

class ProfileService {
  late final Dio _dio;

  ProfileService() {
    // DioService의 싱글톤 인스턴스 사용
    _dio = DioService().dio;
  }

  /// 내 프로필 조회
  /// GET https://newsclip.duckdns.org/v1/me
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      // 디버깅 로그를 간단하게 수정합니다.
      debugPrint('🔵 프로필 조회 요청 시작');

      // 'validateStatus' 옵션을 제거하여 Dio가 401을 에러로 처리하도록 합니다.
      final response = await _dio.get('/me');

      debugPrint('✅ 프로필 조회 성공');
      // 인터셉터에서 재시도 후 성공하면 여기에 도달합니다.
      return response.data as Map<String, dynamic>;

    } on DioException catch (e) {
      debugPrint('❌ DioException 발생: ${e.message}');
      
      // 인터셉터의 재발급 실패 후에도 401이 올 수 있습니다.
      if (e.response?.statusCode == 401) {
        throw '인증에 실패했습니다. 다시 로그인해주세요.';
      }
      
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        throw data['message'];
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '프로필 조회 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 프로필 설정 (최초 1회)
  /// POST https://newsclip.duckdns.org/v1/auth/setup-profile
  Future<Map<String, dynamic>> setupProfile({
    required String nickname,
    String? profileImagePath,
  }) async {
    try {
      debugPrint('🔵 프로필 설정 요청 시작');

      final formData = FormData.fromMap({
        'nickname': nickname,
      });

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(
              profileImagePath,
              filename: profileImagePath.split('/').last,
            ),
          ),
        );
      }

      // 'validateStatus' 옵션을 제거합니다.
      final response = await _dio.post(
        '/auth/setup-profile',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint('✅ 프로필 설정 성공');
      return response.data as Map<String, dynamic>;
      
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생: ${e.message}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 401) {
          throw '로그인이 필요합니다.';
        }

        if (statusCode == 400 && data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '프로필 설정에 실패했습니다. (코드: $statusCode)';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw '서버 응답 시간이 초과되었습니다.';
      }

      if (e.type == DioExceptionType.connectionError) {
        throw '네트워크 연결을 확인해주세요.';
      }

      throw '프로필 설정 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }
}
