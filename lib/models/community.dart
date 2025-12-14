// models/community.dart

/// API 명세 5.1/5.2의 'author' 객체 모델
class PostAuthor {
  final String nickname;
  final String? profileImage;
  final String role; // "expert", "user" 등

  PostAuthor({
    required this.nickname,
    this.profileImage,
    required this.role,
  });

  /// JSON 맵(Map)에서 PostAuthor 객체를 생성하는 팩토리 생성자
  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    // 5.2 응답에서 role이 "" (빈 문자열)이거나 null일 경우 'user'로 처리
    String role = json['role'] as String? ?? 'user';
    if (role.isEmpty) {
      role = 'user';
    }

    return PostAuthor(
      // 5.2 응답에서 nickname이 null로 올 경우 기본값 처리
      nickname: json['nickname'] as String? ?? '알 수 없는 사용자',

      // 5.1은 'profileImage', 5.2는 'profile_image'일 수 있으므로 둘 다 확인
      // [수정] API 명세에 맞춰 snake_case('profile_image')를 우선 확인
      profileImage: (json['profile_image'] as String?) ?? (json['profileImage'] as String?),
      role: role,
    );
  }
}

/// API 명세 5.1/5.2의 'post' 객체 모델
class CommunityPost {
  // --- API 5.1/5.2 스펙 기반 필드 ---
  final String postId;
  final String title;
  final String content;
  final String category;
  final PostAuthor author;
  final List<String> images;
  final DateTime createdAt;

  // --- API 5.1 스펙 기반 필드 (5.2에는 없음) ---
  int viewCount;
  int likeCount;
  int dislikeCount;
  int commentCount;

  // --- 로컬 UI 상태 전용 필드 (API 명세에 없음) ---
  // (UI의 즉각적인 반응을 위해 사용)
  bool isLiked;
  bool isDisliked;

  CommunityPost({
    required this.postId,
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    required this.images,
    required this.createdAt,
    required this.viewCount,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    this.isLiked = false,
    this.isDisliked = false,
  });

  /// JSON 맵(Map)에서 CommunityPost 객체를 생성하는 팩토리 생성자
  /// (5.1 목록 조회, 5.2 작성 응답 모두 호환 가능)
  factory CommunityPost.fromJson(Map<String, dynamic> json) {

    return CommunityPost(
      // [수정] 5.1 'postId'(String) / 5.2 'ID'(int or String) -> .toString()으로 통일
      //postId: (json['postId'] ?? json['ID'] ?? json['id'] ?? json['post_id'] ?? 0).toString(),
      postId: (json['post_id'] ?? json['postId'] ?? json['id'] ?? 0).toString(),

      // [수정] 5.1 'title' / 5.2 'Title' - null 체크 강화
      title: (json['title'] as String?) ?? (json['Title'] as String?) ?? '',

      // [수정] 5.1 'content' / 5.2 'Content' - null 체크 강화
      content: (json['content'] as String?) ?? (json['Content'] as String?) ?? '',

      // [수정] 5.1 'category' / 5.2 'Category' - null 체크 강화
      category: (json['category'] as String?) ?? (json['Category'] as String?) ?? 'general',

      // [수정] 5.1 'author' / 5.2 'user'
      author: PostAuthor.fromJson(
          json['author'] as Map<String, dynamic>? ??
              json['user'] as Map<String, dynamic>? ??
              {}),

      // [수정] 5.2 'images'가 null일 경우 '?? []'로 빈 리스트 처리
      images: (json['images'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),

      // [수정] 명세 5.1: "created_at" (snake_case)
      createdAt: DateTime.parse(
          (json['created_at'] as String?) ?? (json['createdAt'] as String?) ?? DateTime.now().toIso8601String()
      ),

      // [수정] 명세 5.1: 카운트 필드 snake_case 적용 ("view_count" 등)
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      dislikeCount: json['dislike_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,

      // [수정] 명세 5.1: 로그인한 유저의 상호작용 상태 ("is_liked", "is_disliked")
      isLiked: json['is_liked'] as bool? ?? false,
      isDisliked: json['is_disliked'] as bool? ?? false,
    );
  }

  // --- 로컬 UI 상태 변경 메서드 ---

  void toggleLike() {
    if (isLiked) {
      likeCount -= 1;
      isLiked = false;
    } else {
      likeCount += 1;
      isLiked = true;
      if (isDisliked) {
        dislikeCount -= 1;
        isDisliked = false;
      }
    }
  }

  void toggleDislike() {
    if (isDisliked) {
      dislikeCount -= 1;
      isDisliked = false;
    } else {
      dislikeCount += 1;
      isDisliked = true;
      if (isLiked) {
        likeCount -= 1;
        isLiked = false;
      }
    }
  }
}

/// API 명세 6.1 댓글 객체 모델
class CommentItem {
  final int commentId;
  final String content;
  final DateTime createdAt;
  final PostAuthor author; // 기존에 정의된 PostAuthor 재사용

  CommentItem({
    required this.commentId,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      commentId: json['comment_id'] as int,
      content: json['content'] as String? ?? '', // null 방지
      createdAt: DateTime.parse(json['created_at'] as String),
      // API 응답의 'user' 객체를 PostAuthor.fromJson으로 넘겨서 처리
      author: PostAuthor.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}