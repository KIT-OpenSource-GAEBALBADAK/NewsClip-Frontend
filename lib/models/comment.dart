class Comment {
  final int commentId;
  final String content;
  final DateTime createdAt;
  final CommentUser user;

  Comment({
    required this.commentId,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

class CommentUser {
  final int id;
  final String nickname;
  final String? profileImage;
  final String role;

  CommentUser({
    required this.id,
    required this.nickname,
    this.profileImage,
    required this.role,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] as int,
      nickname: json['nickname'] as String,
      profileImage: json['profile_image'] as String?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'profile_image': profileImage,
      'role': role,
    };
  }
}

