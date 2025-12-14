import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/news_list_service.dart';

class NewsReaderScreen extends StatefulWidget {
  // URL을 직접 받는 대신 int 타입의 newsId를 받습니다.
  final int newsId;

  const NewsReaderScreen({Key? key, required this.newsId}) : super(key: key);

  @override
  State<NewsReaderScreen> createState() => _NewsReaderScreenState();
}

class _NewsReaderScreenState extends State<NewsReaderScreen> {
  final NewsListService _newsService = NewsListService();
  late final WebViewController _controller;

  // newsId를 기반으로 뉴스 상세 정보를 가져와 URL을 반환하는 함수
  Future<String> _loadNewsUrl() async {
    try {
      final response = await _newsService.getNewsDetail(widget.newsId);
      // API 응답 구조에 맞춰 url을 파싱합니다.
      final newsUrl = response['url'] as String?;

      if (newsUrl == null || newsUrl.isEmpty) {
        throw Exception('뉴스 URL을 찾을 수 없습니다.');
      }
      return newsUrl;
    } catch (e) {
      // 에러를 다시 던져 FutureBuilder에서 처리하도록 함
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뉴스'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<String>(
        future: _loadNewsUrl(),
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러가 발생했을 때
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('뉴스를 불러올 수 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // FutureBuilder를 다시 실행하여 재시도
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 성공적으로 URL을 가져왔을 때
          final newsUrl = snapshot.data!;
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(newsUrl));

          return WebViewWidget(controller: _controller);
        },
      ),
    );
  }
}
