import 'dart:math' as math;
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // ===== Design Colors (기존 디자인 시스템 유지) =====
  static const Color _gradientStart = Color(0xFF8B5CF6); // 보라
  static const Color _gradientEnd = Color(0xFFEC4899);   // 핑크
  static const Color _textTitle = Color(0xFF0A0A0A);
  static const Color _textBody = Color(0xFF4B5563);
  static const Color _textSub = Color(0xFF9CA3AF);
  static const Color _bgSection = Color(0xFFF9FAFB);     // 섹션 배경색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header (고정) =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. 뒤로가기 버튼
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  // 2. 우측 그라데이션 아이콘 (방패 모양)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_gradientStart, _gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user_outlined, // 방패 아이콘
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Content (스크롤 가능) =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이틀
                    const Text(
                      '개인정보 처리방침',
                      style: TextStyle(
                        color: _textTitle,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '최종 수정일: 2025년 12월 09일',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 약관 내용 시작
                    _buildSection(
                      index: '1',
                      title: '총칙',
                      content:
                      '본 서비스는 회원의 개인정보보호를 매우 중요시하며, 『개인정보보호법』 등 관련 법령을 준수하고 있습니다. 본 방침은 회사가 어떤 정보를 수집하고, 수집한 정보를 어떻게 사용하며, 필요 시 어떻게 변경하는지 알려드립니다.',
                    ),
                    _buildSection(
                      index: '2',
                      title: '수집하는 개인정보의 항목',
                      content:
                      '회사는 회원가입, 원활한 고객상담, 서비스 신청 등을 위해 아래와 같은 개인정보를 수집하고 있습니다.\n\n'
                          '• 필수항목: 이메일 주소, 비밀번호, 닉네임\n'
                          '• 선택항목: 프로필 사진, 자기소개\n'
                          '• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, 접속 IP 정보',
                    ),
                    _buildSection(
                      index: '3',
                      title: '개인정보의 수집 및 이용목적',
                      content:
                      '수집한 개인정보를 다음의 목적을 위해 활용합니다.\n\n'
                          '1. 서비스 제공에 관한 계약 이행 및 서비스 제공에 따른 요금정산\n'
                          '2. 회원 관리 (본인확인, 개인식별, 불량회원의 부정이용 방지)\n'
                          '3. 신규 서비스 개발 및 마케팅 활용',
                    ),
                    _buildSection(
                      index: '4',
                      title: '개인정보의 보유 및 이용기간',
                      content:
                      '원칙적으로 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 일정 기간 동안 정보를 보관합니다.',
                    ),
                    _buildSection(
                      index: '5',
                      title: '개인정보 파기절차 및 방법',
                      content:
                      '회사는 원칙적으로 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 파기절차 및 방법은 다음과 같습니다.\n\n'
                          '• 파기절차: 회원탈퇴 등 목적이 달성된 후 내부 방침 및 기타 관련 법령에 의한 정보보호 사유에 따라 일정 기간 저장된 후 파기됩니다.\n'
                          '• 파기방법: 전자적 파일 형태로 저장된 개인정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제합니다.',
                    ),
                    _buildSection(
                      index: '6',
                      title: '문의처',
                      content:
                      '개인정보 관련 문의사항이 있으신 경우 아래 연락처로 문의 주시면 신속하게 답변 드리겠습니다.\n\n'
                          '• 이메일: thisis@notreal.com\n'
                          '• 고객센터: 0000-0000',
                    ),

                    const SizedBox(height: 40),

                    // 하단 푸터 느낌
                    Center(
                      child: Text(
                        'NewsClip App',
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.3),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 약관 섹션 위젯 빌더
  Widget _buildSection({required String index, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  index,
                  style: const TextStyle(
                    color: _gradientStart,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgSection,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: _textBody,
                fontSize: 14,
                height: 1.6, // 가독성을 위한 줄간격
              ),
            ),
          ),
        ],
      ),
    );
  }
}