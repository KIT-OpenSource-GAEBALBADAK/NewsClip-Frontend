import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../../services/auth_service.dart';
import '../community/community_screen.dart';
import '../../services/community_service.dart';
import '../login/login_screen.dart';
import '../../models/profile_lists.dart';

// [수정] 방금 만드신 ProfileService import (파일 경로가 다르면 수정해주세요)
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // [추가] 내가 쓴 게시글 목록을 저장할 변수
  List<MyPost> _myPosts = [];

  // [추가] 내가 쓴 댓글 목록을 저장할 변수
  List<MyComment> _myComments = [];

  // [수정] 서비스 인스턴스 및 로딩 상태 변수 추가
  final ProfileService _profileService = ProfileService();

  // [추가] 커뮤니티 서비스 (이게 없어서 빨간 줄이 떴던 겁니다!)
  final CommunityService _communityService = CommunityService();

  bool _isLoading = true; // 로딩 중인지 여부

  // [수정] 초기값을 빈 값으로 설정 (API 로드 전 안전장치)
  String name = '';
  String bio = '';
  String avatarUrl = '';
  // 기본 이미지 URL (서버 이미지가 없을 때 사용)
  final String defaultAvatar =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face';

  bool isExpert = false;
  String joinDate = '';

  int posts = 0;
  int comments = 0;
  int likes = 0;
  int followers = 0;

  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool isEditing = false;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bioController = TextEditingController(); // 초기화만 해둠

    // [수정] 화면 시작 시 데이터 로드 함수 실행
    _loadProfileData();
  }

  // [수정] API를 통해 프로필 정보를 가져오는 함수
  Future<void> _loadProfileData() async {
    try {
      // API 호출
      final data = await _profileService.getMyProfile();

      print('📌 [DEBUG] 서버에서 받은 프로필 데이터 전체: $data');
      print('📌 [DEBUG] 닉네임 값 확인: ${data['user']['nickname']}');

      // [추가] 게시글 목록 조회 (최근 5개만)
      final postData = await _profileService.getMyPosts(page: 1, size: 5);

      // [추가] 댓글 목록 조회 (최근 5개)
      final commentData = await _profileService.getMyComments(page: 1, size: 5);

      if (!mounted) return;

      setState(() {
        // 1. 닉네임
        // 'user' 객체와 'stats' 객체를 먼저 분리해서 꺼냅니다.
        final userMap = data['user'] ?? {};
        final statsMap = data['stats'] ?? {};
        name = userMap['nickname'] ?? '알 수 없음';

        // 2. 프로필 이미지 (userMap에서 꺼내기)
        final serverImage = userMap['profile_image'];
        if (serverImage != null && serverImage.toString().isNotEmpty) {
          avatarUrl = serverImage;
        } else {
          avatarUrl = defaultAvatar;
        }

        // 3. 통계 (statsMap에서 꺼내기 & 키 이름 스네이크 케이스로 수정)
        // 로그: post_count, comment_count, total_received_likes
        posts = statsMap['post_count'] ?? 0;
        comments = statsMap['comment_count'] ?? 0;
        likes = statsMap['total_received_likes'] ?? 0; // likeCount -> total_received_likes 확인

        // 나머지는 그대로
        bio = userMap['bio'] ?? data['bio'] ?? '아직 자기소개가 없습니다.';
        _bioController.text = bio;

        // [추가] 받아온 게시글 리스트 저장
        _myPosts = postData.posts;

        // [추가] 댓글 리스트 저장
        _myComments = commentData.comments;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 프로필 로딩 에러: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // 에러 발생 시 기본값 유지
        name = '오류 발생';
        bio = '정보를 불러오지 못했습니다.';
        avatarUrl = defaultAvatar;
      });
      // 에러 메시지 띄우기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 로딩 실패: $e')),
      );
    }
  }

  // [수정] 로그 위치 변경 (에러 나기 전에 ID 확인)
  Future<void> _deletePost(String postId) async {
    try {
      // [중요] 삭제 요청 보내기 '전'에 ID를 먼저 출력합니다.
      print('🔍 [DEBUG] 삭제 시도할 게시글 ID: $postId');

      // [수정] String이므로 '0' 문자열이거나 비어있는지 확인
      if (postId == '0' || postId == '') {
        throw Exception('게시글 ID가 유효하지 않습니다.');
      }

      // API 호출
      await _communityService.deletePost(postId.toString());

      print('✅ 게시글 삭제 성공 (서버 응답 완료)');

      if (!mounted) return;
      setState(() {
        _myPosts.removeWhere((post) => post.postId == postId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
    } catch (e) {
      print('❌ 삭제 실패 로그: $e'); // 에러 내용을 콘솔에 자세히 출력
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  // 게시글 삭제 확인 다이얼로그
  // [수정] int postId -> String postId
  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost(postId as String); // 이제 String을 넘기므로 에러 없음
            },
            child: const Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final now = DateTime.now();
    final diffInHours =
    (now.difference(date).inMilliseconds / (1000 * 60 * 60)).floor();

    if (diffInHours < 1) return '방금 전';
    if (diffInHours < 24) return '${diffInHours}시간 전';

    final diffInDays = (diffInHours / 24).floor();
    if (diffInDays == 1) return '어제';
    if (diffInDays < 7) return '${diffInDays}일 전';
    if (diffInDays < 14) return '1주 전';
    return '${(diffInDays / 7).floor()}주 전';
  }

  void _openBookmarkedNews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookmarksScreen(),
      ),
    );
  }
  // [추가] 커뮤니티(게시글 목록) 화면으로 이동하는 함수
  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // 'CommunityScreen'은 실제 커뮤니티 화면 위젯 이름이어야 합니다.
        builder: (_) => const CommunityScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [수정] 로딩 중이면 로딩 인디케이터 표시
    if (_isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.background,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final app = context.watch<AppProvider>();
    final bookmarkedNews = app.bookmarkedNews;

    // mock posts (현재 API에는 게시글 목록 조회 기능이 없으므로 더미 유지)
    final mockMyPosts = [
      {
        'id': '1',
        'title': 'Z세대가 바라본 뉴스 미디어의 미래',
        'likes': 23,
        'comments': 8,
        'date': '3일 전',
      },
      {
        'id': '2',
        'title': '대학생 알바와 학업 병행하는 현실적인 팁',
        'likes': 45,
        'comments': 12,
        'date': '1주 전',
      },
      {
        'id': '3',
        'title': '소셜미디어 뉴스 소비, 장단점 분석',
        'likes': 31,
        'comments': 6,
        'date': '2주 전',
      },
    ];

    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          // ===== Header =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '프로필',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // ===== Tabs =====
          Container(
            padding:
            const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor:
                Theme.of(context).textTheme.bodyMedium?.color,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '프로필'),
                  Tab(text: '활동'),
                  Tab(text: '설정'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            height: 1,      // 공간 높이
            thickness: 1,   // 선 두께
            color: Theme.of(context).dividerColor.withOpacity(0.2), // 연한 회색
          ),

          // ===== Tab contents =====
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ─── 프로필 탭 ───
                SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // 프로필 카드
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: Column(
                            children: [
                              // [수정] 이미지 로드 부분 안전하게 처리
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: avatarUrl.startsWith('http')
                                    ? NetworkImage(avatarUrl)
                                    : NetworkImage(defaultAvatar),
                                onBackgroundImageError: (_, __) {
                                  // 이미지 로드 실패 시 처리 (필요시 구현)
                                },
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isExpert) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.08),
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.shield,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '전문가',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // bio + edit
                                  isEditing
                                      ? Column(
                                    children: [
                                      TextField(
                                        controller: _bioController,
                                        maxLines: 3,
                                        maxLength: 150,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                          const EdgeInsets.all(8),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                bio = _bioController.text;
                                                isEditing = false;
                                              });
                                              // TODO: 여기서 실제로 서버에 bio 수정 요청을 보낼 수 있습니다.
                                            },
                                            child: const Text('저장'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _bioController.text = bio;
                                                isEditing = false;
                                              });
                                            },
                                            child: const Text('취소'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                      : Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 260,
                                        child: Text(
                                          bio,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isEditing = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    joinDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 활동 통계 카드
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '활동 통계',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  _StatCard(
                                    icon: Icons.chat_bubble_outline,
                                    label: '작성글',
                                    value: posts,
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    icon: Icons.mode_comment_outlined,
                                    label: '댓글',
                                    value: comments,
                                    color: Colors.green,
                                  ),
                                  _StatCard(
                                    icon: Icons.favorite_border,
                                    label: '좋아요',
                                    value: likes,
                                    color: Colors.red,
                                  ),
                                  _StatCard(
                                    icon: Icons.person_outline,
                                    label: '팔로워',
                                    value: followers,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── 활동 탭 ───
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      // 1. 내가 쓴 글 카드
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 헤더
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '내가 쓴 글',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  // 🔽 [추가] 게시글 개수 뱃지
                                  const SizedBox(width: 8),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$posts', // 실제 게시글 개수 변수
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // 내용
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                              child: _myPosts.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: Text(
                                    '작성한 게시글이 없습니다.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ),
                              )
                                  : Container(
                                //height: _myPosts.length > 3 ? 240 : null,
                                height: 220,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        ..._myPosts.map((post) {
                                          return Container(
                                            margin:
                                            const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.02),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        post.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons.favorite_border,
                                                                  size: 14),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                '${post.likeCount}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey.shade600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .mode_comment_outlined,
                                                                  size: 14),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                '${post.commentCount}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey.shade600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Text(
                                                            _formatDate(post.createdAt
                                                                .toString()),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.more_vert,
                                                        size: 18,
                                                        color: Colors.grey.shade500),
                                                    onSelected: (value) {
                                                      if (value == 'delete') {
                                                        _showDeleteConfirmation(
                                                            post.postId.toString());
                                                      }
                                                    },
                                                    itemBuilder: (BuildContext context) =>
                                                    [
                                                      const PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text('게시글 삭제',
                                                            style:
                                                            TextStyle(fontSize: 13)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),

                      // 2. 내가 쓴 댓글 카드
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              // onTap: () {print('댓글 전체보기 클릭됨');},
                              borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(24)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.mode_comment_outlined, size: 18),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '내가 쓴 댓글',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '$comments',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                              child: _myComments.isNotEmpty
                                  ? Container(
                                //height: _myComments.length > 3 ? 240 : null,
                                height: 220,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        ..._myComments.map((comment) {
                                          return Container(
                                            margin:
                                            const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.02),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        comment.content,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                    horizontal: 6,
                                                                    vertical: 2,
                                                                  ),
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        999),
                                                                    border: Border.all(
                                                                      color: Colors.grey
                                                                          .shade300,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    comment.targetType ==
                                                                        'news'
                                                                        ? '뉴스'
                                                                        : '게시글',
                                                                    style:
                                                                    const TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.grey,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Flexible(
                                                                  child: Text(
                                                                    comment.targetTitle,
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow
                                                                        .ellipsis,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.grey
                                                                          .shade600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            _formatDate(comment.createdAt
                                                                .toString()),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  : Column(
                                children: [
                                  const SizedBox(height: 12),
                                  const SizedBox(height: 8),
                                  Text(
                                    '작성한 댓글이 없습니다.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── 설정 탭 ───
                SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // 알림 설정
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '알림 설정',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 푸시 알림
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          notificationsEnabled
                                              ? Icons.volume_up
                                              : Icons.volume_off,
                                          size: 18,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '푸시 알림',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '댓글, 좋아요 알림 받기',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: notificationsEnabled,
                                    onChanged: (v) {
                                      setState(() {
                                        notificationsEnabled = v;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // 소리 알림
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          soundEnabled
                                              ? Icons.volume_up
                                              : Icons.volume_off,
                                          size: 18,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '소리 알림',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '알림음 재생',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: soundEnabled,
                                    onChanged: (v) {
                                      setState(() {
                                        soundEnabled = v;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 화면 설정 (다크 모드)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '화면 설정',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.yellow.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          app.isDarkMode
                                              ? Icons.dark_mode
                                              : Icons.light_mode,
                                          size: 18,
                                          color: Colors.yellow.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '다크 모드',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '어두운 테마 사용',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: app.isDarkMode,
                                    onChanged: (_) {
                                      app.toggleDarkMode();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 계정 관리
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '계정 관리',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: 계정 정보 수정
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: const Icon(Icons.settings, size: 18),
                                label: const Text('계정 정보 수정'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: 개인정보 처리방침
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon:
                                const Icon(Icons.shield_outlined, size: 18),
                                label: const Text('개인정보 처리방침'),
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    // 1. 로그아웃 (토큰 삭제)
                                    await AuthService().logout();
                                    print('✅ 로그아웃 완료 (토큰 삭제됨)');

                                    // 2. 로그인 화면으로 이동 (스택 비우기)
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('로그아웃 되었습니다.')),
                                      );
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                            (route) => false, // 이전 화면들 싹 지우기
                                      );
                                    }
                                  } catch (e) {
                                    print('❌ 로그아웃 실패: $e');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('로그아웃'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}