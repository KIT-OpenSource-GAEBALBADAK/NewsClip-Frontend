// 프로필 조회, 수정 기능 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  final Dio _dio;

  ProfileService(this._dio);

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

  // TODO: 프로필 수정
  // Future<void> updateProfile({
  //   String? nickname,
  //   File? profileImage,
  // }) async { ... }
}

