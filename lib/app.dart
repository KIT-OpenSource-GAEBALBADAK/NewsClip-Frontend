// App.tsx 변환 (MaterialApp 설정)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'providers/app_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

// StatelessWidget을 StatefulWidget으로 변경
class NewsClipApp extends StatefulWidget {
  const NewsClipApp({Key? key}) : super(key: key);

  @override
  State<NewsClipApp> createState() => _NewsClipAppState();
}

class _NewsClipAppState extends State<NewsClipApp> {
  // Future를 State의 멤버 변수로 선언
  late final Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    // initState에서 Future를 단 한 번만 생성하여 할당
    _isLoggedInFuture = AuthService().isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'NewsClip',
          debugShowCheckedModeBanner: false,
          
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // FutureBuilder가 State의 Future 변수를 사용하도록 수정
          home: FutureBuilder<bool>(
            future: _isLoggedInFuture,
            builder: (context, snapshot) {
              // 로딩 중
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // 토큰이 있으면 홈 화면, 없으면 로그인 화면
              final isLoggedIn = snapshot.data ?? false;
              return isLoggedIn ? const HomeScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
