// components/BookmarkedNewsScreen.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark, size: 64, color: AppColors.primaryStart),
            const SizedBox(height: 16),
            const Text('북마크 화면'),
            const Text('(BookmarkedNewsScreen.tsx 구현 필요)', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
