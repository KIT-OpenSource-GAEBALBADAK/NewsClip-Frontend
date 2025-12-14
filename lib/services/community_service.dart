import 'package:dio/dio.dart';
import 'package:newsclip/services/dio_service.dart';
import 'package:newsclip/models/community.dart';

/// 커뮤니티 기능(게시글 조회, 작성, 상호작용) 관련
/// 서버 통신을 담당하는 서비스 클래스
class CommunityService {

  // [1. 복구] DioService().dio를 사용하도록 복구
  final Dio _dio = DioService().dio;


  /// 5.1. 게시글 목록 조회
  Future<List<CommunityPost>> getPosts({
    required String type, // 'all', 'expert', 'general'
    required int page,
    int size = 20,
  }) async {
    try {
      // [2. 복구] 실제 서버 경로 및 응답 처리 로직 복구
      final response = await _dio.get( // 👈 _dio 사용
        '/community/posts', // 실제 서버 경로
        queryParameters: {
          'type': type,
          'page': page,
          'size': size,
        },
      );
      print('✅ [DEBUG] Raw Response Data: ${response.data}');
      print('✅ [DEBUG] Raw Response Type: ${response.data.runtimeType}');

      // [실제 서버 응답 처리]
      if (response.data['status'] == 'success') {
        final List<dynamic> postListJson = response.data['data']['posts'] ?? [];
        return postListJson
            .map((json) => CommunityPost.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load posts: ${response.data['message']}');
      }

    } on DioException catch (e) {
      // (이하 에러 핸들링은 동일)
      print('❌ CommunityService.getPosts() DioException: $e');
      print('❌ [DEBUG] Dio Error Response: ${e.response?.data}');
      throw Exception('게시글을 불러오는 데 실패했습니다: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.getPosts() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 5.2. 게시글 작성
  Future<CommunityPost> createPost({
    required String category,
    required String title,
    required String content,
    List<String> filePaths = const [], // 파일 경로 리스트
  }) async {
    // [DEBUG] 함수 호출 및 입력 값 확인 (디버그 로그는 그대로 둡니다)
    print("--- 🚀 CommunityService createPost ---");
    print("▶️ Category: $category");
    print("▶️ Title: $title");
    print("▶️ File count: ${filePaths.length}");

    try {
      // [3. 복구] 실제 서버용 FormData 로직 복구
      // (API 5.2 명세에 따라 이미지가 있든 없든 항상 FormData로 전송)

      final Map<String, dynamic> formDataMap = {
        'category': category,
        'title': title,
        'content': content,
      };

      if (filePaths.isNotEmpty) {
        List<MultipartFile> files = [];
        for (String path in filePaths) {
          files.add(await MultipartFile.fromFile(path));
        }
        formDataMap['files'] = files;
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post( // 👈 _dio 사용
        '/community/posts', // 실제 서버 경로
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // [DEBUG] 응답 확인
      print('✅ [DEBUG] createPost Raw Response Data: ${response.data}');
      print('✅ [DEBUG] createPost Raw Response Type: ${response.data.runtimeType}');
      print('✅ [DEBUG] createPost Status Code: ${response.statusCode}');

      // [실제 서버 응답 처리]
      // 응답이 빈 문자열이거나 null인 경우 처리
      if (response.data == null || response.data == '' || response.data is String) {
        throw Exception('서버로부터 유효하지 않은 응답을 받았습니다. (빈 응답 또는 문자열)');
      }

      if (response.data['status'] == 'success') {
        return CommunityPost.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create post: ${response.data['message']}');
      }

    } on DioException catch (e) {
      // (이하 에러 핸들링은 동일)
      print('❌ CommunityService.createPost() DioException: $e');
      print('❌ Dio Error Type: ${e.type}');
      print('❌ Dio Error Response: ${e.response?.data}');
      throw Exception('게시글 작성에 실패했습니다: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.createPost() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    } finally {
      print("--- 🏁 CommunityService createPost End ---");
    }
  }

  /// 5.3. (추정) 게시글 상호작용 (좋아요/싫어요)
  Future<Map<String, dynamic>> interactWithPost(
      String postId,
      String interactionType,
      ) async {
    if (interactionType != 'like' && interactionType != 'dislike') {
      throw ArgumentError('interactionType must be "like" or "dislike".');
    }

    try {
      // [4. 복구] 실제 서버용 로직 복구
      final response = await _dio.post( // 👈 _dio 사용
        '/community/posts/$postId/interact',
        data: {
          'interaction_type': interactionType,
        },
      );

      if (response.data['status'] == 'success') {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to interact with post: ${response.data['message']}');
      }

    } on DioException catch (e) {
      print('❌ CommunityService.interactWithPost() DioException: $e');
      throw Exception('상호작용에 실패했습니다: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.interactWithPost() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 5.4. 게시글 삭제
  /// DELETE /community/posts/{post_id}
  Future<void> deletePost(String postId) async {
    try {
      final response = await _dio.delete('/community/posts/$postId');

      if (response.data['status'] == 'success') {
        // 성공 시 아무것도 리턴하지 않거나, 로그만 남김
        print('✅ 게시글 삭제 성공: $postId');
      } else {
        throw Exception('Failed to delete post: ${response.data['message']}');
      }
    } on DioException catch (e) {
      print('❌ CommunityService.deletePost() DioException: $e');
      throw Exception('게시글 삭제 실패: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.deletePost() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 6.1. 댓글 목록 조회
  /// GET /community/posts/{id}/comments
  Future<List<CommentItem>> getComments(String postId) async {
    try {

      print('🔍 [DEBUG] 요청하려는 postId: "$postId"');
      print('🔍 [DEBUG] 실제 요청 URL: /community/posts/$postId/comments');

      final response = await _dio.get('/community/posts/$postId/comments');

      if (response.data['status'] == 'success') {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.map((e) => CommentItem.fromJson(e)).toList();
      } else {
        throw Exception('댓글 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      print('❌ CommunityService.getComments() DioException: $e');
      throw Exception('댓글을 불러오지 못했습니다: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.getComments() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 6.2. 댓글 작성
  /// POST /community/posts/{id}/comments
  Future<void> createComment(String postId, String content) async {
    try {
      final response = await _dio.post(
        '/community/posts/$postId/comments',
        data: {'content': content},
      );

      if (response.data['status'] != 'success') {
        throw Exception('댓글 작성 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      print('❌ CommunityService.createComment() DioException: $e');
      throw Exception('댓글 작성에 실패했습니다: ${e.message}');
    } catch (e) {
      print('❌ CommunityService.createComment() Exception: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }
}