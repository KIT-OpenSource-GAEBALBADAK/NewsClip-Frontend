import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';

class NewsTinderService {
  final Dio _dio;

  NewsTinderService() : _dio = DioService().dio;

  /// 쇼츠 피드 조회
  Future<Map<String, dynamic>> getShorts({int size = 10, int? cursorId}) async {
    try {
      final queryParameters = <String, dynamic>{
        'size': size,
      };
      if (cursorId != null) {
        queryParameters['cursorId'] = cursorId;
      }

      final response = await _dio.get(
        '/shorts',
        queryParameters: queryParameters,
      );
      debugPrint('✅ 쇼츠 피드 조회 성공');
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

  /// 쇼츠와 상호작용 (좋아요/싫어요)
  Future<Map<String, dynamic>> interactWithShort(int shortId, String interactionType) async {
    try {
      final response = await _dio.post(
        '/shorts/$shortId/interact',
        data: {'interaction_type': interactionType},
      );
      debugPrint('✅ 쇼츠 상호작용 ($interactionType) 성공');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        throw Exception('쇼츠 상호작용 실패: $statusCode - ${errorData?['message'] ?? e.message}');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('쇼츠 상호작용 중 알 수 없는 오류 발생: $e');
    }
  }

  /// 쇼츠 댓글 조회
  Future<Map<String, dynamic>> getShortComments(int shortId) async {
    try {
      final response = await _dio.get('/shorts/$shortId/comments');
      debugPrint('✅ 쇼츠 댓글 조회 성공');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        throw Exception('쇼츠 댓글 조회 실패: $statusCode - ${errorData?['message'] ?? e.message}');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('쇼츠 댓글 조회 중 알 수 없는 오류 발생: $e');
    }
  }

  /// 쇼츠 댓글 작성
  Future<Map<String, dynamic>> addShortComment(int shortId, String content) async {
    try {
      final response = await _dio.post(
        '/shorts/$shortId/comments',
        data: {'content': content},
      );
      debugPrint('✅ 쇼츠 댓글 작성 성공');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        throw Exception('쇼츠 댓글 작성 실패: $statusCode - ${errorData?['message'] ?? e.message}');
      }
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('쇼츠 댓글 작성 중 알 수 없는 오류 발생: $e');
    }
  }
}
