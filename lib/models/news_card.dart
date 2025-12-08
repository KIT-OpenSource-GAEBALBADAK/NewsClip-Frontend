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
      shortId: json['shortId'] as int,
      originalNewsId: json['originalNewsId'] as int,
      summary: json['summary'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      likeCount: json['likeCount'] as int,
      dislikeCount: json['dislikeCount'] as int,
      commentCount: json['commentCount'] as int,
      isLiked: json['isLiked'] as bool,
      isDisliked: json['isDisliked'] as bool,
    );
  }
}
