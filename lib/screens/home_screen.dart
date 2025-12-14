import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'news/news_list_screen.dart';
import 'news/news_tinder_screen.dart';
import 'community/community_screen.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/profile_setup_screen.dart';
import '../widgets/common/bottom_navigation.dart';
import '../widgets/news_recommend_popup.dart';
import '../services/profile_service.dart';

// 프로필 변경을 알리기 위한 전역 notifier
final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

// 🔥 프로필 데이터 전역 캐시 (중복 호출 방지)
class ProfileCache {
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  static bool get hasValidCache {
    if (_cachedProfile == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheTimeout;
  }

  static void setCache(Map<String, dynamic> profile) {
    _cachedProfile = profile;
    _lastFetch = DateTime.now();
  }

  static Map<String, dynamic>? getCache() => _cachedProfile;

  static void clearCache() {
    _cachedProfile = null;
    _lastFetch = null;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // App.tsx의 renderContent() 로직
  final List<Widget> _screens = [
    const NewsListScreen(),        // 'news'
    const CommunityScreen(),       // 'community'
    const NewsReaderScreen(),      // 'hot' (틴더 카드)
    const BookmarksScreen(),       // 'bookmarks'
    const ProfileScreen(),         // 'profile'
  ];

  @override
  void initState() {
    super.initState();
    // 🔥 프로필 체크 및 팝업 표시
    _checkProfileAndShowPopup();
  }

  /// 프로필 체크: NULL이면 프로필 설정 화면으로, 아니면 팝업 표시
  Future<void> _checkProfileAndShowPopup() async {
    try {
      debugPrint('🔵 홈 화면: 프로필 체크 시작');

      final profileService = ProfileService();
      final data = await profileService.getMyProfile();

      // 프로필 캐시에 저장
      ProfileCache.setCache(data);

      final userMap = data['user'] as Map<String, dynamic>?;
      final nickname = userMap?['nickname'] as String?;

      if (!mounted) return;

      // 닉네임이 NULL이면 프로필 설정 화면으로 이동
      if (nickname == null || nickname.trim().isEmpty) {
        debugPrint('⚠️ 닉네임 없음 -> 프로필 설정 화면으로 이동');

        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );

        // 프로필 설정 완료 후 돌아왔을 때 팝업 표시
        if (result == true && mounted) {
          debugPrint('✅ 프로필 설정 완료 -> 팝업 표시 예약');
          // 약간의 딜레이를 주어 화면 전환이 완료된 후 팝업 표시
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showNewsRecommendationPopup();
            }
          });
        }
      } else {
        // 프로필이 있으면 팝업 표시 (한 번만)
        debugPrint('✅ 프로필 존재: $nickname -> 팝업 체크');
        _showNewsRecommendationPopup();
      }
    } catch (e) {
      debugPrint('❌ 프로필 체크 실패: $e');
      // 에러 발생 시 프로필 설정 화면으로 이동
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );

        if (result == true && mounted) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showNewsRecommendationPopup();
            }
          });
        }
      }
    }
  }

  /// 뉴스 추천 팝업 표시 (한 번만)
  Future<void> _showNewsRecommendationPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPopup = prefs.getBool('has_seen_news_recommendation_popup') ?? false;

    debugPrint('🔍 팝업 체크: hasSeenPopup=$hasSeenPopup');

    if (!hasSeenPopup) {
      debugPrint('✅ 팝업 표시 조건 만족! 팝업을 띄웁니다.');

      // 화면 로드 후 팝업 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showNewsRecommendPopup(context);
            // 팝업이 표시된 후에 플래그 저장
            prefs.setBool('has_seen_news_recommendation_popup', true);
            debugPrint('✅ 팝업 표시 완료 및 플래그 저장');
          }
        });
      });
    } else {
      debugPrint('❌ 이미 팝업을 본 적이 있음');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: 모든 화면을 메모리에 유지 (상태 보존)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // BottomNavigation.tsx 변환
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
