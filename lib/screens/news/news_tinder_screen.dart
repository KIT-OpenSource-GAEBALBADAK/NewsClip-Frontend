// components/NewsReader.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NewsReaderScreen extends StatefulWidget {
  const NewsReaderScreen({Key? key}) : super(key: key);

  @override
  State<NewsReaderScreen> createState() => _NewsReaderScreenState();
}

class _NewsReaderScreenState extends State<NewsReaderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HOT Logo
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.local_fire_department, size: 48, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'HOT',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('틴더 스타일 카드 화면'),
              const Text('(NewsReader.tsx 구현 필요)', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              const Text('flutter_card_swiper 패키지 사용', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
