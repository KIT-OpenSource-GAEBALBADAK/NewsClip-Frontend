import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/news_list_service.dart';
import '../screens/news/news_reader_screen.dart';

/// 팝업을 띄우는 함수 (이것만 호출하면 됩니다)
void showNewsRecommendPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(153), // 배경 어둡게 (0.6 * 255 = 153)
    builder: (context) => const NewsRecommendPopup(),
  );
}

class NewsRecommendPopup extends StatefulWidget {
  const NewsRecommendPopup({super.key});

  @override
  State<NewsRecommendPopup> createState() => _NewsRecommendPopupState();
}

class _NewsRecommendPopupState extends State<NewsRecommendPopup> {
  final NewsListService _newsService = NewsListService();
  List<Map<String, dynamic>> _newsList = [];
  bool _loading = true;
  String? _error;

  // ===== Design Tokens from JSON =====
  static const Color _primary = Color(0xFFA066FF);
  static const Color _textPrimary = Color(0xFF1A1A1C);
  static const Color _textTertiary = Color(0xFF9D9DA5);
  static const double _modalRadius = 28.0;

  @override
  void initState() {
    super.initState();
    _loadRecommendedNews();
  }

  Future<void> _loadRecommendedNews() async {
    try {
      debugPrint('🔵 추천 뉴스 API 호출 시작');
      final news = await _newsService.getRecommendedNews(count: 5);
      debugPrint('✅ 추천 뉴스 ${news.length}개 로드 성공');

      // 각 뉴스의 상세 정보를 조회하여 이미지 URL 가져오기
      final enrichedNews = <Map<String, dynamic>>[];

      for (var newsItem in news) {
        try {
          // newsId 또는 news_id 필드 확인
          final newsId = newsItem['newsId'] ?? newsItem['news_id'];

          if (newsId != null) {
            debugPrint('🔵 뉴스 상세 정보 조회: $newsId');
            final detail = await _newsService.getNewsDetail(newsId is String ? int.parse(newsId) : newsId as int);

            // 상세 정보에서 이미지 URL 추출
            final imageUrl = detail['image_url'] ?? detail['imageUrl'];

            enrichedNews.add({
              ...newsItem,
              'image_url': imageUrl,
              'detail': detail, // 필요시 다른 정보도 사용 가능
            });
          } else {
            enrichedNews.add(newsItem);
          }
        } catch (e) {
          debugPrint('⚠️ 뉴스 상세 정보 조회 실패: $e');
          // 실패해도 기본 정보는 유지
          enrichedNews.add(newsItem);
        }
      }

      if (mounted) {
        setState(() {
          _newsList = enrichedNews;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 추천 뉴스 로드 실패: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none, // 클립 아이콘이 밖으로 나가도록 허용
        alignment: Alignment.topCenter,
        children: [
          // 메인 컨테이너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), // 상단 패딩을 늘려 타이틀 공간 확보
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_modalRadius),
              border: Border.all(color: _primary.withAlpha(77), width: 3), // 보라색 외곽선 효과 (0.3 * 255 = 77)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(31), // 0.12 * 255 = 31
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 차지
              children: [
                // 타이틀 및 닫기 버튼 영역
                Stack(
                  children: [
                    const Center(
                      child: Text(
                        "오늘은 이 뉴스 어때요?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          fontFamily: 'Pretendard Variable',
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: _textTertiary, size: 24),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 로딩 또는 뉴스 리스트
                if (_loading)
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        '추천 뉴스를 불러올 수 없습니다',
                        style: TextStyle(
                          color: _textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else if (_newsList.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        '추천할 뉴스가 없습니다',
                        style: TextStyle(
                          color: _textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ..._buildNewsList(),

                const SizedBox(height: 24),

                // 하단 버튼
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withAlpha(77), // 0.3 * 255 = 77
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "시작하기",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 상단 클립 아이콘 (Stack으로 띄움)
          Positioned(
            top: -24, // 박스 위로 올림
            child: Transform.rotate(
              angle: -math.pi / 12, // 약간 기울기
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1C), // 검은색 클립 배경
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNewsList() {
    List<Widget> widgets = [];
    for (int i = 0; i < _newsList.length; i++) {
      final news = _newsList[i];

      // newsId 추출 (다양한 필드명 대응)
      final newsId = news['newsId'] ?? news['news_id'] ?? news['id'];

      widgets.add(_NewsItemTile(
        newsId: newsId,
        category: news['category'] ?? '일반',
        time: '방금',
        title: news['title'] ?? '제목 없음',
        imgUrl: news['image_url'] ?? 'https://picsum.photos/100',
      ));

      if (i < _newsList.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }
}

/// 뉴스 아이템 타일 위젯
class _NewsItemTile extends StatelessWidget {
  final dynamic newsId; // int 또는 String 가능
  final String category;
  final String time;
  final String title;
  final String imgUrl;

  const _NewsItemTile({
    required this.newsId,
    required this.category,
    required this.time,
    required this.title,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (newsId != null) {
          // newsId를 int로 변환
          final id = newsId is int ? newsId : int.tryParse(newsId.toString());

          if (id != null) {
            debugPrint('🔵 뉴스 아이템 클릭: ID=$id');

            // 웹뷰 화면으로 이동
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NewsReaderScreen(newsId: id),
              ),
            );
          } else {
            debugPrint('⚠️ 유효하지 않은 newsId: $newsId');
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imgUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72,
                height: 72,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: _NewsRecommendPopupState._primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: _NewsRecommendPopupState._textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewsRecommendPopupState._textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

