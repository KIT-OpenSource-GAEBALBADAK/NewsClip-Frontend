import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/news_item.dart';
import '../../services/news_list_service.dart';
import 'news_reader_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  // 🔹 기존 로직 유지
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final NewsListService _newsService = NewsListService();

  List<NewsItem> _allNews = [];
  List<NewsItem> _filtered = [];

  // ID 기반 상태 관리
  final Set<int> _liked = {};
  final Set<int> _disliked = {};
  final Set<int> _bookmarked = {};
  final Map<int, int> _dislikeCounts = {};

  final List<String> _categories = const [
    "정치", "경제", "문화", "환경", "기술",
    "스포츠", "라이프스타일", "건강", "교육", "음식", "여행", "패션"
  ];
  late String _activeCategory;

  bool _commentsOpen = false;
  NewsItem? _commentsTarget;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  bool _canLoadMore = true;

  @override
  void initState() {
    super.initState();
    _activeCategory = _categories.first;
    _loadNews(isRefresh: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent * 0.95 &&
          !_isLoadingMore &&
          _canLoadMore) {
        _loadNews();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _allNews.clear();
        _filtered.clear();
        _hasError = false;
        _canLoadMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _newsService.getNewsList(
        category: _activeCategory,
        page: _currentPage,
      );

      final List<dynamic> newsData = response['data']['news'];
      final newsItems = newsData.map((json) => NewsItem.fromJson(json)).toList();

      setState(() {
        _canLoadMore = newsItems.isNotEmpty;
        for (var item in newsItems) {
          if (item.isLiked) _liked.add(item.id);
          if (item.isDisliked) _disliked.add(item.id);
          if (item.isBookmarked) _bookmarked.add(item.id);
        }
        if (isRefresh) {
          _allNews = newsItems;
        } else {
          _allNews.addAll(newsItems);
        }
        _applyFilter();
        _currentPage++;
      });
    } catch (e) {
      setState(() => _hasError = true);
      debugPrint('Error loading news: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allNews.where((n) {
        return q.isEmpty
            ? true
            : n.title.toLowerCase().contains(q) ||
            n.summary.toLowerCase().contains(q) ||
            n.source.toLowerCase().contains(q);
      }).toList();
    });
  }

  int _getDislikeCount(int id) => _dislikeCounts[id] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _Header(),

            // 🔹 검색창 영역 (위아래 경계선 추가)
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)), // 위쪽 경계선
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 적절한 여백
                  child: _SearchBar(ctrl: _searchCtrl, onChanged: (_) => _applyFilter()),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)), // 아래쪽 경계선
              ],
            ),

            _CategoryRow(
              categories: _categories,
              active: _activeCategory,
              onSelect: (v) {
                setState(() => _activeCategory = v);
                _loadNews(isRefresh: true);
              },
            ),

            Expanded(
              child: _isLoading && _allNews.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError && _allNews.isEmpty
                  ? Center(child: ElevatedButton(onPressed: () => _loadNews(isRefresh: true), child: const Text('다시 시도')))
                  : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _loadNews(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(top: 4, bottom: 80, left: 16, right: 16),
                      itemCount: _filtered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _filtered.length) {
                          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                        }
                        final item = _filtered[i];
                        return NewsCard(
                          item: item,
                          liked: _liked.contains(item.id),
                          disliked: _disliked.contains(item.id),
                          bookmarked: _bookmarked.contains(item.id),
                          likeCount: item.likes +
                              (_liked.contains(item.id) && !item.isLiked ? 1 :
                              (_liked.contains(item.id) == false && item.isLiked ? -1 : 0)),
                          dislikeCount: _getDislikeCount(item.id),
                          commentCount: item.comments,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => NewsReaderScreen(newsId: item.id)));
                          },
                          onToggleLike: () async {
                            try {
                              final result = await _newsService.interactWithNews(item.id, 'like');
                              setState(() {
                                final index = _allNews.indexWhere((n) => n.id == item.id);
                                if (index != -1) {
                                  _allNews[index] = _allNews[index].copyWith(
                                    isLiked: result['isLiked'],
                                    isDisliked: result['isDisliked'],
                                    likes: result['likeCount'],
                                  );
                                  _dislikeCounts[item.id] = result['dislikeCount'];

                                  if (_allNews[index].isLiked) {
                                    _liked.add(item.id);
                                  } else {
                                    _liked.remove(item.id);
                                  }
                                  if (_allNews[index].isDisliked) {
                                    _disliked.add(item.id);
                                  } else {
                                    _disliked.remove(item.id);
                                  }
                                  _applyFilter();
                                }
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('좋아요 처리에 실패했습니다: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onToggleDislike: () async {
                            try {
                              final result = await _newsService.interactWithNews(item.id, 'dislike');
                              setState(() {
                                final index = _allNews.indexWhere((n) => n.id == item.id);
                                if (index != -1) {
                                  _allNews[index] = _allNews[index].copyWith(
                                    isLiked: result['isLiked'],
                                    isDisliked: result['isDisliked'],
                                    likes: result['likeCount'],
                                  );
                                  _dislikeCounts[item.id] = result['dislikeCount'];

                                  if (_allNews[index].isLiked) {
                                    _liked.add(item.id);
                                  } else {
                                    _liked.remove(item.id);
                                  }
                                  if (_allNews[index].isDisliked) {
                                    _disliked.add(item.id);
                                  } else {
                                    _disliked.remove(item.id);
                                  }
                                  _applyFilter();
                                }
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('싫어요 처리에 실패했습니다: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onToggleBookmark: () async {
                            try {
                              final isBookmarked = await _newsService.toggleBookmark(item.id);
                              setState(() {
                                if (isBookmarked) {
                                  _bookmarked.add(item.id);
                                } else {
                                  _bookmarked.remove(item.id);
                                }
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBookmarked ? '북마크에 추가되었습니다.' : '북마크에서 제거되었습니다.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('북마크 처리에 실패했습니다: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onOpenComments: () {
                            setState(() {
                              _commentsTarget = item;
                              _commentsOpen = true;
                            });
                          },
                          onShare: () async {
                            final text = '${item.title}\n${item.summary}';
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사 완료')));
                            }
                          },
                        );
                      },
                    ),
                  ),
                  if (_commentsTarget != null)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: CommentsModal(
                        isOpen: _commentsOpen,
                        onClose: () => setState(() { _commentsOpen = false; _commentsTarget = null; }),
                        articleId: _commentsTarget!.id,
                        articleTitle: _commentsTarget!.title,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('안녕하세요 👋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 2),
              Text('오늘의 뉴스를 확인해보세요', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 28, color: Colors.black54),
              Positioned(
                right: 2, top: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_horiz, size: 28, color: Colors.black54),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ctrl, required this.onChanged});
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44, // 높이 조정
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA), // 아주 연한 회색 배경
        borderRadius: BorderRadius.circular(8), // 둥글기 조정
      ),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: const InputDecoration(
          hintText: '뉴스 검색...',
          hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Color(0xFF999999), size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10), // 내부 여백 조정
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.active, required this.onSelect});
  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == active;
              return GestureDetector(
                onTap: () => onSelect(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.liked,
    required this.disliked,
    required this.bookmarked,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.onTap,
    required this.onToggleLike,
    required this.onToggleDislike,
    required this.onToggleBookmark,
    required this.onOpenComments,
    required this.onShare,
  });

  final NewsItem item;
  final bool liked;
  final bool disliked;
  final bool bookmarked;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleDislike;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenComments;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: ImageWithFallback(url: item.image, width: 90, height: 90)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.summary, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.5))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _CategoryBadge(item.category),
                  const SizedBox(width: 8),
                  Text(item.source, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  _dot(),
                  Text(_formatDate(item.publishedAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  _dot(),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(item.readTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${item.views}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionChipButton(
                    isActive: liked,
                    activeColor: const Color(0xFFFFEBEE),
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    iconColor: liked ? Colors.red : Colors.grey,
                    label: '$likeCount',
                    onTap: onToggleLike,
                  ),
                  const SizedBox(width: 12),
                  _ActionChipButton(
                    isActive: disliked,
                    activeColor: const Color(0xFFE3F2FD),
                    icon: disliked ? Icons.favorite : Icons.favorite_border,
                    iconColor: disliked ? Colors.blue : Colors.grey,
                    label: '$dislikeCount',
                    onTap: onToggleDislike,
                    isInverted: true,
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onOpenComments,
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$commentCount', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: onShare, padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.ios_share, size: 20, color: Colors.grey)),
                  const SizedBox(width: 16),
                  IconButton(onPressed: onToggleBookmark, padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border, size: 20, color: bookmarked ? Colors.black87 : Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _dot() => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('•', style: TextStyle(color: Colors.grey)));
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isInverted = false,
  });

  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 20, color: iconColor);
    if (isInverted) {
      iconWidget = Transform.rotate(angle: math.pi, child: iconWidget);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: isActive ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
        decoration: BoxDecoration(color: isActive ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: isActive ? iconColor : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class CommentsModal extends StatelessWidget {
  const CommentsModal({super.key, required this.isOpen, required this.onClose, required this.articleId, required this.articleTitle});
  final bool isOpen;
  final VoidCallback onClose;
  final int articleId;
  final String articleTitle;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(articleTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                ListTile(leading: CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(Icons.person, size: 16, color: Colors.white)), title: Text('뉴스리뷰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), subtitle: Text('좋은 기사네요 👍', style: TextStyle(fontSize: 13)), dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
    );
  }
}

class ImageWithFallback extends StatelessWidget {
  const ImageWithFallback({super.key, required this.url, this.width, this.height});
  final String url;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return Image.network(url, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: width, height: height, color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)));
  }
}

String _formatDate(DateTime dt) { return '${dt.month}월 ${dt.day}일'; }
