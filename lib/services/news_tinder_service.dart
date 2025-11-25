import 'package:dio/dio.dart';
import 'dio_service.dart';

class NewsTinderService {
  final Dio _dio;

  NewsTinderService() : _dio = DioService().dio;

  /// 쇼츠 피드 조회
  Future<Map<String, dynamic>> getShorts({int size = 10}) async {
    try {
      final response = await _dio.get(
        '/shorts',
        queryParameters: {'size': size},
      );
      print('✅ 쇼츠 피드 조회 성공');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        throw Exception('쇼츠 피드 조회 실패: $statusCode - ${errorData?['message'] ?? e.message}');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('쇼츠 피드 조회 중 알 수 없는 오류 발생: $e');
    }
  }
}
