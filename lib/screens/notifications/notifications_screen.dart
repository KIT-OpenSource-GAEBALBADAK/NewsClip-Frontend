// components/NotificationCenter.tsx 변환
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: AppColors.primaryStart),
            const SizedBox(height: 16),
            const Text('알림 센터'),
            const Text('(NotificationCenter.tsx 구현 필요)', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
