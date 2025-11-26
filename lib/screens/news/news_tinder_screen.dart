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

  // 북마크 관련 변수 제거됨

  // 서버에서 받아올 실제 기사 리스트
  final List<NewsCard> articles = [];
  final NewsTinderService _tinder = NewsTinderService();

  // 로딩 상태 및 추가 데이터 존재 여부 플래그
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadShorts();
  }

  // 데이터를 추가로 로드하는 함수
  Future<void> _loadShorts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final map = await _tinder.getShorts(size: 10);
      final data = map['data'] as List<dynamic>?;

      if (data != null && data.isNotEmpty) {
        final list = data.map((e) => NewsCard.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          articles.addAll(list);
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      _toast(context, '쇼츠 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  // 다음 카드로 넘길 때 남은 개수 체크
  void _animateNext() {
    setState(() => currentIndex = min(currentIndex + 1, articles.length));

    if (articles.length - currentIndex <= 3 && _hasMore) {
      _loadShorts();
    }
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

  // 북마크, 댓글 관련 함수 제거됨

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)));
  }

  // 처음부터 다시 보기 로직
  void _restart() {
    setState(() {
      currentIndex = 0;
      liked.clear();
      disliked.clear();
      history.clear();
      articles.clear();
      _hasMore = true;
    });
    _loadShorts();
  }

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty && _isLoading) {
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
                    ? _doneCard(onRestart: _restart)
                    : _CardStack(
                  articles: articles,
                  index: currentIndex,
                  onLike: onLike,
                  onDislike: onDislike,
                  formatRelative: formatRelative,
                ),
              ),
            ),
          ),

          // 하단 액션 버튼 (완료 시 숨김)
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
          Text(
            _hasMore ? '새로운 뉴스를 불러오는 중입니다...' : '현재 준비된 뉴스가 모두 소진되었습니다.',
            style: const TextStyle(color: Colors.grey),
          ),
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

// ---------------------------------------------------------------------------
// 디자인 유지된 컴포넌트들 (북마크/댓글 UI 제거됨)
// ---------------------------------------------------------------------------

class _CardStack extends StatefulWidget {
  final List<NewsCard> articles;
  final int index;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final String Function(DateTime) formatRelative;

  const _CardStack({
    required this.articles,
    required this.index,
    required this.onLike,
    required this.onDislike,
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
  final String Function(DateTime)? formatRelative;

  const _NewsCard({
    required this.article,
    this.overlay,
    this.formatRelative,
  });

  @override
  Widget build(BuildContext context) {
    // 텍스트 전처리
    final String fullText = article.summary.replaceAll('\n', '  ');
    final String tag = '#미디어';

    final String title = fullText.length > 20
        ? fullText.substring(0, 20) + '...'
        : fullText;

    const double rowHeight = 32.0;
    const double fontSize = 14.0;
    const double lineHeight = rowHeight / fontSize;

    return Stack(
      children: [
        Container(
          width: 349,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTag(tag),
              const SizedBox(height: 24),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 28),
              _buildGradientLine(),
              const SizedBox(height: 32),

              // Wide Image + Text Layout Logic
              LayoutBuilder(
                builder: (context, constraints) {
                  final double fullWidth = constraints.maxWidth;
                  final double imageWidth = fullWidth * 0.5; // 50% 너비
                  const double gap = 16.0;
                  final double sideTextWidth = fullWidth - imageWidth - gap;

                  final int splitIndex = _calculateSplitIndex(
                      fullText,
                      TextStyle(fontSize: fontSize, height: lineHeight, fontFamily: 'Pretendard'),
                      sideTextWidth,
                      4
                  );

                  String topText = '';
                  String bottomText = '';

                  if (splitIndex >= fullText.length) {
                    topText = fullText;
                  } else {
                    topText = fullText.substring(0, splitIndex);
                    bottomText = fullText.substring(splitIndex).trim();
                  }

                  return Stack(
                    children: [
                      // Layer 1: Background Lines
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: imageWidth + gap),
                              Expanded(
                                child: Column(
                                  children: List.generate(4, (i) => _buildUnderline(rowHeight)),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: List.generate(5, (i) => _buildUnderline(rowHeight)),
                          ),
                        ],
                      ),

                      // Layer 2: Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  article.imageUrl,
                                  width: imageWidth,
                                  height: rowHeight * 4,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: imageWidth,
                                    height: rowHeight * 4,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              const SizedBox(width: gap),
                              Expanded(
                                child: Text(
                                  topText,
                                  style: const TextStyle(
                                    fontSize: fontSize,
                                    color: Color(0xFF6B6B84),
                                    height: lineHeight,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                          if (bottomText.isNotEmpty)
                            Text(
                              bottomText,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: fontSize,
                                color: Color(0xFF6B6B84),
                                height: lineHeight,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
              _buildGradientLine(),
            ],
          ),
        ),

        if (overlay != null) Positioned.fill(child: overlay!),
        // 북마크, 댓글 아이콘 Positioned 제거됨
      ],
    );
  }

  int _calculateSplitIndex(String text, TextStyle style, double maxWidth, int maxLines) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    textPainter.layout(maxWidth: maxWidth);

    if (!textPainter.didExceedMaxLines) {
      return text.length;
    }
    final pos = textPainter.getPositionForOffset(Offset(maxWidth, maxLines * style.fontSize! * style.height!));
    return pos.offset;
  }

  Widget _buildUnderline(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFECE6F0), width: 1.0),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
      ),
      child: Text(
        tag,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildGradientLine() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
      ),
    );
  }
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