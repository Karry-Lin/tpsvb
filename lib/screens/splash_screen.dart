import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/query_providers.dart';
import '../providers/service_providers.dart';
import 'main_screen.dart';

/// 啟動首頁（Landing Page）
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 套用儲存的偏好設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      applyStoredPreferences(ref);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToQuery() {
    ref.read(audioServiceProvider).playButton();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // 深藍色背景
      body: GestureDetector(
        onTap: _navigateToQuery,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App 圖示
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App 名稱
                      const Text(
                        '場訂',
                        style: TextStyle(
                          fontFamily: 'ChenYuluoyan',
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '台北市公立運動場地預約查詢',
                        style: TextStyle(
                          fontFamily: 'ChenYuluoyan',
                          color: Colors.white70,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // 副標題
                      Text(
                        '快速瀏覽場地預約狀況',
                        style: TextStyle(
                          fontFamily: 'ChenYuluoyan',
                          color: Colors.white.withAlpha(204),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // 開始查詢按鈕
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToQuery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '開始查詢',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 提示文字
                      Text(
                        '點擊畫面任意位置進入',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
