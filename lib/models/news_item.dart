class NewsItem {
  final String id;
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
  });

  // JSON to NewsItem 변환 (Factory Constructor)
  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['newsId'] ?? '',
      title: json['title'] ?? '',
      summary: json['content'] ?? '',
      image: json['image_url'] ?? '',
      category: json['category'] ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      readTime: '${json['readTimeMinutes'] ?? 3}분',
      views: json['viewCount'] ?? 0,
      likes: json['likeCount'] ?? 0,
      comments: json['commentCount'] ?? 0,
      source: json['source'] ?? '',
      content: json['content'] ?? '',
    );
  }

  // NewsItem to JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'newsId': id,
      'title': title,
      'content': summary,
      'imageUrl': image,
      'category': category,
      'publishedAt': publishedAt.toIso8601String(),
      'readTimeMinutes': int.tryParse(readTime.replaceAll('분', '')) ?? 3,
      'viewCount': views,
      'likeCount': likes,
      'commentCount': comments,
      'source': source,
    };
  }
}

