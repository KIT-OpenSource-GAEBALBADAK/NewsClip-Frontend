// 프로필 조회, 수정 기능 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';
import 'package:newsclip/models/profile_lists.dart';

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
      return response.data['data'] as Map<String, dynamic>;

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

  /// 7.7 내가 쓴 게시글 목록 조회
  /// GET /me/posts
  Future<MyPostList> getMyPosts({int page = 1, int size = 10}) async {
    try {
      debugPrint('🔵 내가 쓴 게시글 목록 조회 요청: page=$page, size=$size');

      final response = await _dio.get(
        '/me/posts',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      debugPrint('✅ 내가 쓴 게시글 목록 조회 성공');
      debugPrint('🔥 [DEBUG] 서버 응답 데이터(response.data["data"]): ${response.data['data']}');
      // response.data['data'] 전체를 넘겨서 MyPostList(페이징 정보 + 리스트)로 변환
      return MyPostList.fromJson(response.data['data']);

    } on DioException catch (e) {
      debugPrint('❌ 내가 쓴 게시글 조회 실패: ${e.message}');

      // 기존 에러 처리 로직과 통일성 유지
      if (e.response?.statusCode == 401) {
        throw '로그인이 필요합니다.';
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

      throw '게시글 목록을 불러오는 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 7.8 내가 쓴 댓글 목록 조회
  /// GET /me/comments
  Future<MyCommentList> getMyComments({int page = 1, int size = 10}) async {
    try {
      debugPrint('🔵 내가 쓴 댓글 목록 조회 요청: page=$page, size=$size');

      final response = await _dio.get(
        '/me/comments',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      debugPrint('✅ 내가 쓴 댓글 목록 조회 성공');
      // response.data['data'] 전체를 넘겨서 MyCommentList(페이징 정보 + 리스트)로 변환
      return MyCommentList.fromJson(response.data['data']);

    } on DioException catch (e) {
      debugPrint('❌ 내가 쓴 댓글 조회 실패: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw '로그인이 필요합니다.';
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

      throw '댓글 목록을 불러오는 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 7.5 내 선호 카테고리 설정
  /// PUT /me/preferences/categories
  Future<Map<String, dynamic>> updatePreferredCategories({
    required List<String> categories,
  }) async {
    try {
      debugPrint('🔵 선호 카테고리 설정 요청: $categories');

      final response = await _dio.put(
        '/me/preferences/categories',
        data: {
          'categories': categories,
        },
      );

      debugPrint('✅ 선호 카테고리 설정 성공');
      return response.data as Map<String, dynamic>;

    } on DioException catch (e) {
      debugPrint('❌ DioException 발생: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw '로그인이 필요합니다.';
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

      throw '선호 카테고리 설정 중 오류가 발생했습니다.';
    } catch (e) {
      debugPrint('❌ 예상치 못한 오류: $e');
      rethrow;
    }
  }
}
