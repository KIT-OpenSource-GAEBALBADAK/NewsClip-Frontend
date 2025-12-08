// App.tsx (AppContent의 렌더링 로직) 변환
import 'package:flutter/material.dart';

import 'news/news_list_screen.dart';
import 'news/news_tinder_screen.dart';
import 'community/community_screen.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/common/bottom_navigation.dart';

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
