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
      // 🔥 snake_case와 camelCase 둘 다 지원 (API 응답 형식에 유연하게 대응)
      isBookmarked: json['is_bookmarked'] as bool? ?? json['isBookmarked'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      isDisliked: json['is_disliked'] as bool? ?? json['isDisliked'] as bool? ?? false,
    );
  }

  NewsItem copyWith({
    int? id,
    String? title,
    String? summary,
    String? image,
    String? category,
    DateTime? publishedAt,
    String? readTime,
    int? views,
    int? likes,
    int? comments,
    String? source,
    String? content,
    String? url,
    bool? isBookmarked,
    bool? isLiked,
    bool? isDisliked,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      image: image ?? this.image,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      readTime: readTime ?? this.readTime,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      source: source ?? this.source,
      content: content ?? this.content,
      url: url ?? this.url,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
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
