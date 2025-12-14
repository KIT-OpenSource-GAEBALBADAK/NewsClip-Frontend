import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // debugPrint 사용을 위해 추가
import '../services/dio_service.dart';
import '../models/bookmark.dart';

class BookmarkService {
  final Dio _dio = DioService().dio;

  /// 북마크 목록 조회
  /// GET /me/bookmarks?page=1&size=10
  Future<BookmarkResponse> getBookmarks({int page = 1, int size = 10}) async {
    try {
      final response = await _dio.get(
        '/me/bookmarks',
        queryParameters: {'page': page, 'size': size},
      );

      // [👇 이 로그를 추가해주세요] 서버가 주는 날것의 데이터를 확인해야 합니다.
      debugPrint('🔥 [DEBUG] 서버 응답 전체 JSON: ${response.data}');

      return BookmarkResponse.fromJson(response.data);

    } on DioException catch (e) {
      debugPrint('❌ 북마크 조회 실패: ${e.message}');
      // 필요하다면 여기서 사용자 정의 예외로 변환하여 throw 가능
      rethrow;
    } catch (e) {
      debugPrint('❌ 북마크 조회 알 수 없는 오류: $e');
      throw Exception('데이터를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// [수정] 북마크 토글
  /// POST /news/{newsId}/bookmark
  /// 성공 시 현재 북마크 상태(true=추가됨, false=삭제됨)를 반환
  Future<bool> toggleBookmark(int newsId) async {
    try {
      // 로그 추가: 요청 보내는 URL과 ID 확인
      debugPrint('📡 북마크 요청 시작: /news/$newsId/bookmark');

      final response = await _dio.post('/news/$newsId/bookmark');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          final isBookmarked = data['data']['is_bookmarked'];
          debugPrint('✅ 북마크 토글 성공 (ID: $newsId, 상태: $isBookmarked)');
          return isBookmarked == true;
        }
        return false;
      }
      throw Exception('상태 변경 실패');

    } on DioException catch (e) {
      // [디버깅 핵심] 상태 코드와 상세 내용 출력
      debugPrint('🚨 [DioError] Status: ${e.response?.statusCode}');
      debugPrint('🚨 [DioError] URL: ${e.requestOptions.path}');
      debugPrint('🚨 [DioError] Data: ${e.response?.data}');

      // 토큰이 잘 실려가는지 확인 (보안상 앞부분만 출력하거나 길이만 확인)
      final authHeader = e.requestOptions.headers['Authorization'];
      debugPrint('🚨 [DioError] Token 존재 여부: ${authHeader != null}');

      if (e.response != null) {
        final errorData = e.response?.data;
        // 서버에서 주는 에러 메시지가 있다면 사용
        final message = errorData is Map ? errorData['message'] : '서버 오류 발생';
        throw Exception(message);
      }
      throw Exception('네트워크 연결을 확인해주세요.');
    } catch (e) {
      debugPrint('❌ 알 수 없는 오류: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }
}