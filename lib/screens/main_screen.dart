import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/center_query_provider.dart';
import '../providers/query_providers.dart';
import '../providers/service_providers.dart';import '../widgets/filter_sheet.dart';
import 'available_screen.dart';
import 'booking_info_screen.dart';
import 'query_screen.dart';

/// 主畫面（底部 TabBar 容器）
/// - Tab 0：速覽頁（AvailableScreen）
/// - Tab 1：完整查詢頁（QueryScreen）
/// - 統一管理篩選面板開啟與查詢觸發
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentTab = 0;
  bool _hasQueried = false;

  @override
  void initState() {
    super.initState();
    // 進入後在下一幀立即彈出篩選面板
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openFilterSheet();
    });
  }

  /// 開啟篩選面板，套用後觸發查詢
  Future<void> _openFilterSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_hasQueried, // 首次必須設定才可關閉；之後可隨意關閉
      builder: (_) => const FilterSheet(),
    );
    if (changed == true && mounted) {
      _startQuery();
    }
  }

  /// 觸發所有選取場館的並發查詢
  Future<void> _startQuery() async {
    final audio = ref.read(audioServiceProvider);
    final centers = ref.read(selectedCentersProvider);
    final sportType = ref.read(selectedSportTypeProvider);
    // 每次查詢都即時計算日期，確保使用當天台北時間，不受 Provider 快取影響
    final days = ref.read(dateRangeDaysProvider);
    final dates = buildQueryDates(days);

    // 清除快取與上次更新時間
    ref.read(queryCacheProvider).invalidateAll();
    ref.read(lastUpdatedProvider.notifier).state = null;
    // 同步更新 UI 顯示用的日期清單
    ref.read(activeDatesProvider.notifier).state = dates;

    // 先將所有場館設為載入中（清空舊資料）
    for (final center in centers) {
      ref.read(sportCenterQueryProvider(center.id).notifier).reset();
    }

    setState(() {
      _hasQueried = true;
    });

    // 開始搜尋音效（循環）
    await audio.startSearching();

    // 全部場館同時並發查詢
    await Future.wait(
      centers.map(
        (center) => ref
            .read(sportCenterQueryProvider(center.id).notifier)
            .query(
              categoryId: sportType.id,
              dates: dates,
              forceRefresh: true,
            ),
      ),
    );

    ref.read(lastUpdatedProvider.notifier).state = DateTime.now();

    // 查詢完成：停止搜尋音效，播放成功音效
    await audio.playSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _currentTab == 0 ? '快速瀏覽' : '完整查詢',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          // 須知按鈕
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookingInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 18),
            label: const Text(
              '須知',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          // 篩選按鈕
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '篩選條件',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          // Tab 0：速覽頁
          AvailableScreen(
            hasQueried: _hasQueried,
            onRefresh: _startQuery,
          ),
          // Tab 1：完整查詢頁
          QueryScreen(
            hasQueried: _hasQueried,
            onRefresh: _startQuery,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            activeIcon: Icon(Icons.flash_on),
            label: '快速瀏覽',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: '完整查詢',
          ),
        ],
      ),
    );
  }
}
