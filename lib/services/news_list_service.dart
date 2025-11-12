import 'package:dio/dio.dart';
import 'dio_service.dart';

class NewsListService {
  final Dio _dio;

  NewsListService() : _dio = DioService().dio;

  /// 뉴스 목록 조회
  ///
  /// [category]: 뉴스 카테고리 (예: 'politics', 'economy', 'society' 등)
  /// [page]: 페이지 번호 (1부터 시작)
  /// [size]: 페이지당 항목 수 (기본값: 20)
  ///
  /// Response 구조:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "뉴스 목록 조회 성공",
  ///   "data": {
  ///     "news": [...],
  ///     "totalPages": 15
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getNewsList({
    String? category,
    int page = 1,
    int size = 20,
  }) async {
    try {
      // ========================================
      // 🔹 실제 API용 Dio 코드 (프로덕션용)
      // ========================================
      final response = await _dio.get(
        '/news',
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'size': size,
        },
      );

      print('✅ 뉴스 목록 조회 성공');

      // 실제 API는 이미 data 필드를 포함한 Map을 반환합니다.
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
}
