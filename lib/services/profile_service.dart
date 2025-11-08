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
      debugPrint('🔵 프로필 조회 요청 시작');
      debugPrint('🔵 요청 URL: ${_dio.options.baseUrl}/me');

      final response = await _dio.get(
        '/me',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('✅ 응답 상태 코드: ${response.statusCode}');
      debugPrint('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data as Map<String, dynamic>;
      }

      throw '프로필 조회에 실패했습니다. (코드: ${response.statusCode})';
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생');
      debugPrint('❌ 타입: ${e.type}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 401) {
          throw '로그인이 필요합니다.';
        }

        if (data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        throw '프로필 조회에 실패했습니다. (코드: $statusCode)';
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
      debugPrint('🔵 nickname: $nickname');
      debugPrint('🔵 profileImagePath: $profileImagePath');

      // FormData 구성
      final formData = FormData.fromMap({
        'nickname': nickname,
      });

      // 이미지 파일이 있으면 추가
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

      final response = await _dio.post(
        '/auth/setup-profile',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('✅ 응답 상태 코드: ${response.statusCode}');
      debugPrint('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data as Map<String, dynamic>;
      }

      // 에러 응답 처리
      if (response.data is Map && response.data.containsKey('message')) {
        throw response.data['message'];
      }

      throw '프로필 설정에 실패했습니다. (코드: ${response.statusCode})';
    } on DioException catch (e) {
      debugPrint('❌ DioException 발생');
      debugPrint('❌ 타입: ${e.type}');
      debugPrint('❌ 응답 코드: ${e.response?.statusCode}');
      debugPrint('❌ 응답 데이터: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        if (statusCode == 401) {
          throw '로그인이 필요합니다.';
        }

        if (statusCode == 400 && data is Map && data.containsKey('message')) {
          throw data['message'];
        }

        if (data is Map && data.containsKey('message')) {
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

