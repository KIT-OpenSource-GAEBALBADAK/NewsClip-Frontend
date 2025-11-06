# 구글 소셜 로그인 설정 가이드

## ✅ 구현 완료 사항

### 1. 코드 구현
- ✅ `GoogleAuthService` 클래스 구현 완료
- ✅ 로그인 화면에 구글 로그인 버튼 연결 완료
- ✅ 백엔드 API 연동 완료 (`AuthService.socialLogin()`)

### 2. 동작 플로우
```
1. 사용자가 "Google로 계속하기" 버튼 클릭
2. Google Sign In 화면 표시 (구글 계정 선택)
3. 사용자 인증 후 ID Token 발급
4. ID Token을 백엔드로 전송 (POST /auth/social)
5. 백엔드에서 Access Token & Refresh Token 발급
6. 토큰을 로컬 저장소에 저장
7. 홈 화면으로 자동 이동
```

## 🔧 추가 설정 필요 사항

### 1. Google Cloud Console 설정

#### Android 앱 설정
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. "API 및 서비스" → "사용자 인증 정보" 이동
4. "OAuth 2.0 클라이언트 ID" 생성
5. 애플리케이션 유형: **Android** 선택
6. 패키지 이름 입력: `com.example.newclip1` (현재 앱 ID)
7. SHA-1 인증서 지문 입력 (아래 명령어로 확인)

#### SHA-1 인증서 지문 얻기

**Debug 키 (개발용):**
```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Mac/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release 키 (배포용):**
```bash
keytool -list -v -keystore [릴리즈 키스토어 경로] -alias [앨리어스]
```

#### Web 클라이언트 ID도 생성 (선택사항)
- Google Sign In에서 ID Token을 받기 위해 Web 클라이언트 ID가 필요할 수 있습니다
- 애플리케이션 유형: **웹 애플리케이션** 선택

### 2. Android 설정 파일

#### `android/app/build.gradle.kts`
현재 설정은 정상입니다. 추가 설정 불필요.

#### `android/app/src/main/AndroidManifest.xml`
인터넷 권한이 이미 있는지 확인:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. Google OAuth 인증 정보 사용 위치

#### ❌ 클라이언트 보안 비밀번호 (Client Secret)
- **사용하지 않음**: Flutter 앱에는 등록하지 않습니다
- **사용처**: 백엔드 서버에서만 사용 (서버-to-서버 인증)
- **보안**: 클라이언트 앱에 노출되면 안 되는 정보

#### ✅ Android OAuth 클라이언트 ID
- **자동 사용**: SHA-1 + 패키지 이름으로 자동 인증
- **등록 불필요**: 코드에 명시적으로 등록할 필요 없음
- Google Cloud Console에서 Android 앱 설정만 완료하면 됨

#### ⚠️ Web 클라이언트 ID (필요한 경우만)
ID Token을 받지 못하는 경우, `GoogleAuthService`에 Web 클라이언트 ID를 추가하세요:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
  ],
  // Web 클라이언트 ID (Google Cloud Console에서 "웹 애플리케이션"으로 생성)
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

**언제 필요한가요?**
- ID Token을 받지 못하는 경우
- "PlatformException: sign_in_failed" 에러가 발생하는 경우
- 백엔드에서 특정 클라이언트 ID를 요구하는 경우

## 🧪 테스트 방법

### 1. 개발 환경에서 테스트
```bash
flutter pub get
flutter run
```

### 2. 로그 확인
```dart
// 로그인 과정에서 다음과 같은 로그가 출력됩니다:
🔵 구글 로그인 시작
✅ 구글 계정 선택 완료: user@gmail.com
✅ 구글 ID Token 발급 성공
🔑 ID Token (앞 50자): ...
🔵 소셜 로그인 요청 시작
✅ 응답 코드: 200
✅ 백엔드 소셜 로그인 성공
```

### 3. 에러 처리
- 사용자가 로그인 취소 시: 아무 동작 없음
- ID Token 발급 실패: 에러 메시지 표시
- 백엔드 API 실패: 에러 메시지 표시

## 📱 지원 플랫폼

- ✅ Android
- ✅ iOS (추가 설정 필요)
- ✅ Web (추가 설정 필요)

### iOS 추가 설정 (필요시)
`ios/Runner/Info.plist`에 다음 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## 🔐 보안 고려사항

1. **ID Token 검증**: 백엔드에서 반드시 ID Token을 검증해야 합니다
2. **HTTPS 사용**: 프로덕션 환경에서는 반드시 HTTPS 사용
3. **토큰 저장**: Access Token과 Refresh Token은 안전하게 저장됨 (SharedPreferences 사용)

## 📝 백엔드 API 요구사항

### POST /auth/social
**Request:**
```json
{
  "provider": "google",
  "token": "GOOGLE_ID_TOKEN_HERE"
}
```

**Response (성공):**
```json
{
  "status": "success",
  "data": {
    "accessToken": "JWT_ACCESS_TOKEN",
    "refreshToken": "JWT_REFRESH_TOKEN"
  }
}
```

## 🎯 다음 단계

1. Google Cloud Console에서 OAuth 2.0 클라이언트 ID 생성
2. SHA-1 인증서 지문 등록
3. 실제 디바이스 또는 에뮬레이터에서 테스트
4. 프로덕션 환경 설정 (Release 키 등록)

## 📞 문제 해결

### "PlatformException (sign_in_failed)" 에러
- SHA-1 인증서가 제대로 등록되었는지 확인
- Google Cloud Console에서 Android 앱 설정 확인
- 패키지 이름이 일치하는지 확인

### "ID Token을 받지 못했습니다" 에러
- Web 클라이언트 ID 추가 생성 필요
- GoogleSignIn 초기화 시 serverClientId 설정

### 백엔드 연동 실패
- 백엔드 API 엔드포인트 확인 (`https://newsclip.duckdns.org/v1/auth/social`)
- ID Token이 제대로 전송되는지 확인
- 백엔드에서 구글 ID Token 검증 로직 확인

