// components/CommunityFeedWithWrite.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: AppColors.primaryStart),
            const SizedBox(height: 16),
            const Text('커뮤니티 화면'),
            const Text('(CommunityFeedWithWrite.tsx 구현 필요)', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글쓰기 화면
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
