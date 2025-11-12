class NewsItem {
  final int id;
  final String title;
  final String summary;
  final String image;
  final String category;
  final DateTime publishedAt;
  final String readTime;
  final int views;
  final int likes;
  final int comments;
  final String source;
  final String content;
  final String url;
  final bool isBookmarked;
  final bool isLiked;
  final bool isDisliked;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.image,
    required this.category,
    required this.publishedAt,
    required this.readTime,
    required this.views,
    required this.likes,
    required this.comments,
    required this.source,
    required this.content,
    required this.url,
    required this.isBookmarked,
    required this.isLiked,
    required this.isDisliked,
  });

  // JSON to NewsItem 변환 (Factory Constructor)
  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      summary: json['content'] ?? '',
      image: json['image_url'] ?? '',
      category: json['category'] ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      readTime: '${json['read_time_minutes'] ?? 3}분',
      views: json['view_count'] ?? 0,
      likes: json['like_count'] ?? 0,
      comments: json['comment_count'] ?? 0,
      source: json['source'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      isBookmarked: json['isBookmarked'] ?? false,
      isLiked: json['isLiked'] ?? false,
      isDisliked: json['isDisliked'] ?? false,
    );
  }

  // NewsItem to JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': summary,
      'image_url': image,
      'category': category,
      'published_at': publishedAt.toIso8601String(),
      'read_time_minutes': int.tryParse(readTime.replaceAll('분', '')) ?? 3,
      'view_count': views,
      'like_count': likes,
      'comment_count': comments,
      'source': source,
      'url': url,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isDisliked': isDisliked,
    };
  }
}
