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

## 📂 디렉토리 구조
### 하위 파일명들은 예시 입니다.
```
📦 lib
├── 📂 core                      # 앱 전반에서 사용되는 공통 리소스
│   ├── 📂 constants             # 상수 (색상, 치수, 텍스트 스타일)
│   ├── 📂 theme                 # 테마 설정 (다크/라이트 모드)
│   └── 📂 utils                 # 유틸리티 (유효성 검사 등)
│
├── 📂 models                    # 데이터 모델 (DTO)
│   ├── 📄 user.dart
│   ├── 📄 news_item.dart
│   ├── 📄 community.dart
│   ├── 📄 comment.dart
│   └── ... (기타 데이터 모델)
│
├── 📂 providers                 # 상태 관리 (Provider)
│   └── 📄 app_provider.dart     # 전역 앱 상태 관리
│
├── 📂 screens                   # UI 화면 (기능별 분류)
│   ├── 📂 bookmarks             # 북마크 화면
│   ├── 📂 community             # 커뮤니티 (생성, 목록, 시트)
│   ├── 📂 login                 # 인증 (로그인, 회원가입, 비밀번호 찾기)
│   ├── 📂 news                  # 뉴스 (목록, 리더, 틴더 UI)
│   ├── 📂 notifications         # 알림 화면
│   ├── 📂 profile               # 프로필 (설정, 수정, 카테고리 변경)
│   └── 📄 home_screen.dart      # 메인 홈 화면
│
├── 📂 services                  # API 통신 및 비즈니스 로직
│   ├── 📄 dio_service.dart      # HTTP 클라이언트 설정
│   ├── 📄 auth_service.dart     # 일반 인증 로직
│   ├── 📄 google_auth_service.dart
│   ├── 📄 kakao_auth_service.dart
│   ├── 📄 news_list_service.dart
│   ├── 📄 news_tinder_service.dart
│   └── ... (기능별 서비스)
│
├── 📂 widgets                   # 재사용 가능한 공통 위젯
│   ├── 📂 common
│   │   ├── 📄 bottom_navigation.dart
│   │   └── 📄 news_recommend_popup.dart
│   └── ...
│
├── 📄 app.dart                  # 앱 초기 설정 (MaterialApp)
└── 📄 main.dart                 # 앱 진입점 (Entry Point)
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

## 🚀 프로젝트 실행법

### 1. Prerequisites
이 프로젝트를 실행하려면 [Flutter SDK](https://flutter.dev/docs/get-started/install)가 설치되어 있어야 합니다.

### 2. Installation
프로젝트를 클론하고 의존성 패키지를 설치합니다.

```bash
# Clone the repository
git clone https://github.com/KIT-OpenSource-GAEBALBADAK/NewsClip-Frontend.git

# Navigate to project folder
cd NewsClip-Frontend

# Install dependencies (필수!)
flutter pub get
