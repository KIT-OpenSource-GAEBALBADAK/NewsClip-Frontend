import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        elevation: 0,
      ),
      body: const Center(
        child: Text('비밀번호 찾기 화면'),
      ),
    );
  }
}