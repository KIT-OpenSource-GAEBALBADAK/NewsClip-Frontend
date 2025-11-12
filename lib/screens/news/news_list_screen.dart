import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/news_item.dart';
import '../../services/news_list_service.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({Key? key}) : super(key: key);

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _newsService = NewsListService();

  // State
  List<NewsItem> _allNews = [];
  List<NewsItem> _filtered = [];
  final Set<String> _liked = {};
  final List<String> _categories = [
    "전체",
    "정치",
    "경제",
    "문화",
    "환경",
    "기술",
    "스포츠",
    "라이프스타일",
    "건강",
    "교육",
    "음식",
    "여행",
    "패션"
  ];
  String _activeCategory = '전체';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  bool _canLoadMore = true;

  @override
  void initState() {
    super.initState();
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
      final newsItems =
          newsData.map((json) => NewsItem.fromJson(json)).toList();

      setState(() {
        _canLoadMore = newsItems.isNotEmpty;
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
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allNews
          .where((news) => news.title.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        _SearchBar(ctrl: _searchCtrl, onChanged: (_) => _applyFilter()),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('뉴스를 불러올 수 없습니다'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadNews(isRefresh: true),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadNews(isRefresh: true),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        itemCount: _filtered.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _filtered.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          return NewsCard(
                            item: _filtered[i],
                            liked: _liked.contains(_filtered[i].id),
                            onToggleLike: () => setState(() {
                              final id = _filtered[i].id;
                              _liked.contains(id)
                                  ? _liked.remove(id)
                                  : _liked.add(id);
                            }),
                            onShare: () async {
                              final n = _filtered[i];
                              final text = '${n.title}\n${n.summary}';
                              await Clipboard.setData(
                                  ClipboardData(text: text));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('복사 완료')));
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 45, 12, 4),
        child: Row(
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('안녕하세요 👋', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('오늘의 뉴스를 확인해보세요',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                    onPressed: () {},
                    icon:
                        const Icon(Icons.notifications_none_rounded, size: 20)),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Text('3',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
      );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ctrl, required this.onChanged});

  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SizedBox(
          height: 38,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '뉴스 검색...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: Colors.grey.withAlpha(38),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
      );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(
      {required this.categories, required this.active, required this.onSelect});

  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('카테고리',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat == active;
                return ChoiceChip(
                  label: Text(cat,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black)),
                  selected: selected,
                  onSelected: (_) => onSelect(cat),
                  showCheckmark: false,
                  backgroundColor: Colors.grey.withAlpha(25),
                  selectedColor: Theme.of(context).primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                );
              },
            ),
          )
        ],
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// News card
// ──────────────────────────────────────────────────────────────────────────────
class NewsCard extends StatelessWidget {
  const NewsCard(
      {super.key,
      required this.item,
      required this.liked,
      required this.onToggleLike,
      required this.onShare});

  final NewsItem item;
  final bool liked;
  final VoidCallback onToggleLike;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).dividerColor.withAlpha(51)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.image,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                      width: 84,
                      height: 84,
                      child:
                          Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          BadgeChip(item.category),
                          const SizedBox(width: 6),
                          Flexible(
                              child: Text(item.source,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey))),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 6),
                          Text(
                              item.publishedAt
                                  .toIso8601String()
                                  .substring(0, 10),
                              style: const TextStyle(color: Colors.grey)),
                        ]),
                        const SizedBox(height: 6),
                        Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(item.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey)),
                      ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.remove_red_eye_outlined, size: 14),
                const SizedBox(width: 4),
                Text('${item.views}'),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 14),
                const SizedBox(width: 4),
                Text(item.readTime),
              ]),
              Row(children: [
                IconButton(
                    onPressed: onToggleLike,
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                    color: liked ? Colors.red : Colors.black54),
                Text('${item.likes}'),
                const Spacer(),
                IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded)),
              ])
            ]),
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// Small bits
// ──────────────────────────────────────────────────────────────────────────────
class BadgeChip extends StatelessWidget {
  const BadgeChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
      );
}
