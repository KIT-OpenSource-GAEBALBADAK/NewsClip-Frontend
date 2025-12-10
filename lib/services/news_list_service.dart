import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';

class NewsListService {
  final Dio _dio;

  NewsListService() : _dio = DioService().dio;

  /// 뉴스 목록 조회
  Future<Map<String, dynamic>> getNewsList({
    String? category,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/news',
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'size': size,
        },
      );
      debugPrint('✅ 실제 API에서 뉴스 목록 조회 성공');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        if (statusCode == 400) {
          throw Exception(errorData['message'] ?? '잘못된 요청입니다');
        } else if (statusCode == 404) {
          throw Exception('뉴스를 찾을 수 없습니다');
        } else if (statusCode == 500) {
          throw Exception('서버 오류가 발생했습니다');
        }
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('뉴스 목록 조회 실패: $e');
    }
  }

  /// 뉴스 상세 정보 조회 (수정된 버전)
  /// GET /news/{newsId}
  Future<Map<String, dynamic>> getNewsDetail(int newsId) async {
    try {
      final response = await _dio.get('/news/$newsId');
      debugPrint('✅ 뉴스 상세 정보 조회 성공: $newsId');
      // API 리스폰스의 data 객체를 그대로 반환
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('존재하지 않는 뉴스입니다.');
      }
      throw Exception('뉴스 상세 정보 조회 중 오류 발생: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류 발생: $e');
    }
  }

  /// 뉴스 북마크 토글
  /// POST /news/{newsId}/bookmark
  Future<bool> toggleBookmark(int newsId) async {
    try {
      final response = await _dio.post('/news/$newsId/bookmark');
      debugPrint('✅ 북마크 토글 성공: $newsId');
      return response.data['data']['is_bookmarked'] as bool;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? '북마크 처리 중 오류가 발생했습니다.');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('북마크 처리 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 뉴스 상호작용
  /// POST /news/{newsId}/interact
  Future<Map<String, dynamic>> interactWithNews(
      int newsId, String interactionType) async {
    try {
      final response = await _dio.post(
        '/news/$newsId/interact',
        data: {'interaction_type': interactionType},
      );
      debugPrint('✅ 뉴스 상호작용 ($interactionType) 성공: $newsId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? '상호작용 처리 중 오류가 발생했습니다.');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('상호작용 처리 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 뉴스 추천 목록 조회 (팝업용)
  /// GET /news/recommendations/popup?count=5
  Future<List<Map<String, dynamic>>> getRecommendedNews({int count = 5}) async {
    try {
      final response = await _dio.get(
        '/news/recommendations/popup',
        queryParameters: {'count': count},
      );
      debugPrint('✅ 추천 뉴스 목록 조회 성공 (${count}개)');

      final data = response.data['data'] as Map<String, dynamic>;
      final newsList = data['news'] as List<dynamic>;

      return newsList.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        if (statusCode == 400) {
          throw Exception(errorData['message'] ?? '잘못된 요청입니다');
        } else if (statusCode == 401) {
          throw Exception('로그인이 필요합니다');
        } else if (statusCode == 500) {
          throw Exception('서버 오류가 발생했습니다');
        }
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('추천 뉴스 조회 실패: $e');
    }
  }

  /// 뉴스 댓글 목록 조회
  /// GET /news/{newsId}/comments
  Future<Map<String, dynamic>> getNewsComments(int newsId) async {
    try {
      final response = await _dio.get('/news/$newsId/comments');
      debugPrint('✅ 댓글 목록 조회 성공: $newsId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;

        if (statusCode == 404) {
          throw Exception('뉴스를 찾을 수 없습니다');
        } else if (statusCode == 500) {
          throw Exception('서버 오류가 발생했습니다');
        }
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('댓글 목록 조회 실패: $e');
    }
  }

  /// 뉴스 댓글 작성
  /// POST /news/{newsId}/comments
  Future<Map<String, dynamic>> addNewsComment(int newsId, String content) async {
    try {
      final response = await _dio.post(
        '/news/$newsId/comments',
        data: {'content': content},
      );
      debugPrint('✅ 댓글 작성 성공: $newsId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        if (statusCode == 400) {
          throw Exception(errorData['message'] ?? '잘못된 요청입니다');
        } else if (statusCode == 404) {
          throw Exception('뉴스를 찾을 수 없습니다');
        } else if (statusCode == 500) {
          throw Exception('서버 오류가 발생했습니다');
        }
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('댓글 작성 실패: $e');
    }
  }
}
