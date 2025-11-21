import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/news_card.dart';
import '../../services/news_tinder_service.dart';

class NewsReaderScreen extends StatefulWidget {
  const NewsReaderScreen({Key? key}) : super(key: key);

  @override
  State<NewsReaderScreen> createState() => _NewsReaderScreenState();
}

class _NewsReaderScreenState extends State<NewsReaderScreen> {
  int currentIndex = 0;
  final Set<int> liked = {};
  final Set<int> disliked = {};
  final List<String> history = [];
  final Set<int> bookmarks = {};

  // 서버에서 받아올 실제 기사 리스트
  final List<NewsCard> articles = [];
  final NewsTinderService _tinder = NewsTinderService();

  @override
  void initState() {
    super.initState();
    _loadShorts();
  }

  Future<void> _loadShorts() async {
    try {
      final map = await _tinder.getShorts(size: 10);
      final data = map['data'] as List<dynamic>?;
      if (data != null) {
        final list = data.map((e) => NewsCard.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          articles.clear();
          articles.addAll(list);
          currentIndex = 0;
        });
      } else {
        _toast(context, '데이터가 비어있습니다');
      }
    } catch (e) {
      _toast(context, '쇼츠 로드 실패: $e');
    }
  }

  String formatRelative(DateTime dt) {
    final now = DateTime.now().toUtc();
    final d = now.difference(dt.toUtc());
    if (d.inMinutes < 1) return '방금 전';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    if (d.inDays < 7) return '${d.inDays}일 전';
    return '${dt.month}월 ${dt.day}일';
  }

  void onLike() {
    if (currentIndex >= articles.length) return;
    final id = articles[currentIndex].shortId;
    liked.add(id);
    history.add('like:$id');
    _animateNext();
  }

  void onDislike() {
    if (currentIndex >= articles.length) return;
    final id = articles[currentIndex].shortId;
    disliked.add(id);
    history.add('dislike:$id');
    _animateNext();
  }

  void _animateNext() {
    setState(() => currentIndex = min(currentIndex + 1, articles.length));
  }

  void onUndo() {
    if (currentIndex == 0 || history.isEmpty) return;
    final last = history.removeLast();
    final parts = last.split(':');
    if (parts.length == 2) {
      final action = parts[0];
      final id = int.tryParse(parts[1]);
      if (id != null) {
        if (action == 'like') liked.remove(id);
        if (action == 'dislike') disliked.remove(id);
      }
    }
    setState(() => currentIndex = max(0, currentIndex - 1));
  }

  void onShare(NewsCard a) {
    Share.share('${a.summary}\n\n${a.summary.split('\n').first}\n\n링크: ${a.imageUrl}');
  }

  void onToggleBookmark(NewsCard a) {
    setState(() {
      if (bookmarks.contains(a.shortId)) {
        bookmarks.remove(a.shortId);
        _toast(context, '북마크 해제');
      } else {
        bookmarks.add(a.shortId);
        _toast(context, '북마크 추가');
      }
    });
  }

  void onOpenComments(NewsCard a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => ListView.builder(
          controller: controller,
          padding: const EdgeInsets.all(16),
          itemCount: 20,
          itemBuilder: (_, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text('댓글 ${i + 1}'),
            subtitle: Text('이 쇼츠는 정말 흥미롭네요! (${a.summary})'),
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)));
  }

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F5FE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final done = currentIndex >= articles.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FE),
      body: Stack(
        children: [
          // 카드 스택
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 360,
                height: 360 * 16 / 9,
                child: done
                    ? _doneCard(onRestart: () {
                  setState(() {
                    currentIndex = 0;
                    liked.clear();
                    disliked.clear();
                    history.clear();
                  });
                })
                    : _CardStack(
                  articles: articles,
                  index: currentIndex,
                  onLike: onLike,
                  onDislike: onDislike,
                  onBookmark: onToggleBookmark,
                  isBookmarked: (id) => bookmarks.contains(id),
                  onOpenComments: onOpenComments,
                  formatRelative: formatRelative,
                ),
              ),
            ),
          ),

          // 하단 액션 버튼
          if (!done)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: _ActionBar(
                onDislike: onDislike,
                onUndo: onUndo,
                onShare: () => onShare(articles[currentIndex]),
                onLike: onLike,
              ),
            ),
        ],
      ),
    );
  }

  Widget _doneCard({required VoidCallback onRestart}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('모든 뉴스를 확인했어요!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('새로운 뉴스가 곧 업데이트됩니다', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: onRestart,
              child: const Text('처음부터 다시 보기'),
            ),
          )
        ],
      ),
    );
  }
}


class _CardStack extends StatefulWidget {
  final List<NewsCard> articles;
  final int index;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final void Function(NewsCard) onBookmark;
  final bool Function(int id) isBookmarked;
  final void Function(NewsCard) onOpenComments;
  final String Function(DateTime) formatRelative;

  const _CardStack({
    required this.articles,
    required this.index,
    required this.onLike,
    required this.onDislike,
    required this.onBookmark,
    required this.isBookmarked,
    required this.onOpenComments,
    required this.formatRelative,
  });

  @override
  State<_CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<_CardStack> with SingleTickerProviderStateMixin {
  double dragX = 0;

  @override
  Widget build(BuildContext context) {
    final top = widget.articles[widget.index];
    final next = widget.index + 1 < widget.articles.length
        ? widget.articles[widget.index + 1]
        : null;
    final third = widget.index + 2 < widget.articles.length
        ? widget.articles[widget.index + 2]
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (third != null) _buildCard(third, depth: 2),
        if (next != null) _buildCard(next, depth: 1),
        _buildDraggableCard(top),
      ],
    );
  }

  Widget _buildCard(NewsCard a, {required int depth}) {
    final scale = 1 - depth * 0.05;
    final y = depth * 10.0;
    final op = depth == 1 ? 0.85 : 0.7;

    return Transform.translate(
      offset: Offset(0, y),
      child: Transform.scale(
        scale: scale,
        child: Opacity(opacity: op, child: _NewsCard(article: a, overlay: null)),
      ),
    );
  }

  Widget _buildDraggableCard(NewsCard a) {
    const threshold = 120.0;
    final like = dragX > threshold;
    final dislike = dragX < -threshold;

    return GestureDetector(
      onPanUpdate: (d) => setState(() => dragX += d.delta.dx),
      onPanEnd: (_) {
        if (dragX > threshold) {
          widget.onLike();
        } else if (dragX < -threshold) {
          widget.onDislike();
        }
        setState(() => dragX = 0);
      },
      child: Transform.translate(
        offset: Offset(dragX, 0),
        child: Transform.rotate(
          angle: dragX / 600,
          child: _NewsCard(
            article: a,
            overlay: like
                ? _SwipeOverlay.like()
                : (dislike ? _SwipeOverlay.dislike() : null),
            onBookmark: () => widget.onBookmark(a),
            isBookmarked: widget.isBookmarked(a.shortId),
            onOpenComments: () => widget.onOpenComments(a),
            formatRelative: widget.formatRelative,
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsCard article;
  final Widget? overlay;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final VoidCallback? onOpenComments;
  final String Function(DateTime)? formatRelative;

  const _NewsCard({
    required this.article,
    this.overlay,
    this.onBookmark,
    this.isBookmarked = false,
    this.onOpenComments,
    this.formatRelative,
  });

  @override
  Widget build(BuildContext context) {
    final readTime = max(1, (article.summary.length / 100).ceil());
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // 배경 이미지
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Image.network(
              article.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFF3F4F6)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.2),
                    Colors.transparent,
                    Colors.black.withOpacity(.82),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip('#쇼츠'),
                _pill('${article.likeCount} 좋아요'),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        article.originalNewsId.toString().padLeft(2, '0'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text('@${article.originalNewsId}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 6),
                    Text(
                      formatRelative?.call(DateTime.now()) ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    if (onBookmark != null)
                      IconButton(
                        onPressed: onBookmark,
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  article.summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _stat(Icons.favorite_border, article.likeCount.toString()),
                    const SizedBox(width: 14),
                    const SizedBox(width: 14),
                    _stat(Icons.schedule, '$readTime분'),
                  ],
                ),
              ],
            ),
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 12)),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(.4),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 12)),
  );

  Widget _stat(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.white70),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

class _SwipeOverlay extends StatelessWidget {
  final bool isLike;
  const _SwipeOverlay._(this.isLike);
  factory _SwipeOverlay.like() => const _SwipeOverlay._(true);
  factory _SwipeOverlay.dislike() => const _SwipeOverlay._(false);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLike
                ? [Colors.red.withOpacity(.3), Colors.transparent]
                : [Colors.blue.withOpacity(.3), Colors.transparent],
            begin: isLike ? Alignment.centerLeft : Alignment.centerRight,
            end: isLike ? Alignment.centerRight : Alignment.centerLeft,
          ),
        ),
        child: Align(
          alignment: isLike ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isLike ? Colors.red : Colors.blue,
                  width: 8,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLike ? Icons.thumb_up : Icons.thumb_down,
                size: 48,
                color: isLike ? Colors.red : Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onUndo;
  final VoidCallback onShare;
  final VoidCallback onLike;

  const _ActionBar({
    required this.onDislike,
    required this.onUndo,
    required this.onShare,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(icon: Icons.thumb_down, onTap: onDislike, color: Colors.blue),
        const SizedBox(width: 12),
        _circleBtnSmall(icon: Icons.rotate_left, onTap: onUndo),
        const SizedBox(width: 12),
        _circleBtnSmall(icon: Icons.share, onTap: onShare),
        const SizedBox(width: 12),
        _circleBtn(icon: Icons.thumb_up, onTap: onLike, color: Colors.red),
      ],
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 8)),
            ]),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _circleBtnSmall({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 8)),
            ]),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.grey[700], size: 22),
      ),
    );
  }
}

// 작은 바운싱 버튼은 추후 필요하면 분리할 수 있습니다.
