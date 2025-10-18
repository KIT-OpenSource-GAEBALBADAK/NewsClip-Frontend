# React → Flutter 파일 매핑표

## ✅ 생성 완료된 파일 (23개)

### 설정 파일 (3개)
- ✅ `pubspec.yaml` ← package.json
- ✅ `analysis_options.yaml` ← (신규)
- ✅ `README.md`

### Core (7개)
- ✅ `lib/core/constants/app_colors.dart` ← styles/globals.css (색상)
- ✅ `lib/core/constants/app_text_styles.dart` ← styles/globals.css (타이포그래피)
- ✅ `lib/core/constants/app_dimensions.dart` ← styles/globals.css (간격)
- ✅ `lib/core/theme/light_theme.dart` ← styles/globals.css (:root)
- ✅ `lib/core/theme/dark_theme.dart` ← styles/globals.css (.dark)

### Models (3개)
- ✅ `lib/models/news_article.dart` ← AppContext.tsx (NewsArticle)
- ✅ `lib/models/user.dart` ← AppContext.tsx (User)
- ✅ `lib/models/notification.dart` ← AppContext.tsx (Notification)

### State & Entry (4개)
- ✅ `lib/main.dart` ← App.tsx (main)
- ✅ `lib/app.dart` ← App.tsx (MaterialApp)
- ✅ `lib/providers/app_provider.dart` ← AppContext.tsx
- ✅ `lib/screens/home_screen.dart` ← App.tsx (AppContent)

### Screens (7개)
- ✅ `lib/screens/login/login_screen.dart` ← LoginScreen.tsx
- ✅ `lib/screens/news/news_list_screen.dart` ← NewsList.tsx (placeholder)
- ✅ `lib/screens/news/news_reader_screen.dart` ← NewsReader.tsx (HOT 탭 - 틴더 카드)
- ✅ `lib/screens/community/community_screen.dart` ← CommunityFeedWithWrite.tsx (placeholder)
- ✅ `lib/screens/profile/profile_screen.dart` ← ProfileScreen.tsx
- ✅ `lib/screens/bookmarks/bookmarks_screen.dart` ← BookmarkedNewsScreen.tsx (placeholder)
- ✅ `lib/screens/notifications/notifications_screen.dart` ← NotificationCenter.tsx (placeholder)

### Widgets (1개)
- ✅ `lib/widgets/common/bottom_navigation.dart` ← BottomNavigation.tsx

---

## ⏳ 구현 필요한 파일 (38개)

### Services (3개)
- ⏳ `lib/services/local_storage_service.dart` ← AppContext.tsx (localStorage)
- ⏳ `lib/services/auth_service.dart` ← AppContext.tsx (login/logout)
- ⏳ `lib/services/api_service.dart` ← (신규)

### Common Widgets (5개)
- ⏳ `lib/widgets/common/custom_header.dart` ← Header.tsx
- ⏳ `lib/widgets/common/slide_notification.dart` ← SlideNotification.tsx
- ⏳ `lib/widgets/common/hot_logo.dart` ← HotLogo.tsx
- ⏳ `lib/widgets/common/bookmark_button.dart` ← BookmarkButton.tsx
- ⏳ `lib/widgets/common/image_with_fallback.dart` ← figma/ImageWithFallback.tsx

### News Widgets (3개)
- ⏳ `lib/widgets/news/swipe_news_card.dart` ← NewsReader.tsx (카드)
- ⏳ `lib/widgets/news/news_list_item.dart` ← NewsList.tsx (아이템)
- ⏳ `lib/widgets/news/news_category_chip.dart` ← (신규)

### Community Widgets (6개)
- ⏳ `lib/widgets/community/community_feed.dart` ← CommunityFeed.tsx
- ⏳ `lib/widgets/community/write_post.dart` ← WritePost.tsx
- ⏳ `lib/widgets/community/comment_sheet.dart` ← CommentSheet.tsx
- ⏳ `lib/widgets/community/comments_modal.dart` ← CommentsModal.tsx
- ⏳ `lib/widgets/community/comment_item.dart` ← (신규)
- ⏳ `lib/widgets/community/post_card.dart` ← (신규)

### Custom UI (3개)
- ⏳ `lib/ui/custom_badge.dart` ← ui/badge.tsx
- ⏳ `lib/ui/custom_button.dart` ← ui/button.tsx
- ⏳ `lib/ui/alert_banner.dart` ← ui/alert.tsx

### Models (3개)
- ⏳ `lib/models/comment.dart` ← (신규)
- ⏳ `lib/models/post.dart` ← (신규)
- ⏳ `lib/models/slide_notification_data.dart` ← SlideNotification.tsx

### Utils (2개)
- ⏳ `lib/core/utils/date_formatter.dart` ← (신규)
- ⏳ `lib/core/utils/validators.dart` ← (신규)

### 화면 완전 구현 (7개)
- ⏳ NewsList.tsx → news_list_screen.dart (완전 구현)
- ⏳ NewsReader.tsx → news_reader_screen.dart (완전 구현)
- ⏳ CommunityFeedWithWrite.tsx → community_screen.dart (완전 구현)
- ⏳ PlaceholderScreen.tsx → shorts_screen.dart (완전 구현)
- ⏳ BookmarkedNewsScreen.tsx → bookmarks_screen.dart (완전 구현)
- ⏳ NotificationCenter.tsx → notifications_screen.dart (완전 구현)

### Assets (9개 폰트 파일)
- ⏳ `assets/fonts/Pretendard-Thin.otf`
- ⏳ `assets/fonts/Pretendard-ExtraLight.otf`
- ⏳ `assets/fonts/Pretendard-Light.otf`
- ⏳ `assets/fonts/Pretendard-Regular.otf`
- ⏳ `assets/fonts/Pretendard-Medium.otf`
- ⏳ `assets/fonts/Pretendard-SemiBold.otf`
- ⏳ `assets/fonts/Pretendard-Bold.otf`
- ⏳ `assets/fonts/Pretendard-ExtraBold.otf`
- ⏳ `assets/fonts/Pretendard-Black.otf`

---

## 📊 진행 상황

| 카테고리 | 완료 | 전체 | 진행률 |
|---------|------|------|--------|
| 설정 파일 | 3 | 3 | 100% |
| Core | 5 | 7 | 71% |
| Models | 3 | 6 | 50% |
| State & Entry | 4 | 4 | 100% |
| Screens | 8 | 8 | 100% (placeholder) |
| Widgets | 1 | 15 | 7% |
| Services | 0 | 3 | 0% |
| UI | 0 | 3 | 0% |
| Assets | 0 | 9 | 0% |
| **총합** | **24** | **58** | **41%** |

---

## 🎯 현재 상태

### ✅ 실행 가능 (로그인 → 홈 → 각 탭 placeholder)
```bash
cd flutter
flutter pub get
flutter run
```

### 🔥 핵심 기능 동작
- ✅ 로그인 화면 (카카오/구글)
- ✅ 로그인 상태 관리
- ✅ 하단 네비게이션 (5개 탭: 뉴스/커뮤니티/HOT/북마크/프로필)
- ✅ 화면 전환
- ✅ 다크모드 저장 (Provider)
- ✅ 프로필 화면
- ✅ 로그아웃

### 📱 5개 탭 구조 (React 원본과 동일)
1. **뉴스** - 뉴스 리스트
2. **커뮤니티** - 커뮤니티 피드
3. **HOT** - 틴더 스타일 카드 스와이프 (NewsReader)
4. **북마크** - 저장한 뉴스
5. **프로필** - 사용자 프로필

### ⏳ 구현 필요
- NewsList.tsx의 뉴스 리스트 UI
- NewsReader.tsx의 틴더 카드 스와이프
- CommunityFeed의 게시물 리스트
- 댓글 기능
- 북마크 기능
- 알림 시스템

---

## 🚀 다음 단계

1. **Pretendard 폰트 다운로드 및 배치**
   - https://github.com/orioncactus/pretendard/releases
   - `flutter/assets/fonts/` 폴더에 복사

2. **화면 완전 구현**
   - NewsList.tsx → news_list_screen.dart
   - NewsReader.tsx → news_reader_screen.dart
   - CommunityFeedWithWrite.tsx → community_screen.dart

3. **위젯 구현**
   - swipe_news_card.dart (flutter_card_swiper 사용)
   - news_list_item.dart
   - comment_sheet.dart

4. **서비스 구현**
   - local_storage_service.dart
   - auth_service.dart (실제 소셜 로그인 SDK)

---

모든 파일 매핑은 `/FLUTTER_FILE_STRUCTURE.md` 참조
