# Flutter NewsClip - 빠른 시작 가이드

## 🎯 현재 상태

React 웹 앱을 Flutter로 변환 중입니다.

### ✅ 완료 (41%)
- 프로젝트 설정 (pubspec.yaml)
- 테마 & 색상 시스템
- 로그인 화면
- 하단 네비게이션
- 화면 전환
- 상태 관리 (Provider)

### ⏳ 구현 필요 (59%)
- 뉴스 리스트 UI
- 틴더 카드 스와이프
- 커뮤니티 피드
- 댓글 시스템
- 실제 데이터 로딩

---

## 🚀 실행 방법

### 1. 폰트 설치

```bash
# 1. Pretendard 폰트 다운로드
# https://github.com/orioncactus/pretendard/releases

# 2. OTF 파일 9개를 flutter/assets/fonts/ 폴더에 복사
```

### 2. 의존성 설치

```bash
cd flutter
flutter pub get
```

### 3. 실행

```bash
# Android/iOS 시뮬레이터 실행
flutter run

# 또는 특정 디바이스 지정
flutter devices
flutter run -d <device-id>
```

---

## 📱 현재 동작하는 기능

### 로그인
1. 앱 실행
2. "카카오로 계속하기" 또는 "Google로 계속하기" 클릭
3. 자동 로그인 (Mock)

### 하단 네비게이션 (React 원본과 동일)
- **뉴스**: 뉴스 리스트 (placeholder)
- **커뮤니티**: 커뮤니티 피드 (placeholder)
- **HOT**: 틴더 스타일 카드 스와이프 (placeholder)
- **북마크**: 저장한 뉴스 목록 (placeholder)
- **프로필**: 프로필 정보 + 로그아웃

---

## 📂 파일 구조

```
flutter/
├── pubspec.yaml                 # 패키지 설정
├── lib/
│   ├── main.dart                # 엔트리포인트
│   ├── app.dart                 # MaterialApp
│   ├── core/                    # 테마, 색상, 상수
│   ├── models/                  # 데이터 모델
│   ├── providers/               # 상태 관리
│   ├── screens/                 # 화면 (8개)
│   └── widgets/                 # 위젯
└── assets/
    └── fonts/                   # Pretendard 폰트
```

---

## 🔄 React → Flutter 매핑

| React | Flutter | 상태 |
|-------|---------|------|
| App.tsx | main.dart + app.dart + home_screen.dart | ✅ |
| AppContext.tsx | app_provider.dart | ✅ |
| BottomNavigation.tsx | bottom_navigation.dart | ✅ |
| LoginScreen.tsx | login_screen.dart | ✅ |
| ProfileScreen.tsx | profile_screen.dart | ✅ |
| NewsList.tsx | news_list_screen.dart | ⏳ |
| NewsReader.tsx (HOT) | news_reader_screen.dart | ⏳ |
| CommunityFeedWithWrite.tsx | community_screen.dart | ⏳ |
| BookmarkedNewsScreen.tsx | bookmarks_screen.dart | ⏳ |

전체 매핑: `FILE_MAPPING.md` 참조

---

## 🛠️ 다음 작업

### 우선순위 1: 핵심 화면 구현
1. `screens/news/news_list_screen.dart` - 뉴스 리스트
2. `screens/news/news_reader_screen.dart` - 틴더 카드
3. `screens/community/community_screen.dart` - 커뮤니티

### 우선순위 2: 위젯 구현
1. `widgets/news/news_list_item.dart` - 뉴스 카드
2. `widgets/news/swipe_news_card.dart` - 스와이프 카드
3. `widgets/community/comment_sheet.dart` - 댓글

### 우선순위 3: 서비스
1. `services/local_storage_service.dart` - 로컬 저장
2. `services/auth_service.dart` - 실제 소셜 로그인
3. `services/api_service.dart` - API 호출

---

## ⚡ 문제 해결

### 폰트가 안 보여요
```bash
# assets/fonts/ 폴더에 Pretendard 폰트 9개 파일 확인
# pubspec.yaml에 fonts 섹션 확인
flutter clean
flutter pub get
```

### Hot Reload가 안 돼요
```bash
# 터미널에서 'r' 입력
r

# 또는 전체 재시작
R
```

### 패키지 에러
```bash
flutter pub get
flutter pub upgrade
```

---

## 📚 참고

- React 원본: `../` (상위 폴더)
- 매핑 가이드: `FILE_MAPPING.md`
- Flutter 문서: https://docs.flutter.dev/

---

**질문이 있으면 FILE_MAPPING.md와 원본 React 코드를 비교하세요!**
