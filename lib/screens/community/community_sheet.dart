import 'package:flutter/material.dart';
// [수정] 모델과 서비스 임포트
import 'package:newsclip/models/community.dart';
import 'package:newsclip/services/community_service.dart';

enum CommentSortType { latest, popular }

class CommentSheet extends StatefulWidget {
  final CommunityPost post;

  const CommentSheet({
    super.key,
    required this.post,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

// ❌ [삭제] 기존 파일 내에 있던 CommentItem, ReplyItem 클래스 정의 삭제
// (models/community.dart의 CommentItem을 사용합니다)

// UI에서 '답글' 기능을 위한 껍데기 클래스 (API 미지원으로 비워둠)
class ReplyItemStub {
  // 실제 사용되지 않음, 에러 방지용
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _inputController = TextEditingController();

  // [추가] 서비스 인스턴스
  final CommunityService _communityService = CommunityService();

  // [수정] models/community.dart의 CommentItem 사용
  List<CommentItem> _comments = [];
  bool _isLoading = true; // 로딩 상태

  // 답글 대상 (API 6.2는 대댓글 미지원이므로 기능 비활성화용)
  CommentItem? _activeReplyTarget;
  CommentSortType _sortType = CommentSortType.latest;

  @override
  void initState() {
    super.initState();
    // [수정] 시작하자마자 서버에서 댓글 불러오기
    _fetchComments();
  }

  // [구현] 실제 서버 연동 함수
  Future<void> _fetchComments() async {
    try {
      final comments = await _communityService.getComments(widget.post.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('댓글 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ====== 정렬 ======
  List<CommentItem> get _sortedComments {
    final list = [..._comments];
    if (_sortType == CommentSortType.latest) {
      // 최신순 (createdAt 기준 내림차순)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // 인기순 (API 6.1에 좋아요 수 데이터가 없으므로 정렬 불가 -> 최신순 유지)
      // 추후 API 업데이트 시 구현
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }
  /*
  void _toggleSortType() {
    setState(() {
      _sortType = _sortType == CommentSortType.latest
          ? CommentSortType.popular
          : CommentSortType.latest;
    });
  }

  String get _sortLabel =>
      _sortType == CommentSortType.latest ? '최신순' : '인기순';
   */


  // ====== 좋아요 / 싫어요 (API 6.1 미지원으로 기능 비활성화) ======
  void _toggleLike(CommentItem c) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글 좋아요 기능은 아직 준비 중입니다.')),
    );
  }

  void _toggleDislike(CommentItem c) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글 싫어요 기능은 아직 준비 중입니다.')),
    );
  }

  // ====== 댓글 / 답글 추가 ======
  void _addCommentOrReply() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // [API 한계] 현재 대댓글(답글) 작성 API가 없으므로 막아둠
    if (_activeReplyTarget != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답글 작성 기능은 아직 서버가 지원하지 않습니다.')),
      );
      return;
    }

    try {
      // 1. 서버 전송
      await _communityService.createComment(widget.post.postId, text);

      // 2. 입력창 초기화
      _inputController.clear();
      FocusScope.of(context).unfocus();

      // 3. 목록 새로고침 & 댓글 수 증가 (UI 반영)
      await _fetchComments();
      setState(() {
        widget.post.commentCount++;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    }
  }

  // ====== 신고 ======
  void _reportComment(CommentItem c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${c.author.nickname}"님의 댓글을 신고했습니다.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

              // ===== 헤더 =====
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
                    /*
                    // 정렬 필터
                    InkWell(
                      onTap: _toggleSortType,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Text(
                              _sortLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textSub,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 16, color: textSub),
                          ],
                        ),
                      ),
                    ),
                    */
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 24, color: textMain),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: dividerColor),

              // ===== 댓글 리스트 =====
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : sorted.isEmpty
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
                        // 대댓글 미지원이므로 기능 제한
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('답글 기능은 준비 중입니다.')),
                        );
                      },
                      onToggleReplies: () {
                        // 대댓글 없음
                      },
                      onReport: () => _reportComment(c),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: sorted.length,
                ),
              ),

              const Divider(height: 1, color: dividerColor),

              // ===== 하단 입력창 =====
              // (답글 대상 표시 바는 대댓글 미지원이므로 일단 숨김 처리될 것임)
              if (_activeReplyTarget != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF8F7FF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        // API 데이터 불일치로 닉네임 사용
                        'To. ${_activeReplyTarget!.author.nickname}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _activeReplyTarget = null),
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF6B6B84)),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _inputController,
                          // onSubmitted: (_) => _addCommentOrReply(), // 엔터키 전송 원하면 주석 해제
                          decoration: const InputDecoration(
                            hintText: '따뜻한 댓글을 남겨주세요...',
                            hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _addCommentOrReply,
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF8B5CF6),
                        child: const Icon(Icons.arrow_upward,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // 키보드 올라왔을 때 여백
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== 개별 댓글 카드 (수정됨) ======
class _CommentCard extends StatelessWidget {
  final CommentItem data; // models/community.dart의 모델
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onReplyTap;
  final VoidCallback onToggleReplies;
  final VoidCallback onReport;

  const _CommentCard({
    required this.data,
    required this.onLike,
    required this.onDislike,
    required this.onReplyTap,
    required this.onToggleReplies,
    required this.onReport,
  });

  // [추가] 날짜 계산 헬퍼 함수
  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    const textSub = Color(0xFF6B6B84);
    const cardBorder = Color(0x268B5CF6);
    const textMain = Color(0xFF0A0A0A);

    // API 6.1에 없는 데이터는 기본값 처리
    final authorName = data.author.nickname;
    final isExpert = data.author.role == 'expert';
    final expertTag = isExpert ? '전문가' : null;
    final timeAgo = _formatTimeAgo(data.createdAt);

    // API 6.1에는 좋아요 수, 좋아요 여부, 답글 목록이 없으므로 0/false/empty 처리
    final likes = 0;
    final liked = false;
    final disliked = false;
    final hasReplies = false; // 답글 없음
    final repliesExpanded = false;

    // [추가] 프로필 이미지 URL 가져오기
    final profileUrl = data.author.profileImage;

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
              // 1. 프로필 이미지 로직 (if-else 문법 사용)
              if (profileUrl != null && profileUrl.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.network(
                    profileUrl,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _AvatarCircle(
                        label: authorName.isNotEmpty
                            ? authorName.characters.first
                            : '?',
                      );
                    },
                  ),
                )
              else
                _AvatarCircle(
                  label: authorName.isNotEmpty ? authorName.characters.first : '?',
                ),

              const SizedBox(width: 10),

              // 2. 닉네임 및 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isExpert)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: accent.withOpacity(0.08),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ),
              // 신고 버튼 필요 X
              /*
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
              */
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

          // 좋아요 / 싫어요 / 답글 기능 필요 X
          /*
          const SizedBox(height: 8),

          // 좋아요 / 싫어요 / 답글 (UI는 유지하되 데이터는 0/false)
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Icon(
                      liked
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: liked ? accent : textSub,
                    ),
                    const SizedBox(width: 4),
                    if (likes > 0)
                      Text(
                        '$likes',
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
                  disliked
                      ? Icons.thumb_down
                      : Icons.thumb_down_alt_outlined,
                  size: 18,
                  color: disliked ? accent : textSub,
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
          */

          // ===== 답글 (API 미지원으로 표시 안 함) =====
          if (hasReplies) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onToggleReplies,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Icon(
                    repliesExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '답글 보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// _AvatarCircle 위젯은 그대로 유지
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