// components/AppContext.tsx (NewsArticle interface) 변환
class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String author;
  final String publishedAt;
  final String category;
  final String imageUrl;
  final int readTime;
  final String? views;
  final String? likes;
  final String? comments;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedAt,
    required this.category,
    required this.imageUrl,
    required this.readTime,
    this.views,
    this.likes,
    this.comments,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      publishedAt: json['publishedAt'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      readTime: json['readTime'] as int,
      views: json['views'] as String?,
      likes: json['likes'] as String?,
      comments: json['comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'publishedAt': publishedAt,
      'category': category,
      'imageUrl': imageUrl,
      'readTime': readTime,
      'views': views,
      'likes': likes,
      'comments': comments,
    };
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    String? publishedAt,
    String? category,
    String? imageUrl,
    int? readTime,
    String? views,
    String? likes,
    String? comments,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      readTime: readTime ?? this.readTime,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}
