// components/AppContext.tsx 변환
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_article.dart';
import '../models/user.dart';
import '../models/notification.dart';

class AppProvider with ChangeNotifier {
  // Dark Mode
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  
  // Bookmarks
  List<NewsArticle> _bookmarkedNews = [];
  List<NewsArticle> get bookmarkedNews => _bookmarkedNews;
  
  // Notifications
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  // Auth
  bool _isLoggedIn = false;
  User? _user;
  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  
  AppProvider() {
    _loadPreferences();
    _loadNotifications();
  }
  
  // ==================== Dark Mode ====================
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    
    // Load login state
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    notifyListeners();
  }
  
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }
  
  // ==================== Bookmarks ====================
  Future<void> addBookmark(NewsArticle news) async {
    if (_bookmarkedNews.any((b) => b.id == news.id)) return;
    
    _bookmarkedNews.add(news);
    await _saveBookmarks();
    notifyListeners();
  }
  
  Future<void> removeBookmark(String newsId) async {
    _bookmarkedNews.removeWhere((n) => n.id == newsId);
    await _saveBookmarks();
    notifyListeners();
  }
  
  bool isBookmarked(String newsId) {
    return _bookmarkedNews.any((n) => n.id == newsId);
  }
  
  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: JSON 직렬화 구현
  }
  
  // ==================== Notifications ====================
  void _loadNotifications() {
    // Mock notifications (AppContext.tsx의 initialNotifications)
    _notifications = [
      NotificationModel(
        id: '1',
        type: NotificationType.comment,
        title: '새로운 댓글',
        content: '김전문가님이 댓글을 남겼습니다',
        timestamp: '5분 전',
        isRead: false,
      ),
      // ... 더 추가 가능
    ];
  }
  
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
  
  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }
  
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
  
  // ==================== Authentication ====================
  Future<void> login(String provider) async {
    // Mock login (AppContext.tsx의 login 함수)
    _user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '$provider 사용자',
      email: 'user@$provider.com',
      provider: provider,
    );
    _isLoggedIn = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    
    notifyListeners();
  }

  Future<void> setLoggedInFromEmail(String email) async {
    _user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: email.split('@').first,
      email: email,
      provider: 'local',
    );
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    // await prefs.setString('user', jsonEncode({
    //   'id': _user!.id,
    //   'name': _user!.name,
    //   'email': _user!.email,
    //   'provider': _user!.provider,
    // }));

    notifyListeners();
  }
  
  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user');
    
    notifyListeners();
  }
}
