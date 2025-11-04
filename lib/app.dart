// App.tsx 변환 (MaterialApp 설정)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'providers/app_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

class NewsClipApp extends StatelessWidget {
  const NewsClipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'NewsClip',
          debugShowCheckedModeBanner: false,
          
          // 테마 설정 (styles/globals.css 기반)
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // ✅ 첫 화면: AuthService의 토큰 기반으로 로그인 상태 확인
          home: FutureBuilder<bool>(
            future: AuthService().isLoggedIn(),
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
