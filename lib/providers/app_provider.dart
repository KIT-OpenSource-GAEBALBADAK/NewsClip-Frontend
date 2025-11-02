// components/AppContext.tsx 변환
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_article.dart';
import '../models/notification.dart';

/// 앱의 전역 상태를 관리하는 Provider
/// - 다크모드
/// - 북마크
/// - 알림
/// (로그인 상태는 AuthService에서 관리)
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

  AppProvider() {
    _loadPreferences();
    _loadNotifications();
  }

  // ==================== Dark Mode ====================
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
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
}

