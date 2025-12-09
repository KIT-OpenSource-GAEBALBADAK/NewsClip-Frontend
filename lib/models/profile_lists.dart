// profile_lists.dart

/// 7.7 내가 쓴 게시글 단일 아이템 모델
class MyPost {
  final int postId;
  final String title;
  final String content;
  final String category;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  MyPost({
    required this.postId,
    required this.title,
    required this.content,
    required this.category,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory MyPost.fromJson(Map<String, dynamic> json) {
    return MyPost(
      postId: json['postId'] ?? json['post_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      viewCount: json['viewCount'] ?? json['view_count'] ?? 0,
      likeCount: json['likeCount'] ?? json['like_count'] ?? 0,
      commentCount: json['commentCount'] ?? json['comment_count'] ?? 0,
      createdAt: DateTime.parse(
          json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 7.7 내가 쓴 게시글 목록 응답 모델 (Pagination 포함)
class MyPostList {
  final List<MyPost> posts;
  final int totalItems;
  final int totalPages;
  final int page;
  final int size;

  MyPostList({
    required this.posts,
    required this.totalItems,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  factory MyPostList.fromJson(Map<String, dynamic> json) {
    return MyPostList(
      posts: (json['posts'] as List<dynamic>?)
          ?.map((e) => MyPost.fromJson(e))
          .toList() ?? [],
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
    );
  }
}

/// ---------------------------------------------------------

/// 7.8 내가 쓴 댓글 단일 아이템 모델
class MyComment {
  final int commentId;
  final String content;
  final String targetType; // 'news' or 'post' 등
  final int targetId;
  final String targetTitle;
  final DateTime createdAt;

  MyComment({
    required this.commentId,
    required this.content,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    required this.createdAt,
  });

  factory MyComment.fromJson(Map<String, dynamic> json) {
    return MyComment(
      commentId: json['comment_id'] ?? 0,
      content: json['content'] ?? '',
      targetType: json['targetType'] ?? '',
      targetId: json['target_id'] ?? 0,
      targetTitle: json['target_title'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 7.8 내가 쓴 댓글 목록 응답 모델 (Pagination 포함)
class MyCommentList {
  final List<MyComment> comments;
  final int totalItems;
  final int totalPages;
  final int page;
  final int size;

  MyCommentList({
    required this.comments,
    required this.totalItems,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  factory MyCommentList.fromJson(Map<String, dynamic> json) {
    print('🔥 [DEBUG] 댓글 JSON 원본: $json');
    return MyCommentList(
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => MyComment.fromJson(e))
          .toList() ?? [],
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
    );
  }
}