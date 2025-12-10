import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/news_item.dart';
import '../../models/comment.dart';
import '../../services/news_list_service.dart';
import '../../services/profile_service.dart';
import '../home_screen.dart'; // profileUpdateNotifier 사용
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
  final ProfileService _profileService = ProfileService();

  List<NewsItem> _allNews = [];
  List<NewsItem> _filtered = [];

  // ID 기반 상태 관리
  final Set<int> _liked = {};
  final Set<int> _disliked = {};
  final Set<int> _bookmarked = {};
  final Map<int, int> _dislikeCounts = {};

  // 프로필 정보
  String? _userProfileImage;
  String? _userName;

  final List<String> _categories = const [
    "전체","정치", "경제", "문화", "환경", "기술",
    "스포츠", "라이프스타일", "건강", "교육", "음식", "여행", "패션"
  ];
  late String _activeCategory;

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
    _loadSavedStates(); // 🔥 저장된 상태 복원
    _loadProfile();
    _loadNews(isRefresh: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent * 0.95 &&
          !_isLoadingMore &&
          _canLoadMore) {
        _loadNews();
      }
    });

    // 프로필 변경 감지
    profileUpdateNotifier.addListener(_onProfileUpdated);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 나타날 때마다 프로필 갱신
    _loadProfile();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    profileUpdateNotifier.removeListener(_onProfileUpdated);
    super.dispose();
  }

  void _onProfileUpdated() {
    debugPrint('🔔 프로필 업데이트 알림 받음 -> 프로필 재로드');
    _loadProfile();
  }

  // 🔥 로컬 저장소에서 이전 상태 복원
  Future<void> _loadSavedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedList = prefs.getStringList('liked_news') ?? [];
      final dislikedList = prefs.getStringList('disliked_news') ?? [];
      final bookmarkedList = prefs.getStringList('bookmarked_news') ?? [];

      setState(() {
        _liked.addAll(likedList.map((e) => int.tryParse(e)).whereType<int>());
        _disliked.addAll(dislikedList.map((e) => int.tryParse(e)).whereType<int>());
        _bookmarked.addAll(bookmarkedList.map((e) => int.tryParse(e)).whereType<int>());
      });

      debugPrint('✅ 로컬 저장소에서 상태 복원:');
      debugPrint('   좋아요: ${_liked.length}개, 싫어요: ${_disliked.length}개, 북마크: ${_bookmarked.length}개');
    } catch (e) {
      debugPrint('❌ 상태 복원 실패: $e');
    }
  }

  // 🔥 로컬 저장소에 상태 저장
  Future<void> _saveStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('liked_news', _liked.map((e) => e.toString()).toList());
      await prefs.setStringList('disliked_news', _disliked.map((e) => e.toString()).toList());
      await prefs.setStringList('bookmarked_news', _bookmarked.map((e) => e.toString()).toList());
    } catch (e) {
      debugPrint('❌ 상태 저장 실패: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      debugPrint('🔵 NewsListScreen: 프로필 로드 시작');
      final data = await _profileService.getMyProfile();
      debugPrint('🔵 NewsListScreen: 프로필 응답 받음 - $data');

      // API 응답 구조: { user: {...}, stats: {...} }
      final userMap = data['user'] as Map<String, dynamic>?;

      setState(() {
        _userProfileImage = userMap?['profile_image'] as String?;
        _userName = userMap?['nickname'] as String?;
        debugPrint('🔵 NewsListScreen: 프로필 상태 업데이트 완료');
        debugPrint('   - 이름: $_userName');
        debugPrint('   - 이미지 URL: $_userProfileImage');
      });
    } catch (e) {
      debugPrint('❌ NewsListScreen: 프로필 로드 실패: $e');
      // 실패해도 기본 이미지로 표시되므로 에러 무시
    }
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
    // 키보드 높이를 Scaffold 외부에서 가져옴
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // SafeArea 하단 패딩
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 키보드가 나타나도 전체 레이아웃 조정 안함
      body: Stack(
        children: [
          // 메인 콘텐츠
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _Header(
                  profileImage: _userProfileImage,
                  userName: _userName,
                ),

                // 🔹 검색창 영역 (위아래 경계선 추가)
                Column(
                  children: [
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: _SearchBar(ctrl: _searchCtrl, onChanged: (_) => _applyFilter()),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
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
                          : RefreshIndicator(
                              onRefresh: () => _loadNews(isRefresh: true),
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: EdgeInsets.only(
                                  top: 4,
                                  bottom: _commentsTarget != null ? 360 : 80, // 댓글창 열려있으면 더 많은 패딩
                                  left: 16,
                                  right: 16,
                                ),
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
                                            _saveStates();
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
                                            _saveStates();
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
                                          _saveStates();
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
                ),
              ],
            ),
          ),

          // 댓글 조회 모달 (Scaffold 레벨에서 절대 위치로 고정)
          if (_commentsTarget != null)
            Positioned(
              left: 0,
              right: 0,
              // SafeArea 하단 + 입력창 높이(60) 위에 고정
              bottom: safeAreaBottom + 60,
              height: 280,
              child: _CommentsModal(
                newsId: _commentsTarget!.id,
                newsTitle: _commentsTarget!.title,
                onClose: () => setState(() {
                  _commentsTarget = null;
                }),
              ),
            ),

          // 댓글 입력창 (키보드 위로 이동)
          if (_commentsTarget != null)
            Positioned(
              left: 0,
              right: 0,
              // 키보드가 있으면 키보드 위로, 없으면 SafeArea 하단에
              bottom: keyboardHeight > 0 ? keyboardHeight : safeAreaBottom,
              child: _CommentInputBar(
                newsId: _commentsTarget!.id,
                onCommentAdded: () {
                  setState(() {
                    final allIndex = _allNews.indexWhere((n) => n.id == _commentsTarget!.id);
                    if (allIndex != -1) {
                      _allNews[allIndex] = _allNews[allIndex].copyWith(
                        comments: _allNews[allIndex].comments + 1,
                      );
                    }

                    final filteredIndex = _filtered.indexWhere((n) => n.id == _commentsTarget!.id);
                    if (filteredIndex != -1) {
                      _filtered[filteredIndex] = _filtered[filteredIndex].copyWith(
                        comments: _filtered[filteredIndex].comments + 1,
                      );
                    }

                    final currentTarget = _commentsTarget;
                    _commentsTarget = null;
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) {
                        setState(() {
                          _commentsTarget = currentTarget;
                        });
                      }
                    });
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    this.profileImage,
    this.userName,
  });

  final String? profileImage;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 _Header 빌드: profileImage=$profileImage, userName=$userName');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // 프로필 이미지 - 실제 사용자 이미지 또는 기본 이미지
          profileImage != null && profileImage!.isNotEmpty
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileImage!),
                  backgroundColor: Colors.grey,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('❌ 프로필 이미지 로드 실패: $exception');
                  },
                )
              : const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName != null ? '안녕하세요, $userName님 👋' : '안녕하세요 👋',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              const Text(
                '오늘의 뉴스를 확인해보세요',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
                    color: selected ? Color(0xFF8B5CF6) : Colors.white,
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

class _CommentInputBar extends StatefulWidget {
  const _CommentInputBar({
    required this.newsId,
    required this.onCommentAdded,
  });

  final int newsId;
  final VoidCallback onCommentAdded;

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
  final TextEditingController _controller = TextEditingController();
  final NewsListService _newsService = NewsListService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty || _isSubmitting) return;

    final content = _controller.text.trim();
    _controller.clear();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _newsService.addNewsComment(widget.newsId, content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 작성되었습니다'),
            duration: Duration(milliseconds: 1500),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );

        // 댓글 목록 새로고침
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 작성 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        // 실패 시 입력 내용 복원
        _controller.text = content;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _isSubmitting
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                  color: _isSubmitting ? Colors.grey : null,
                  shape: BoxShape.circle,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsModal extends StatefulWidget {
  const _CommentsModal({
    required this.newsId,
    required this.newsTitle,
    required this.onClose,
  });

  final int newsId;
  final String newsTitle;
  final VoidCallback onClose;

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  final NewsListService _newsService = NewsListService();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _newsService.getNewsComments(widget.newsId);
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

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.newsTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadComments,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        )
                      : _comments.isEmpty
                          ? const Center(
                              child: Text(
                                '첫 댓글을 작성해보세요!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80), // 입력창 공간
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return ListTile(
                                  leading: comment.user.profileImage != null && comment.user.profileImage!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 14,
                                          backgroundImage: NetworkImage(comment.user.profileImage!),
                                          backgroundColor: Colors.grey,
                                        )
                                      : const CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          radius: 14,
                                          child: Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                  title: Row(
                                    children: [
                                      Text(
                                        comment.user.nickname,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '· ${_formatTimestamp(comment.createdAt)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(comment.content, style: const TextStyle(fontSize: 13)),
                                  dense: true,
                                );
                              },
                            ),
            ),
          ],
        ),
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
