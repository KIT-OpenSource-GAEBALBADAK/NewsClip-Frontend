import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});
  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final List<NewsItem> _allNews = seedNews();
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _liked = <String>{};
  String _activeCategory = '전체';
  bool _commentsOpen = false;
  NewsItem? _commentsTarget;

  // 다양한 카테고리 구성 (초기 파일 레퍼런스 스타일)
  final List<String> _categories = const [
    '정치', '경제', '사회', '문화', 'IT/과학', '스포츠', '건강', '세계','라이프스타일', '엔터테인먼트',
  ];

  List<NewsItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allNews.where((n) {
      final catOk = _activeCategory == '전체' || n.category == _activeCategory;
      final qOk = q.isEmpty
          ? true
          : n.title.toLowerCase().contains(q) ||
          n.summary.toLowerCase().contains(q) ||
          n.source.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(),
        _SearchBar(ctrl: _searchCtrl, onChanged: (_) => setState(() {})),
        _CategoryRow(
          categories: _categories,
          active: _activeCategory,
          onSelect: (v) => setState(() => _activeCategory = v),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (_, i) => NewsCard(
              item: _filtered[i],
              liked: _liked.contains(_filtered[i].id),
              onToggleLike: () => setState(() {
                final id = _filtered[i].id;
                _liked.contains(id) ? _liked.remove(id) : _liked.add(id);
              }),
              onOpenComments: () => setState(() {
                _commentsTarget = _filtered[i];
                _commentsOpen = true;
              }),
              onShare: () async {
                final n = _filtered[i];
                final text = '${n.title}\n${n.summary}';
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사 완료')));
                }
              },
            ),
          ),
        ),
        if (_commentsTarget != null)
          CommentsModal(
            isOpen: _commentsOpen,
            onClose: () => setState(() {
              _commentsOpen = false;
              _commentsTarget = null;
            }),
            articleId: _commentsTarget!.id,
            articleTitle: _commentsTarget!.title,
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('안녕하세요 👋', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('오늘의 뉴스를 확인해보세요', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 20)),
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
          fillColor: Colors.grey.withOpacity(0.15),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.active, required this.onSelect});
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
            const Text('카테고리', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(onPressed: () => onSelect('초기화'), child: const Text('초기화', style: TextStyle(color: Colors.grey))),
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
              label: Text(cat, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black)),
              selected: selected,
              onSelected: (_) => onSelect(cat),
              showCheckmark: false,
              backgroundColor: Colors.grey.withOpacity(0.1),
              selectedColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
  const NewsCard({super.key, required this.item, required this.liked, required this.onToggleLike, required this.onOpenComments, required this.onShare});
  final NewsItem item;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageWithFallback(url: item.image, width: 84, height: 84),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  BadgeChip(item.category),
                  const SizedBox(width: 6),
                  Flexible(child: Text(item.source, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 6),
                  Text(relativeDate(item.publishedAt), style: const TextStyle(color: Colors.grey)),
                ]),
                const SizedBox(height: 6),
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: const [
            Icon(Icons.remove_red_eye_outlined, size: 14),
            SizedBox(width: 4),
            // views next to icon
          ]),
          Row(children: [
            Text('${item.views}'),
            const SizedBox(width: 12),
            const Icon(Icons.schedule, size: 14),
            const SizedBox(width: 4),
            Text(item.readTime),
          ]),
          Row(children: [
            IconButton(onPressed: onToggleLike, icon: Icon(liked ? Icons.favorite : Icons.favorite_border), color: liked ? Colors.red : Colors.black54),
            Text('${item.likes}'),
            IconButton(onPressed: onOpenComments, icon: const Icon(Icons.mode_comment_outlined)),
            Text('${item.comments}'),
            const Spacer(),
            IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded)),
          ])
        ]),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Comments modal
// ──────────────────────────────────────────────────────────────────────────────
class CommentsModal extends StatelessWidget {
  const CommentsModal({super.key, required this.isOpen, required this.onClose, required this.articleId, required this.articleTitle});
  final bool isOpen;
  final VoidCallback onClose;
  final String articleId;
  final String articleTitle;
  @override
  Widget build(BuildContext context) => Container(
    height: 340,
    color: Theme.of(context).colorScheme.surface,
    child: Column(children: [
      ListTile(
        title: const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(articleTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView(children: const [
          ListTile(title: Text('뉴스리뷰'), subtitle: Text('좋은 기사네요 👍')),
          ListTile(title: Text('미디어전문가'), subtitle: Text('공감합니다.')),
          ListTile(title: Text('Z대표'), subtitle: Text('필요한 콘텐츠입니다.')),
        ]),
      )
    ]),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class ImageWithFallback extends StatelessWidget {
  const ImageWithFallback({super.key, required this.url, this.width, this.height});
  final String url; final double? width; final double? height;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Data & helpers
// ──────────────────────────────────────────────────────────────────────────────
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
}

List<NewsItem> seedNews() => [
  NewsItem(
    id: '1',
    title: '청년층 주거 정책, 새로운 변화의 바람',
    summary: '정부가 발표한 청년 주거 지원 정책이 젊은 세대에게 어떤 영향을 미칠지 전문가들이 분석했습니다.',
    image: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=250&fit=crop',
    category: '정치',
    publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    readTime: '3분',
    views: 1240,
    likes: 89,
    comments: 23,
    source: '한국일보',
    content: '',
  ),
  NewsItem(
    id: '2',
    title: 'MZ세대가 선택하는 새로운 투자 트렌드',
    summary: '암호화폐부터 ESG 투자까지, 젊은 투자자들의 포트폴리오를 살펴봅니다.',
    image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=250&fit=crop',
    category: '경제',
    publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
    readTime: '5분',
    views: 2103,
    likes: 156,
    comments: 41,
    source: '경제신문',
    content: '',
  ),
];

String relativeDate(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
