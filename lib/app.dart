// App.tsx 변환 (MaterialApp 설정)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'providers/app_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/home_screen.dart';

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
          
          // 첫 화면: 로그인 상태에 따라 분기
          home: appProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
