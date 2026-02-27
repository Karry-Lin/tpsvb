import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot_availability.dart';
import 'service_providers.dart';
import 'query_providers.dart';

/// 單一場館的查詢狀態 Notifier
class SportCenterQueryNotifier
    extends StateNotifier<SportCenterQueryState> {
  final String sportCenterId;
  final Ref _ref;

  SportCenterQueryNotifier(this.sportCenterId, this._ref)
      : super(SportCenterQueryState(
          sportCenterId: sportCenterId,
          resultsByDate: {},
          isLoading: false,
        ));

  /// 開始查詢（不 await，讓 UI 逐步更新）
  Future<void> query({
    required String categoryId,
    required List<String> dates,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading && !forceRefresh) return;

    // 重置為載入中狀態
    state = SportCenterQueryState(
      sportCenterId: sportCenterId,
      resultsByDate: {},
      isLoading: true,
    );

    try {
      final repo = _ref.read(repositoryProvider);
      final results = await repo.queryCenter(
        sportCenterId: sportCenterId,
        categoryId: categoryId,
        dates: dates,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        state = SportCenterQueryState(
          sportCenterId: sportCenterId,
          resultsByDate: results,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = SportCenterQueryState(
          sportCenterId: sportCenterId,
          resultsByDate: {},
          isLoading: false,
          errorMessage: e.toString().replaceFirst('ApiException: ', ''),
        );
      }
    }
  }

  void reset() {
    state = SportCenterQueryState(
      sportCenterId: sportCenterId,
      resultsByDate: {},
      isLoading: false,
    );
  }
}

/// 每個場館對應獨立的 StateNotifier Provider（使用 family）
final sportCenterQueryProvider = StateNotifierProvider.family<
    SportCenterQueryNotifier, SportCenterQueryState, String>(
  (ref, sportCenterId) => SportCenterQueryNotifier(sportCenterId, ref),
);

/// 整體查詢進度（已完成的場館數）
final queryProgressProvider = Provider<(int done, int total)>((ref) {
  final centers = ref.watch(selectedCentersProvider);
  int done = 0;
  for (final center in centers) {
    final s = ref.watch(sportCenterQueryProvider(center.id));
    if (!s.isLoading) done++;
  }
  return (done, centers.length);
});

/// 最後更新時間
final lastUpdatedProvider = StateProvider<DateTime?>((_) => null);
