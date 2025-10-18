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
| Target | Android / iOS / Web |

---

## 📂 디렉토리 구조 (구조와 파일명은 개발 진행중 달라질 수 있음)
### 하위 파일명들은 예시 입니다.
```
lib/
├── app.dart                        # 앱 초기 설정 및 MaterialApp 구성
├── main.dart                       # 앱 진입점 (runApp)
│
├── core/                           # 공통 리소스 및 환경 관련 코드
│   ├── constants/                  # 전역 상수 (API URL, 색상 등)
│   ├── theme/                      # 라이트 / 다크 테마
│   └── utils/                      # 공통 유틸리티 (포맷터 등)
│
├── models/                         # 데이터 모델 (DTO)
│   ├── news_article.dart
│   ├── notification.dart
│   ├── user.dart
│   └── comment.dart
│
├── providers/                      # 상태관리 (Provider)
│   ├── app_provider.dart
│   ├── auth_provider.dart
│   ├── news_provider.dart
│   ├── community_provider.dart
│   ├── bookmark_provider.dart
│   └── profile_provider.dart
│
├── screens/                        # UI (기능별 화면)
│   ├── home_screen.dart
│   ├── login/
│   ├── news/
│   ├── community/
│   ├── bookmarks/
│   ├── notifications/
│   └── profile/
│
├── services/                       # API 통신 (Dio 기반)
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── news_service.dart
│   ├── community_service.dart
│   ├── profile_service.dart
│   └── notification_service.dart
│
└── widgets/                        # 공통 위젯
    ├── common/
    │   ├── bottom_navigation.dart
    │   ├── custom_appbar.dart
    │   ├── loading_indicator.dart
    │   └── empty_state.dart
    ├── news/
    ├── community/
    └── profile/
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
