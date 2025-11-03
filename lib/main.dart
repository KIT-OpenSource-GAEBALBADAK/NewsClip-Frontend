// App.tsx 변환 (main 엔트리포인트)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'providers/app_provider.dart';

import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 투명 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 세로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    String keyHash = await KakaoSdk.origin;
    print('=============================================');
    print('🔑 KAKAO KEY HASH: $keyHash');
    print('=============================================');
  } catch (e) {
    print('Key hash retrieval failed: $e');
  }

  KakaoSdk.init(
    nativeAppKey: '25c7ef75b2b00474bc1603a180884255', // TODO: 카카오 네이티브 앱 키로 교체
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const NewsClipApp(),
    ),
  );
}
