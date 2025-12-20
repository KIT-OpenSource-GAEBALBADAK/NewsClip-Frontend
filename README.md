# 🚀 개요

이 레포지토리는 **NewsClip 서비스의 Flutter 프론트엔드 애플리케이션**입니다.  
사용자는 뉴스 요약, 북마크, 커뮤니티, 알림 기능 등을 이용할 수 있으며,  
백엔드(`Go Gin API`)와 통신하여 데이터를 실시간으로 주고받습니다.

---

## ⚙️ 개발 환경

> **Flutter와 Dart 버전은 수업자료에 명시된 버전을 사용합니다.**

| 항목 | 내용 |
|------|------|
| Flutter SDK | 3.35.3 |
| Dart SDK | 3.9.2 |
| IDE | VS Code / Android Studio |
| Target | Android / iOS |

---

## 📂 디렉토리 구조
### 하위 파일명들은 예시 입니다.
```
📦 NewsClip-Frontend
├── .dart_tool/                        # 다트 빌드 도구 및 캐시
├── .idea/                             # 개발 환경(IDE) 설정 파일
├── android/                           # 안드로이드 플랫폼 소스 코드
├── assets/                            # 이미지, 폰트 등 정적 리소스
├── build/                             # 프로젝트 빌드 결과물
├── ios/                               # iOS 플랫폼 소스 코드
├── linux/                             # 리눅스 플랫폼 소스 코드
├── macos/                             # macOS 플랫폼 소스 코드
├── web/                               # 웹 플랫폼 소스 코드
├── windows/                           # 윈도우 플랫폼 소스 코드
│
├── lib/                               # 🚀 핵심 소스 코드
│   ├── core/                          # 앱 공통 리소스 및 설정
│   │   ├── constants/                 # 공통 상수 (색상, 치수, 텍스트 스타일)
│   │   │   ├── app_colors.dart
│   │   │   ├── app_dimensions.dart
│   │   │   └── app_text_styles.dart
│   │   ├── theme/                     # 다크/라이트 모드 테마 설정
│   │   │   ├── dark_theme.dart
│   │   │   └── light_theme.dart
│   │   └── utils/                     # 범용 유틸리티 (유효성 검사 등)
│   │       └── validators.dart
│   │
│   ├── models/                        # 데이터 구조 정의 (DTO)
│   │   ├── bookmark.dart
│   │   ├── comment.dart
│   │   ├── community.dart
│   │   ├── news_card.dart
│   │   ├── news_item.dart
│   │   ├── notification.dart
│   │   ├── profile_lists.dart
│   │   └── user.dart
│   │
│   ├── providers/                     # 전역 상태 관리 (Provider)
│   │   └── app_provider.dart
│   │
│   ├── screens/                       # 화면 UI 구성
│   │   ├── bookmarks/                 # 북마크 목록 화면
│   │   │   └── bookmarks_screen.dart
│   │   ├── community/                 # 커뮤니티(글쓰기, 목록, 시트) 화면
│   │   │   ├── community_create_screen.dart
│   │   │   ├── community_screen.dart
│   │   │   └── community_sheet.dart
│   │   ├── login/                     # 인증(로그인, 가입, 비번찾기) 관련 화면
│   │   │   ├── email_login_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── forgot_password_verify_code_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   ├── news/                      # 뉴스 관련 화면 (목록, 상세, 틴더UI)
│   │   │   ├── news_list_screen.dart
│   │   │   ├── news_reader_screen.dart
│   │   │   └── news_tinder_screen.dart
│   │   ├── notifications/             # 알림 목록 화면
│   │   │   └── notifications_screen.dart
│   │   ├── profile/                   # 사용자 프로필 및 개인 설정 화면
│   │   │   ├── category_change_screen.dart
│   │   │   ├── category_select_screen.dart
│   │   │   ├── change_password_screen.dart
│   │   │   ├── privacy_policy_screen.dart
│   │   │   ├── profile_change_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   └── home_screen.dart            # 메인 홈 화면
│   │
│   ├── services/                       # API 통신 및 외부 서비스 로직
│   │   ├── auth_service.dart
│   │   ├── bookmark_service.dart
│   │   ├── community_service.dart
│   │   ├── dio_service.dart            # HTTP 통신 설정
│   │   ├── google_auth_service.dart
│   │   ├── kakao_auth_service.dart
│   │   ├── news_list_service.dart
│   │   ├── news_tinder_service.dart
│   │   ├── profile_service.dart
│   │   └── user_service.dart
│   │
│   ├── widgets/                        # 재사용 가능한 UI 컴포넌트
│   │   ├── common/                     # 공통 위젯 (하단 바, 팝업 등)
│   │   │   ├── bottom_navigation.dart
│   │   │   └── news_recommend_popup.dart
│   │   └── app.dart                    # 최상위 MaterialApp 위젯
│   │
│   └── main.dart                       # 앱 진입점
│
├── .flutter-plugins-dependencies
├── .gitignore                          # Git 관리 제외 설정
├── .metadata                           # 플러그인 메타데이터
├── analysis_options.yaml               # 코드 분석 및 Lint 규칙
├── devtools_options.yaml               # 개발 도구 설정
├── FILE_MAPPING.md                     # 파일 매핑 설명 문서
├── flutter_launcher_icons.yaml         # 앱 아이콘 생성 설정
├── pubspec.lock                        # 패키지 버전 고정 정보
├── pubspec.yaml                        # 프로젝트 패키지 및 환경 설정
├── QUICKSTART.md                       # 프로젝트 빠른 실행 가이드
├── README.md                           # 프로젝트 메인 설명 파일
└── routes.json                         # 라우트 설정 정보
```

---

## 🧠 아키텍처 개요

```
UI (screens/widgets)
        ↓
ViewModel / Provider (providers)
        ↓
Repository / Service (services)
        ↓
REST API (Go Gin Backend)
        ↓
Database (PostgreSQL)
```

✅ **MVVM 구조 기반**
- `screens`: UI  
- `providers`: 상태 관리 및 비즈니스 로직  
- `services`: API 통신 및 데이터 처리  
- `models`: 데이터 구조 정의  

---

## 🌐 백엔드 연동

| 항목 | 내용 |
|------|------|
| Base URL | `https://newsclip.duckdns.org/v1` |
| Auth | JWT 기반 인증 |
| Data Format | JSON |
| 주요 연동 기능 | 로그인 / 뉴스 조회 / 커뮤니티 / 북마크 / 알림 |

---

## 🧠 플러터 실행 방법

### 1️⃣ 의존성 설치
```bash
flutter pub get
```

### 2️⃣ 플러터 실행
```bash
flutter run
```

---

## 🧩 주요 기능

| 페이지 | 기능 |
|------|------|
| **Login** | 회원가입, 로그인, 비밀번호 찾기 및 변경, 소셜 간편 로그인 |
| **NewsList** | 뉴스 본문 조회, 좋아요/싫어요 북마크 상호작용, 댓글 기능 |
| **NewsShorts** | 스와이프 형식의 뉴스 요약 카드, 댓글 기능, 각종 상호작용 |
| **Community** | 게시글 및 댓글 작성 조회, 전문가/일반 분리 |
| **Bookmark** | 북마크 뉴스 조회, 북마크 해제 |
| **Profile** |  프로필 초기 설정, 프로필 조회 및 변경, 내가 쓴 게시글 및 댓글 조회 |

---

## 🤝 협업 규칙

- **main 브랜치**: 안정화된 배포용 코드  
- **dev 브랜치**: 개발 통합용 (PR 머지 전 테스트 완료 필수)  
- **feature/** 브랜치: 각 기능 단위 (예: `feature/auth`, `feature/news`)  

PR 시에는 반드시 코드 리뷰를 요청합니다.
