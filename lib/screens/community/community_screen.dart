// community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../services/profile_service.dart';
// import '../../widgets/common/bottom_navigation.dart';
import 'community_create_screen.dart';
import 'package:newsclip/services/community_service.dart';
import 'package:newsclip/models/community.dart';
import 'community_sheet.dart'; // 👈 [추가] 이 줄을 추가하세요.

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // --- [수정] Service 및 상태 변수 ---
  final CommunityService _communityService = CommunityService();
  late Future<List<CommunityPost>> _postsFuture; // 데이터를 Future로 관리
  final TextEditingController _search = TextEditingController();
  String _tab = 'all';
  // ❌ _bottomIndex 및 Mock Data 제거
  // int _bottomIndex = 1;
  // final List<Post> _posts = [...];

  @override
  void initState() {
    super.initState();
    // 1. 화면이 로드될 때 서버에서 데이터를 가져옵니다.
    _postsFuture = _fetchPosts();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // 2. 서버에서 데이터를 가져오는 메서드
  Future<List<CommunityPost>> _fetchPosts() {
    //return _communityService.getPosts(type: _tab, page: 1);
    return _communityService.getPosts(type: 'all', page: 1);
  }

  // 3. [수정] 목록을 새로고침하는 메서드 (RefreshIndicator용)
  Future<void> _refreshPosts() {
    setState(() {
      _postsFuture = _fetchPosts();
    });
    return _postsFuture;
  }

  // 4. (추후 구현) 좋아요/싫어요 서비스 연동 메서드
  void _handleLike(CommunityPost post) {
    // 즉각적인 UI 반응
    setState(() {
      post.toggleLike();
    });

    // (서버 연동)
    try {
      _communityService.interactWithPost(post.postId, 'like');
    } catch (e) {
      // 실패 시 UI 롤백
      setState(() {
        post.toggleLike();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리에 실패했습니다: $e')),
      );
    }
  }

  void _handleDislike(CommunityPost post) async {
    setState(() {
      post.toggleDislike();
    });
    try {
      // await를 붙여야 에러가 났을 때 catch로 잡을 수 있습니다.
      await _communityService.interactWithPost(post.postId, 'dislike');
    } catch (e) {
      // 3. 실패 시 UI 롤백 (다시 원래대로 되돌림)
      setState(() {
        post.toggleDislike();
      });

      // (선택 사항) 에러 메시지 띄우기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('싫어요 처리에 실패했습니다: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // ❌ Mock Data 필터링 로직 제거
    // final filtered = _posts.where(...).toList();

    // [수정] Scaffold와 bottomNavigationBar 제거 (부모 위젯이 담당)
    return SafeArea(
      child: Column(
        children: [
          // 헤더 (동일)
          _Header(),
          const SizedBox(height: 8),
          // 검색바 + 아이콘 두 개 (동일)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: _SearchField(
                        controller: _search,
                        // 5. 검색어 입력 시 setState만 호출하면 FutureBuilder가 재실행됨
                        onChanged: (_) => setState(() {}))),
                // 검색 필터 기능 필요 X
                /*
                const SizedBox(width: 8),
                _SquareIconButton(icon: Icons.tune),
                 */
                const SizedBox(width: 8),
                // 6. [수정] 글쓰기 버튼 (새로고침 기능 포함)
                _SquareIconButton(
                  icon: Icons.create,
                  filled: true,
                  onTap: () async {
                    // 글쓰기 화면으로 이동
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewPostScreen(),
                      ),
                    );

                    // 글 작성이 성공적으로 완료되면(true 반환) 목록 새로고침
                    if (result == true) {
                      _refreshPosts();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 탭 칩 (동일)
          _Chips(
            value: _tab,
            // 7. [수정] 탭 변경 시 목록 새로고침
            onChanged: (v) {
              setState(() {
                _tab = v;
                // _refreshPosts(); // 탭 변경 시 새로고침
              });
            },
          ),
          const SizedBox(height: 8),

          // 8. [수정] 피드 (RefreshIndicator + FutureBuilder로 변경)
          Expanded(
            child: RefreshIndicator( // 👈 [추가] 당겨서 새로고침
              onRefresh: _refreshPosts,
              child: FutureBuilder<List<CommunityPost>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  // --- 로딩/에러/데이터 없음 처리 ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('오류: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('게시글이 없습니다.'));
                  }

                  // --- 데이터가 있을 경우 ---
                  final posts = snapshot.data!;

                  // 9. 'filtered' 로직을 FutureBuilder 내부로 이동 (검색어 필터링)
                  final filtered = posts.where((p) {
                    // (A) 데이터 정제: 혹시 모를 대소문자/공백 차이를 없앱니다.
                    final String postRole = (p.author.role ?? '').trim().toLowerCase();
                    final bool isExpertPost = postRole == 'expert';

                    // (B) 탭 필터링 (원하는 것만 return true)
                    if (_tab == 'expert') {
                      // 전문가 탭: 전문가 글만 보여줌
                      if (!isExpertPost) return false;
                    }
                    else if (_tab == 'general') {
                      // 일반 탭: 전문가 글은 숨김 (즉, 전문가가 아니면 보여줌)
                      if (isExpertPost) return false;
                    }
                    // 'all' 탭은 위 조건들에 안 걸리므로 모두 통과

                    final q = _search.text.trim().toLowerCase();
                    if (q.isEmpty) return true;

                    // 검색어 필터링만 수행 (탭 필터링은 서버가 담당)
                    return p.title.toLowerCase().contains(q) ||
                        p.content.toLowerCase().contains(q) ||
                        p.author.nickname.toLowerCase().contains(q) ||
                        p.category.toLowerCase().contains(q);
                  }).toList();

                  // 10. ListView.separated
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length, // 실제 필터된 개수
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = filtered[index];

                      // 11. [수정] _PostCard에 CommunityPost 전달
                      return _PostCard(
                        post: post, // 👈 CommunityPost 전달
                        onLike: () => _handleLike(post),
                        onDislike: () => _handleDislike(post),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======== UI 파츠 (스크린 레벨) ========
class _Header extends StatefulWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final ProfileService _profileService = ProfileService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // --- 1. 기본값 설정 ---
        String displayNickname = '안녕하세요 👋';
        String? profileImageUrl;

        // --- 2. 데이터 파싱 로직 (API 응답 구조: { user: {...}, stats: {...} }) ---
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final userMap = data['user'] as Map<String, dynamic>?;

          if (userMap != null) {
            // 닉네임 설정
            final nickname = userMap['nickname'];
            if (nickname != null) {
              displayNickname = '$nickname님 👋';
            }

            // 프로필 이미지 설정
            final serverImage = userMap['profile_image'];
            if (serverImage != null && serverImage.toString().isNotEmpty) {
              profileImageUrl = serverImage.toString();
            }
          }
        }

        // --- 3. UI 렌더링 ---
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              // 프로필 이미지 아바타
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                // 이미지가 있으면 NetworkImage, 없으면 null
                backgroundImage: (profileImageUrl != null)
                    ? NetworkImage(profileImageUrl)
                    : null,
                // 이미지가 없을 때 보여줄 아이콘
                child: (profileImageUrl == null)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 닉네임 표시
                  Text(
                    displayNickname,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '오늘의 커뮤니티를 확인해보세요',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // 알림 아이콘 (기존 유지), 점 3개 아이콘 필요 X
              /*
              Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 28, color: Colors.black54),
                  Positioned(
                    right: 2,
                    top: 2,
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
               */
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
// ... (이하 동일)
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '커뮤니티 검색...',
          hintStyle: const TextStyle(color: Color(0xFF6B6B84)),
          filled: true,
          fillColor: const Color(0xFFF8F7FF),
          prefixIcon:
          const Icon(Icons.search, size: 18, color: Color(0xFF6B6B84)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
// ... (이하 동일)
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  const _SquareIconButton({
    required this.icon,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xFF8B5CF6) : Colors.white;
    final fg = filled ? Colors.white : const Color(0xFF6B6B84);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? () => debugPrint('$_SquareIconButton tapped'),
        splashColor: filled
            ? Colors.white.withOpacity(0.15)
            : const Color(0xFF8B5CF6).withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Ink(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x268B5CF6)),
          ),
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
// ... (이하 동일)
  final String value;
  final ValueChanged<String> onChanged;
  const _Chips({required this.value, required this.onChanged});

  static const _items = [
    ('all', '전체'),
    ('expert', '전문가'),
    ('general', '일반'),
  ];

  int _indexOf(String v) => _items.indexWhere((e) => e.$1 == v);

  @override
  Widget build(BuildContext context) {
    final selIdx = (_indexOf(value) >= 0) ? _indexOf(value) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 36,
        child: LayoutBuilder(builder: (context, c) {
          final segWidth = c.maxWidth / _items.length;
          return Stack(
            children: [
              // background + border
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x268B5CF6), width: 1),
                ),
              ),
              // moving white thumb
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: segWidth * selIdx,
                width: segWidth,
                top: 3,
                bottom: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // labels
              Row(
                children: List.generate(_items.length, (i) {
                  final selected = i == selIdx;
                  final label = _items[i].$2;
                  final val = _items[i].$1;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onChanged(val),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: selected
                                ? const Color(0xFF0A0A0A)
                                : const Color(0xFF6B6B84),
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

//
// 🔽🔽🔽 [_PostCard] 와 하위 위젯들 수정 🔽🔽🔽
//

class _PostCard extends StatefulWidget {
  // 12. [수정] 'Post'가 아닌 'CommunityPost'를 받도록 변경
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onDislike,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with TickerProviderStateMixin {
  // (AnimationController, dispose 등은 변경 없음)
  late final AnimationController _likeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 140));
  late final AnimationController _dislikeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 140));

  late final Animation<double> _likeScale = Tween(begin: 1.0, end: 1.15)
      .chain(CurveTween(curve: Curves.easeOut))
      .animate(_likeCtrl);

  late final Animation<double> _dislikeScale = Tween(begin: 1.0, end: 1.15)
      .chain(CurveTween(curve: Curves.easeOut))
      .animate(_dislikeCtrl);

  @override
  void dispose() {
    _likeCtrl.dispose();
    _dislikeCtrl.dispose();
    super.dispose();
  }

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 13. [수정] p는 이제 CommunityPost 타입
    final p = widget.post;

    // [추가] 디버깅 로그: 여기서 Role 값이 실제로 어떻게 들어오는지 확인
    debugPrint('🔎 [DEBUG] 글ID: ${p.postId} | 작성자: ${p.author.nickname} | Role 값: "${p.author.role}"');

    return Container(
      // (Container-Decoration은 변경 없음)
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x2B8B5CF6), width: 1.0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 14. [수정] CommunityPost 모델의 author.profileImage 사용
              _buildAvatar(p.author.profileImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 + 전문가뱃지
                    Row(
                      children: [
                        // 15. [수정] p.author.nickname 사용
                        Text(p.author.nickname,
                            style: const TextStyle(fontSize: 14)),

                        // 16. [수정] p.author.role == 'expert'로 확인
                        if (p.author.role == 'expert') ...[
                          const SizedBox(width: 8),
                          _buildExpertBadge('전문가'), // (API 명세 5.1에 expertTag가 없음)
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // 17. [수정] p.createdAt을 포맷팅 (intl 패키지 필요)
                        Text(DateFormat('MM월 dd일').format(p.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B6B84))),
                        const SizedBox(width: 8),
                        // 18. [수정] p.category 사용
                        _buildOutlineChip(label: p.category),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 제목 (p.title은 동일)
          Text(p.title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),

          // '더보기' LayoutBuilder (p.content는 동일하므로 수정 없음)
          LayoutBuilder(builder: (context, constraints) {
            const maxLines = 3;
            const contentStyle = TextStyle(fontSize: 14, color: Color(0xFF6B6B84));
            const linkStyle = TextStyle(
              fontSize: 14,
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            );
            final text = p.content;

            final scaler = MediaQuery.textScalerOf(context);
            // 18. [수정] locale 변수 추가
            final locale = Localizations.localeOf(context);

            final fullTp = TextPainter(
              text: TextSpan(text: text, style: contentStyle),
              textDirection: ui.TextDirection.ltr,
              maxLines: maxLines,
              textScaler: scaler,
              locale: locale, // 👈 locale 추가
            )..layout(maxWidth: constraints.maxWidth);
            final overflow = fullTp.didExceedMaxLines;

            if (!_expanded && overflow) {
              final addonSpan = TextSpan(
                style: contentStyle,
                children: [
                  const TextSpan(text: ' … '),
                  TextSpan(text: '더보기', style: linkStyle),
                ],
              );
              final addonTp = TextPainter(
                text: addonSpan,
                textDirection: ui.TextDirection.ltr,
                textScaler: scaler,
                locale: locale, // 👈 locale 추가
              )..layout();
              final reserveWidth = addonTp.width;

              int lo = 0, hi = text.length, best = 0;
              while (lo <= hi) {
                final mid = (lo + hi) >> 1;

                final probeTp = TextPainter(
                  text: TextSpan(
                    text: text.substring(0, mid).trimRight(),
                    style: contentStyle,
                  ),
                  textDirection: ui.TextDirection.ltr,
                  maxLines: maxLines,
                  textScaler: scaler,
                  locale: locale, // 👈 locale 추가
                )..layout(maxWidth: constraints.maxWidth - reserveWidth);

                if (probeTp.didExceedMaxLines) {
                  hi = mid - 1;
                } else {
                  best = mid;
                  lo = mid + 1;
                }
              }

              final visible = text.substring(0, best).trimRight();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: maxLines,
                    overflow: TextOverflow.clip,
                    textScaler: scaler,
                    locale: locale, // 👈 locale 추가
                    text: TextSpan(
                      style: contentStyle,
                      children: [
                        TextSpan(text: visible),
                        const TextSpan(text: ' … '),
                        TextSpan(
                          text: '더보기',
                          style: linkStyle,
                          recognizer: (TapGestureRecognizer()
                            ..onTap = () => setState(() => _expanded = true)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: contentStyle,
                  maxLines: _expanded ? null : maxLines,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  textScaler: scaler,
                ),
                if (overflow) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_expanded ? '접기' : '더보기'),
                    ),
                  ),
                ],
              ],
            );
          }),


          // 이미지 갤러리 (p.images는 동일)
          if (p.images.isNotEmpty) _ImagesGrid(images: p.images),
          const SizedBox(height: 10),

          // 19. [수정] 카운터/버튼 (p.likes, p.dislikes, p.comments 사용)
          Row(
            children: [
              // Like
              ScaleTransition(
                scale: _likeScale,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await _likeCtrl.forward();
                    _likeCtrl.reverse();
                    widget.onLike(); // 부모의 _handleLike 호출
                  },
                  child: Row(
                    children: [
                      Icon(Icons.favorite,
                          size: 18,
                          color: p.isLiked // (p.isLiked는 CommunityPost에 있음)
                              ? const Color(0xFFFA2B36)
                              : const Color(0xFF6B6B84)),
                      const SizedBox(width: 4),
                      Text('${p.likeCount}', // p.likeCount 사용
                          style: TextStyle(
                              fontSize: 12,
                              color: p.isLiked
                                  ? const Color(0xFFFA2B36)
                                  : const Color(0xFF6B6B84))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Dislike
              ScaleTransition(
                scale: _dislikeScale,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await _dislikeCtrl.forward();
                    _dislikeCtrl.reverse();
                    widget.onDislike(); // 부모의 _handleDislike 호출
                  },
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: 3.1416,
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: p.isDisliked // (p.isDisliked는 CommunityPost에 있음)
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF6B6B84),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${p.dislikeCount}', // p.dislikeCount 사용
                          style: TextStyle(
                              fontSize: 12,
                              color: p.isDisliked
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF6B6B84)))
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
              // 댓글
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  /*
                  // 20. [수정] CommentsPage에 CommunityPost 전달
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CommentsPage(post: p)));
                   */
                  // 20. [수정] CommentsPage 대신 CommentSheet를 띄웁니다.
                  // 2️⃣ await 추가: 댓글창이 닫힐 때까지 여기서 기다림
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (sheetContext) {
                      return CommentSheet(post: p);
                    },
                  );
                  /*
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // 👈 시트가 키보드 등에 의해 가려지지 않게 함
                    backgroundColor: Colors.transparent, // 👈 CommentSheet의 둥근 모서리 적용
                    builder: (sheetContext) {
                      return CommentSheet(post: p); // 👈 p를 CommentSheet로 전달
                    },
                  );
                  */
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined,
                          size: 18, color: Color(0xFF6B6B84)),
                      const SizedBox(width: 4),
                      Text('${p.commentCount}', // p.commentCount 사용
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B6B84))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 21. [수정] _buildAvatar (CommunityPost의 profileImage 사용)
  Widget _buildAvatar(String? url) {
    // URL이 유효하고 http로 시작하는지 확인 (json-server 테스트 시 null일 수 있음)
    final bool isValidUrl = url != null && url.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: (isValidUrl)
          ? Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        // (이미지 로드 실패 시 대체 아이콘)
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAvatar(),
      )
          : _buildFallbackAvatar(), // 기본 아바타
    );
  }

  // (대체 아바타 위젯)
  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade200,
      child: Icon(Icons.person_outline, color: Colors.grey.shade400),
    );
  }

  // (_buildExpertBadge, _buildOutlineChip은 수정 없음)
  Widget _buildExpertBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFECFE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B5CF6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOutlineChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x268B5CF6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
// ... (이하 동일)
  final List<String> images;
  const _ImagesGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _rounded(Image.network(images[0],
          height: 256, width: double.infinity, fit: BoxFit.cover));
    }
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(
              child: _rounded(
                  Image.network(images[0], height: 192, fit: BoxFit.cover))),
          const SizedBox(width: 8),
          Expanded(
              child: _rounded(
                  Image.network(images[1], height: 192, fit: BoxFit.cover))),
        ],
      );
    }
    // 3장 이상
    return Column(
      children: [
        _rounded(Image.network(images[0],
            height: 192, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _rounded(
                    Image.network(images[1], height: 128, fit: BoxFit.cover))),
            const SizedBox(width: 8),
            Expanded(
                child: _rounded(
                    Image.network(images[2], height: 128, fit: BoxFit.cover))),
          ],
        ),
      ],
    );
  }

  Widget _rounded(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: child,
  );
}


// 22. [수정] CommentsPage가 CommunityPost를 받도록 변경
class CommentsPage extends StatelessWidget {
  final CommunityPost post;
  const CommentsPage({required this.post, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('댓글')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Center(child: Text('댓글 화면은 아직 구성되지 않았습니다.')),
          ],
        ),
      ),
    );
  }
}

// 23. ❌ [제거] 기존의 하드코딩된 Post 모델은 삭제합니다.
// class Post { ... }