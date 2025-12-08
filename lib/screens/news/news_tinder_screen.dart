import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/news_card.dart';
import '../../models/comment.dart';
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
      final int? cursorId = articles.isNotEmpty ? articles.last.shortId : null;
      final map = await _tinder.getShorts(
        size: 10,
        cursorId: cursorId,
      );
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

  void onLike() async {
    if (currentIndex >= articles.length) return;
    final id = articles[currentIndex].shortId;

    try {
      await _tinder.interactWithShort(id, 'like');
    } catch (e) {
      _toast(context, '좋아요 처리 실패: $e');
      return;
    }

    liked.add(id);
    history.add('like:$id');
    _animateNext();
  }

  void onDislike() async {
    if (currentIndex >= articles.length) return;
    final id = articles[currentIndex].shortId;

    try {
      await _tinder.interactWithShort(id, 'dislike');
    } catch (e) {
      _toast(context, '싫어요 처리 실패: $e');
      return;
    }

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

  // 댓글 팝업 열기
  void onOpenComments(NewsCard a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(article: a),
    );
  }

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
                  onOpenComments: onOpenComments,
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
  final void Function(NewsCard) onOpenComments;
  final String Function(DateTime) formatRelative;

  const _CardStack({
    required this.articles,
    required this.index,
    required this.onLike,
    required this.onDislike,
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

    return Transform.translate(
      offset: Offset(0, y),
      child: Transform.scale(
        scale: scale,
        child: _NewsCard(article: a, overlay: null),
      ),
    );
  }

  Widget _buildDraggableCard(NewsCard a) {
    const threshold = 120.0;
    final like = dragX > threshold;
    final dislike = dragX < -threshold;

    return GestureDetector(
      onPanUpdate: (d) => setState(() => dragX += d.delta.dx),
      onPanEnd: (_) async {
        final shouldLike = dragX > threshold;
        final shouldDislike = dragX < -threshold;

        if (shouldLike || shouldDislike) {
          // 먼저 dragX를 0으로 설정 (화면 갱신은 아직 안함)
          dragX = 0;

          // 액션 실행
          if (shouldLike) {
            widget.onLike();
          } else {
            widget.onDislike();
          }

          // 짧은 딜레이 후 화면 갱신
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) {
            setState(() {});
          }
        } else {
          // 스와이프가 threshold에 도달하지 않은 경우 원래 위치로
          setState(() => dragX = 0);
        }
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
  final VoidCallback? onOpenComments;
  final String Function(DateTime)? formatRelative;

  const _NewsCard({
    required this.article,
    this.overlay,
    this.onOpenComments,
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
              const SizedBox(height: 16),

              // Center Image + Text Below Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final double fullWidth = constraints.maxWidth;
                  final double imageWidth = fullWidth * 0.85; // 85% 너비로 확대

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 중앙 정렬된 이미지 (밑줄 없이)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            article.imageUrl,
                            width: imageWidth,
                            height: rowHeight * 5,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: imageWidth,
                              height: rowHeight * 5,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),

                      // 텍스트 영역 (밑줄과 함께)
                      Stack(
                        children: [
                          // 텍스트 영역의 밑줄만 표시 (4줄)
                          Column(
                            children: List.generate(4, (i) => _buildUnderline(rowHeight)),
                          ),
                          // 텍스트
                          Text(
                            fullText,
                            maxLines: 4,
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

        // 우측 하단 댓글 아이콘
        if (onOpenComments != null)
          Positioned(
            right: 24,
            bottom: 24,
            child: GestureDetector(
              onTap: onOpenComments,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.comment_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
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

// 댓글 팝업 시트
class _CommentsSheet extends StatefulWidget {
  final NewsCard article;

  const _CommentsSheet({required this.article});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final NewsTinderService _tinder = NewsTinderService();

  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _tinder.getShortComments(widget.article.shortId);
      final data = response['data'] as List<dynamic>?;

      if (data != null) {
        setState(() {
          _comments = data.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '댓글을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}월 ${dt.day}일';
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();

    // 입력창 먼저 클리어
    _commentController.clear();

    try {
      // 댓글 작성 API 호출
      await _tinder.addShortComment(widget.article.shortId, content);

      // 작성 성공 시 댓글 목록 새로고침
      await _loadComments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 작성되었습니다'),
          duration: Duration(milliseconds: 1500),
          backgroundColor: Color(0xFF8B5CF6),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('댓글 작성 실패: $e'),
          duration: const Duration(milliseconds: 2000),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // 드래그 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0A),
                        ),
                        children: [
                          const TextSpan(text: '댓글 '),
                          TextSpan(
                            text: '${_comments.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF6B6B84)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFECE6F0)),

              // 댓글 리스트
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Color(0xFFCCC7D6)),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFF6B6B84), fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadComments,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          )
                        : _comments.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.comment_outlined, size: 64, color: Color(0xFFCCC7D6)),
                                    SizedBox(height: 16),
                                    Text(
                                      '첫 번째 댓글을 작성해보세요!',
                                      style: TextStyle(color: Color(0xFF6B6B84), fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: _comments.length,
                                separatorBuilder: (_, __) => const Divider(height: 32, color: Color(0xFFECE6F0)),
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  return _CommentItem(
                                    author: comment.user.nickname,
                                    profileImage: comment.user.profileImage,
                                    content: comment.content,
                                    timestamp: _formatTimestamp(comment.createdAt),
                                  );
                                },
                              ),
              ),

              const Divider(height: 1, color: Color(0xFFECE6F0)),

              // 댓글 입력창
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          hintStyle: const TextStyle(color: Color(0xFFCCC7D6)),
                          filled: true,
                          fillColor: const Color(0xFFF9F5FE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addComment,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

// 댓글 아이템
class _CommentItem extends StatelessWidget {
  final String author;
  final String? profileImage;
  final String content;
  final String timestamp;

  const _CommentItem({
    required this.author,
    this.profileImage,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 아바타
        profileImage != null && profileImage!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  profileImage!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                ),
              )
            : _buildDefaultAvatar(),
        const SizedBox(width: 12),

        // 댓글 내용
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9AA7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B84),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        author.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
