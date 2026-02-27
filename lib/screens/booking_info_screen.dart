import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 場地預約須知頁面（WebView）
class BookingInfoScreen extends StatefulWidget {
  const BookingInfoScreen({super.key});

  static const String url =
      'https://booking-tpsc.sporetrofit.com/Home/BookingInformation#1';

  @override
  State<BookingInfoScreen> createState() => _BookingInfoScreenState();
}

class _BookingInfoScreenState extends State<BookingInfoScreen> {
  late final WebViewController _webController;
  bool _isLoading = true;
  bool _hasError = false;

  /// 將英文區名 h1 標題替換為中文的 JavaScript
  static const String _replaceH1JS = r"""
(function() {
  var map = {
    'Beitou Dist.':    '北投',
    'Datong Dist.':    '大同',
    'Neihu Dist.':     '內湖',
    'Wanhua Dist.':    '萬華',
    'Songshan Dist.':  '松山',
    'Shihlin Dist.':   '士林',
    'Zhongshan Dist.': '中山',
    'Jhongjheng Dist.':'中正',
    'Nangang Dist.':   '南港',
    'Xinyi Dist.':     '信義',
    "Da'an Dist.":     '大安',
    'Wunshan Dist.':   '文山'
  };
  document.querySelectorAll('h1').forEach(function(el) {
    var text = el.textContent || '';
    for (var eng in map) {
      if (text.indexOf(eng) !== -1) {
        el.textContent = map[eng];
        break;
      }
    }
  });
})();
""";

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            // 注入 JS 將英文標題替換為中文
            await _webController.runJavaScript(_replaceH1JS);
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(BookingInfoScreen.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('場地預約須知'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _hasError = false);
              _webController.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('無法載入頁面', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('請確認網路連線後重試', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            WebViewWidget(controller: _webController),
          if (_isLoading && !_hasError)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
        ],
      ),
    );
  }
}
