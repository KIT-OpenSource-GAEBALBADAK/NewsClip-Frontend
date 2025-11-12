import 'package:dio/dio.dart';
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
      print('✅ 실제 API에서 뉴스 목록 조회 성공');
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
      print('✅ 뉴스 상세 정보 조회 성공: $newsId');
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
}
