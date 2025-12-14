class NewsCard {
  final int shortId;
  final int originalNewsId;
  final String summary;
  final String imageUrl;
  final String title;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool isLiked;
  final bool isDisliked;

  const NewsCard({
    required this.shortId,
    required this.originalNewsId,
    required this.summary,
    required this.imageUrl,
    required this.title,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isDisliked,
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      shortId: json['shortId'] as int? ?? json['short_id'] as int? ?? 0,
      originalNewsId: json['originalNewsId'] as int? ?? json['original_news_id'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? json['like_count'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? json['dislike_count'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? json['comment_count'] as int? ?? 0,
      // 🔥 snake_case와 camelCase 둘 다 지원
      isLiked: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      isDisliked: json['is_disliked'] as bool? ?? json['isDisliked'] as bool? ?? false,
    );
  }
}
