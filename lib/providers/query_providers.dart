import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sport_center.dart';
import '../models/sport_type.dart';
import 'service_providers.dart';

/// 當前選擇的運動類型
final selectedSportTypeProvider = StateProvider<SportType>((ref) {
  // 初始從偏好設定讀取（同步預設值）
  return SportType.all.firstWhere(
    (t) => t.id == 'Badminton',
    orElse: () => SportType.all.first,
  );
});

/// 選取的場館清單（空 = 全選）
final selectedCentersProvider = StateProvider<List<SportCenter>>((ref) {
  return SportCenter.all; // 預設全選
});

/// 查詢日期範圍（天數）
final dateRangeDaysProvider = StateProvider<int>((_) => 14);

/// 時段篩選：0=全天, 1=早上(06-12), 2=下午(12-18), 3=晚上(18-22)
final timeFilterProvider = StateProvider<int>((_) => 0);

/// 計算查詢的日期清單（台北標準時間 UTC+8 起 N 天）
final queryDatesProvider = Provider<List<String>>((ref) {
  final days = ref.watch(dateRangeDaysProvider);
  // 以台北時區（UTC+8）取得今天日期，避免跨午夜時顯示錯誤日期
  final nowUtc = DateTime.now().toUtc();
  final nowTaipei = nowUtc.add(const Duration(hours: 8));
  final today = DateTime(nowTaipei.year, nowTaipei.month, nowTaipei.day);
  return List.generate(days, (i) {
    final d = today.add(Duration(days: i));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  });
});

/// 偏好設定初始化完成後，將儲存的偏好套用到對應 Provider
/// 在 App 啟動時呼叫一次
Future<void> applyStoredPreferences(WidgetRef ref) async {
  final prefsAsync = ref.read(preferencesProvider);
  await prefsAsync.when(
    data: (prefs) async {
      // 套用偏好的運動類型
      final sportTypeId = prefs.getSportType();
      final sportType = SportType.all.firstWhere(
        (t) => t.id == sportTypeId,
        orElse: () => SportType.all.first,
      );
      ref.read(selectedSportTypeProvider.notifier).state = sportType;

      // 套用偏好的場館
      final centerIds = prefs.getSelectedCenters();
      if (centerIds.isNotEmpty) {
        final centers = SportCenter.all
            .where((c) => centerIds.contains(c.id))
            .toList();
        if (centers.isNotEmpty) {
          ref.read(selectedCentersProvider.notifier).state = centers;
        }
      }

      // 套用日期範圍
      ref.read(dateRangeDaysProvider.notifier).state = prefs.getDateRangeDays();

      // 套用時段篩選
      ref.read(timeFilterProvider.notifier).state = prefs.getTimeFilter();
    },
    loading: () {},
    error: (e, st) {},
  );
}
