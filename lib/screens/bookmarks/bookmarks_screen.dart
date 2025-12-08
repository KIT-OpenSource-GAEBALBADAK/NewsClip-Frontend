import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/news_item.dart';
import '../../services/bookmark_service.dart';
import '../../models/bookmark.dart';
import '../news/news_reader_screen.dart';

enum SortBy { recent, oldest, category }

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<BookmarksScreen> createState() => _BookmarkedNewsScreenState();
}

class _BookmarkedNewsScreenState extends State<BookmarksScreen> {
  SortBy _sortBy = SortBy.recent;
  NewsItem? _selectedNews;

  List<NewsItem> _localBookmarkedList = [];
  bool _isLoading = true;
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final response = await _bookmarkService.getBookmarks(page: 1, size: 50);

      if (!mounted) return;

      final List<NewsItem> items = response.data.news.map((item) {

        // [수정 전]
        // int parsedId = int.tryParse(item.newsId) ?? 0;

        // [✅ 수정 후] 정규표현식으로 숫자 이외의 문자 제거 ('n_102' -> '102')
        String numericId = item.newsId.replaceAll(RegExp(r'[^0-9]'), '');
        int parsedId = int.tryParse(numericId) ?? 0;

        return NewsItem(
          id: parsedId,
          title: item.title,
          content: item.content,
          image: item.imageUrl,
          category: item.category,
          publishedAt: item.publishedAt,
          source: item.source,
          summary: item.content,
          readTime: '${item.readTimeMinutes}분',
          views: item.viewCount,
          likes: item.likeCount,
          comments: item.commentCount,
          url: '',
          // 🔥 서버에서 받은 실제 값 사용
          isBookmarked: item.isBookmarked,
          isLiked: item.isLiked,
          isDisliked: item.isDisliked,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _localBookmarkedList = items;
        });
      }

    } catch (e) {
      if (!mounted) return;
      print('북마크 로딩 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 목록을 불러오지 못했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<NewsItem> _getSortedNews(List<NewsItem> original) {
    final sortedList = List<NewsItem>.from(original);
    sortedList.sort((a, b) {
      switch (_sortBy) {
        case SortBy.recent:
          return b.publishedAt.compareTo(a.publishedAt);
        case SortBy.oldest:
          return a.publishedAt.compareTo(b.publishedAt);
        case SortBy.category:
          return a.category.compareTo(b.category);
      }
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bookmarkedList = _getSortedNews(_localBookmarkedList);

    if (_selectedNews != null) {
      final newsIdStr = _selectedNews!.id.toString();
      final isBookmarked = app.isBookmarked(newsIdStr);

      return _DetailView(
        news: _selectedNews!,
        isBookmarked: isBookmarked,
        onClose: () => setState(() => _selectedNews = null),
        onToggleBookmark: () async {
          final newsId = _selectedNews!.id;
          final newsIdString = newsId.toString();

          try {
            // [수정] toggleBookmark 사용
            final isNowBookmarked = await _bookmarkService.toggleBookmark(newsId);

            if (isNowBookmarked) {
              // 북마크 추가됨
              app.addBookmark(_selectedNews!);
            } else {
              // 북마크 해제됨 (삭제)
              app.removeBookmark(newsIdString);
              setState(() {
                _localBookmarkedList.removeWhere((item) => item.id == newsId);
              });
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('북마크 변경 실패')),
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(bookmarkedList.length),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadBookmarks,
        color: Colors.deepPurple,
        child: bookmarkedList.isNotEmpty
            ? ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: bookmarkedList.length,
          itemBuilder: (context, index) {
            return _NewsCard(
              news: bookmarkedList[index],
              // ✅ 수정: 뉴스 리더 화면(웹뷰)으로 이동
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsReaderScreen(newsId: bookmarkedList[index].id),
                  ),
                );
              },
              onRemove: () => _removeBookmark(context, app, bookmarkedList[index]),
            );
          },
        )
            : _EmptyView(onBack: widget.onBack),
      ),
    );
  }

  AppBar _buildAppBar(int count) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.bookmark, color: Colors.deepPurple),
          const SizedBox(width: 8),
          const Text('북마크', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('($count)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
      actions: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortBy>(
                value: _sortBy,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: SortBy.recent, child: Text('최신순')),
                  DropdownMenuItem(value: SortBy.oldest, child: Text('오래된순')),
                  DropdownMenuItem(value: SortBy.category, child: Text('카테고리')),
                ],
                onChanged: (v) => setState(() => _sortBy = v ?? SortBy.recent),
              ),
            ),
          ),
      ],
    );
  }

  // [수정] removeBookmark -> toggleBookmark 로직으로 변경
  Future<void> _removeBookmark(BuildContext context, AppProvider app, NewsItem news) async {
    try {
      // 1. 서버 토글 요청 (이미 북마크된 리스트이므로 토글 시 삭제됨)
      final isBookmarked = await _bookmarkService.toggleBookmark(news.id);

      // 2. 만약 false(해제됨)가 돌아오면 로컬에서도 삭제
      if (!isBookmarked) {
        app.removeBookmark(news.id.toString());
        setState(() {
          _localBookmarkedList.remove(news);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${news.title}"가 제거되었습니다'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 삭제 실패')),
      );
    }
  }
}

// ───────── 서브 위젯 (디자인 수정됨) ─────────

class _NewsCard extends StatelessWidget {
  final NewsItem news;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _NewsCard({required this.news, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // 카드 간 간격
        padding: const EdgeInsets.all(12), // 카드 내부 여백 (사진과 테두리 사이)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // 둥근 모서리
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.15), // 연한 보라색 테두리
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 이미지 (카드 안에 독립적으로 존재)
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // 이미지 자체의 둥근 모서리
              child: SizedBox(
                width: 90,
                height: 90,
                child: Image.network(
                  news.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12), // 이미지와 텍스트 사이 간격

            // 2. 텍스트 정보 영역
            Expanded(
              child: SizedBox(
                height: 90, // 이미지와 높이 맞춤
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상단: 카테고리 태그와 삭제 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CategoryTag(category: news.category),
                        InkWell(
                          onTap: onRemove,
                          child: Icon(Icons.delete_outline,
                              size: 20,
                              color: Colors.grey[600]
                          ),
                        ),
                      ],
                    ),

                    // 중간: 제목
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600, // 제목 굵게
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),

                    // 하단: 언론사와 시간
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          news.source,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        _MetaInfo(readTime: news.readTime, date: news.publishedAt),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String category;
  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // 알약 모양
        border: Border.all(color: Colors.grey.shade300), // 연한 회색 테두리
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final String readTime;
  final DateTime date;

  const _MetaInfo({required this.readTime, required this.date});

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${(diff.inDays / 7).floor()}주 전';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          readTime, // "3분"
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("•", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        Text(
          _formatDate(date),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

// 상세 화면과 빈 화면 위젯은 기존 로직 유지 (디자인 영향 없음)
class _DetailView extends StatelessWidget {
  final NewsItem news;
  final bool isBookmarked;
  final VoidCallback onClose;
  final VoidCallback onToggleBookmark;

  const _DetailView({
    required this.news,
    required this.isBookmarked,
    required this.onClose,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: onClose),
        title: const Text('뉴스 상세', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.black), onPressed: () {}),
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.deepPurple),
            onPressed: onToggleBookmark,
          ),
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  news.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      news.category,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(news.source, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      _MetaInfo(readTime: news.readTime, date: news.publishedAt),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...news.content.split('\n\n').where((p) => p.trim().isNotEmpty).map(
                        (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback? onBack;
  const _EmptyView({this.onBack});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: const Icon(Icons.bookmark_border, size: 32, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('아직 북마크한 뉴스가 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('관심있는 뉴스를 북마크해보세요!', style: TextStyle(fontSize: 13, color: Colors.grey)),

                    // [삭제됨] 뉴스 보러가기 버튼 제거
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}