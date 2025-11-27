class BookmarkResponse {
  final String status;
  final String message;
  final BookmarkData data;

  BookmarkResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BookmarkResponse.fromJson(Map<String, dynamic> json) {
    return BookmarkResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: BookmarkData.fromJson(json['data'] ?? {}),
    );
  }
}

class BookmarkData {
  final List<BookmarkedNewsItem> news;
  final int totalItems;
  final int totalPages;
  final int page;
  final int size;

  BookmarkData({
    required this.news,
    required this.totalItems,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  factory BookmarkData.fromJson(Map<String, dynamic> json) {
    return BookmarkData(
      news: (json['news'] as List<dynamic>?)
          ?.map((item) => BookmarkedNewsItem.fromJson(item))
          .toList() ??
          [],
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
    );
  }
}

class BookmarkedNewsItem {
  final String newsId;
  final String title;
  final String content;
  final String category;
  final String source;
  final String imageUrl;
  final DateTime publishedAt;
  final int viewCount;
  final int readTimeMinutes;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool isBookmarked;

  BookmarkedNewsItem({
    required this.newsId,
    required this.title,
    required this.content,
    required this.category,
    required this.source,
    required this.imageUrl,
    required this.publishedAt,
    required this.viewCount,
    required this.readTimeMinutes,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.isBookmarked,
  });

  factory BookmarkedNewsItem.fromJson(Map<String, dynamic> json) {
    return BookmarkedNewsItem(
      newsId: (json['id'] ?? json['news_id'] ?? json['newsId'] ?? '').toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      source: json['source'] ?? '',
      imageUrl: json['image_url'] ?? '',
      // 날짜 형식이 ISO 8601(2025-10-20T09:00:00Z)이므로 DateTime으로 파싱
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : DateTime.now(),
      viewCount: json['view_count'] ?? 0,
      readTimeMinutes: json['read_time_minutes'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      dislikeCount: json['dislike_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }
}