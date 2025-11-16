import 'package:flutter/material.dart';
import 'package:newsclip/models/community.dart';

enum CommentSortType { latest, popular }

class CommentSheet extends StatefulWidget {
  // 🔽 [수정] 'Post' -> 'CommunityPost'
  final CommunityPost post;

  const CommentSheet({
    super.key,
    required this.post,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

// ===== 데이터 모델 =====
// (CommentItem, ReplyItem 클래스는 변경 없음)
// ... (이하 CommentItem, ReplyItem 모델 클래스)
class ReplyItem {
  final String id;
  final String authorName;
  final String timeAgo;
  final DateTime createdAt;
  String content;
  int likes;
  bool liked;

  ReplyItem({
    required this.id,
    required this.authorName,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    this.likes = 0,
    this.liked = false,
  });
}

class CommentItem {
  final String id;
  final String authorName;
  final bool isExpert;
  final String? expertTag;
  final String timeAgo;
  final DateTime createdAt;

  String content;
  int likes;
  int dislikes;
  bool liked;
  bool disliked;

  List<ReplyItem> replies;
  bool repliesExpanded;

  CommentItem({
    required this.id,
    required this.authorName,
    this.isExpert = false,
    this.expertTag,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    this.likes = 0,
    this.dislikes = 0,
    this.liked = false,
    this.disliked = false,
    this.replies = const [],
    this.repliesExpanded = false,
  });
}
// ... (모델 클래스 끝)


class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _inputController = TextEditingController();

  // 🔽 [수정] Mock Data를 제거하고, 빈 리스트로 초기화합니다.
  // (나중에 이 리스트를 서버에서 받아오도록 initState에서 FutureBuilder로 변경해야 함)
  List<CommentItem> _comments = [];
  CommentItem? _activeReplyTarget;
  CommentSortType _sortType = CommentSortType.latest;

  @override
  void initState() {
    super.initState();
    // 🔽 [제거] Mock Data 생성 로직 전체 삭제
    // _comments = [ ... ];

    // TODO: 서버에서 댓글을 불러오는 로직이 필요합니다.
    // _fetchComments();
  }

  // TODO: (예시) 서버에서 댓글을 불러오는 함수
  // Future<void> _fetchComments() async {
  //   try {
  //     // final comments = await commentService.getComments(widget.post.postId);
  //     // setState(() {
  //     //   _comments = comments;
  //     // });
  //   } catch (e) {
  //     // 에러 처리
  //   }
  // }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ====== 정렬 ======

  List<CommentItem> get _sortedComments {
    final list = [..._comments];
    if (_sortType == CommentSortType.latest) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // 인기순: 좋아요 많은 순
      list.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return list;
  }

  void _toggleSortType() {
    setState(() {
      _sortType = _sortType == CommentSortType.latest
          ? CommentSortType.popular
          : CommentSortType.latest;
    });
  }

  String get _sortLabel =>
      _sortType == CommentSortType.latest ? '최신순' : '인기순';

  // ====== 좋아요 / 싫어요 ======
  // (이하 _toggleLike, _toggleDislike, _toggleReplyLike 로직은 변경 없음)
  // ...
  void _toggleLike(CommentItem c) {
    setState(() {
      if (c.liked) {
        c.liked = false;
        c.likes = (c.likes - 1).clamp(0, 999999);
      } else {
        c.liked = true;
        c.likes += 1;
        if (c.disliked) {
          c.disliked = false;
          c.dislikes = (c.dislikes - 1).clamp(0, 999999);
        }
      }
    });
  }

  void _toggleDislike(CommentItem c) {
    setState(() {
      if (c.disliked) {
        c.disliked = false;
        c.dislikes = (c.dislikes - 1).clamp(0, 999999);
      } else {
        c.disliked = true;
        c.dislikes += 1;
        if (c.liked) {
          c.liked = false;
          c.likes = (c.likes - 1).clamp(0, 999999);
        }
      }
    });
  }

  void _toggleReplyLike(CommentItem parent, ReplyItem r) {
    setState(() {
      r.liked = !r.liked;
      r.likes += r.liked ? 1 : -1;
      if (r.likes < 0) r.likes = 0;
    });
  }
  // ...

  // ====== 댓글 / 답글 추가 ======

  void _addCommentOrReply() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();

    setState(() {
      if (_activeReplyTarget == null) {
        // 원 댓글 추가
        _comments.insert(
          0,
          CommentItem(
            id: now.millisecondsSinceEpoch.toString(),
            authorName: '미소', // TODO: 로그인 유저 이름으로 교체
            timeAgo: '방금 전',
            createdAt: now,
            content: text,
          ),
        );
        // 🔽 [수정] 'widget.post'는 이제 'CommunityPost' 타입
        widget.post.commentCount += 1;
      } else {
        // 답글 추가 (원 댓글에만)
        final target = _activeReplyTarget!;
        target.repliesExpanded = true;
        target.replies = [
          ReplyItem(
            id: now.millisecondsSinceEpoch.toString(),
            authorName: '미소',
            timeAgo: '방금 전',
            createdAt: now,
            content: text,
          ),
          ...target.replies,
        ];
      }
    });

    _inputController.clear();
    setState(() => _activeReplyTarget = null);
    FocusScope.of(context).unfocus();
  }

  // ====== 신고 ======
  // (이하 _reportComment, _reportReply 로직은 변경 없음)
  // ...
  void _reportComment(CommentItem c) {
    // TODO: 실제 신고 API 연동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${c.authorName}"님의 댓글을 신고했습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reportReply(CommentItem parent, ReplyItem r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${r.authorName}"님의 답글을 신고했습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // ...

  @override
  Widget build(BuildContext context) {
    // (이하 build 메서드 내의 UI 코드는 모두 동일합니다)
    // ...
    const accent = Color(0xFF8B5CF6);
    const dividerColor = Color(0xFFE5E5F0);
    const textSub = Color(0xFF6B6B84);
    const textMain = Color(0xFF0A0A0A);

    final sorted = _sortedComments;

    return FractionallySizedBox(
      heightFactor: 0.76,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // ===== 헤더: 댓글 N개 + 정렬 필터 + X =====
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // 🔽 [수정] _comments.length -> widget.post.commentCount
                            '댓글 ${widget.post.commentCount}개',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ... (정렬 필터, 닫기 버튼 동일)
                  ],
                ),
              ),
              const Divider(height: 1, color: dividerColor),

              // ===== 댓글 리스트 =====
              Expanded(
                // 🔽 [수정] 댓글이 0개일 때(서버 연동 전)를 대비한 UI 추가
                child: sorted.isEmpty
                    ? const Center(
                  child: Text(
                    '아직 댓글이 없습니다.\n첫 번째 댓글을 작성해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSub),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemBuilder: (context, index) {
                    final c = sorted[index];
                    return _CommentCard(
                      data: c,
                      onLike: () => _toggleLike(c),
                      onDislike: () => _toggleDislike(c),
                      onReplyTap: () {
                        setState(() {
                          _activeReplyTarget = c;
                        });
                      },
                      onToggleReplies: () {
                        setState(() {
                          c.repliesExpanded = !c.repliesExpanded;
                        });
                      },
                      onReport: () => _reportComment(c),
                      onReplyLike: (reply) => _toggleReplyLike(c, reply),
                      onReportReply: (reply) => _reportReply(c, reply),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: sorted.length,
                ),
              ),

              const Divider(height: 1, color: dividerColor),

              // ... (이하 답글 대상 표시 바, 하단 입력 영역은 모두 동일) ...
              if (_activeReplyTarget != null)
                Container(
                  // ...
                ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  // ...
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== 개별 댓글 카드 ======
// (이하 _CommentCard, _ReplyItem, _AvatarCircle 클래스는 변경 없음)
// ...
class _CommentCard extends StatelessWidget {
  final CommentItem data;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onReplyTap;
  final VoidCallback onToggleReplies;
  final VoidCallback onReport;
  final void Function(ReplyItem reply) onReplyLike;
  final void Function(ReplyItem reply) onReportReply;

  const _CommentCard({
    required this.data,
    required this.onLike,
    required this.onDislike,
    required this.onReplyTap,
    required this.onToggleReplies,
    required this.onReport,
    required this.onReplyLike,
    required this.onReportReply,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    const textSub = Color(0xFF6B6B84);
    const cardBorder = Color(0x268B5CF6);
    const textMain = Color(0xFF0A0A0A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 프로필 + 신고 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarCircle(label: data.authorName.characters.first),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (data.isExpert)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: accent.withValues(alpha: 0.08),
                            ),
                            child: const Text(
                              '전문가',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (data.expertTag != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            data.expertTag!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onReport,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '신고',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSub,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 내용
          Text(
            data.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textMain,
            ),
          ),

          const SizedBox(height: 8),

          // 좋아요 / 싫어요 / 답글
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Icon(
                      data.liked
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: data.liked ? accent : textSub,
                    ),
                    const SizedBox(width: 4),
                    if (data.likes > 0)
                      Text(
                        '${data.likes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSub,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onDislike,
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  data.disliked
                      ? Icons.thumb_down
                      : Icons.thumb_down_alt_outlined,
                  size: 18,
                  color: data.disliked ? accent : textSub,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onReplyTap,
                borderRadius: BorderRadius.circular(20),
                child: const Text(
                  '답글 달기',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // ===== 답글 토글 / 리스트 =====
          if (data.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onToggleReplies,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Icon(
                    data.repliesExpanded
                        ? Icons.expand_less
                        : Icons.expand_more, // 이 부분이 잘렸습니다.
                    size: 20,
                    color: accent,
                  ),
                  // ... 이하 코드가 잘렸습니다.
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ... _AvatarCircle 및 _ReplyItem 위젯 ...
// (이전 코드와 동일하므로 생략)
class _AvatarCircle extends StatelessWidget {
  final String label;
  const _AvatarCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }
}