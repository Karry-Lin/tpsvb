import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot_availability.dart';
import '../models/sport_center.dart';
import '../models/sport_type.dart';
import '../providers/center_query_provider.dart';
import '../providers/query_providers.dart';
import '../widgets/slot_detail_sheet.dart';

/// 速覽頁：只顯示有可預約時段的場館，以日期 Tag 方式呈現
/// [hasQueried]：是否已進行過查詢
/// [onRefresh]：下拉重新整理回呼
/// [onGoToFullView]：底部按鈕切換至完整查詢頁的回呼
class AvailableScreen extends ConsumerWidget {
  final bool hasQueried;
  final Future<void> Function() onRefresh;

  const AvailableScreen({
    super.key,
    required this.hasQueried,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(selectedCentersProvider);
    final sportType = ref.watch(selectedSportTypeProvider);
    final dates = ref.watch(queryDatesProvider);
    final progress = ref.watch(queryProgressProvider);
    final timeFilter = ref.watch(timeFilterProvider);

    // 尚未查詢時顯示空白提示
    if (!hasQueried) {
      return const Center(
        child: _EmptyHint(message: '請點選右上角篩選圖示\n設定條件後開始查詢'),
      );
    }

    // 收集有可預約時段的場館資料
    final availableCenters = <_CenterAvailability>[];
    bool anyLoading = false;

    for (final center in centers) {
      final state = ref.watch(sportCenterQueryProvider(center.id));
      if (state.isLoading) {
        anyLoading = true;
        continue;
      }
      if (state.errorMessage != null) continue;

      // 找出有可預約時段的日期（依時段篩選）
      final availableDays = <_DayInfo>[];
      for (final date in dates) {
        final dayResult = state.resultsByDate[date];
        if (dayResult == null) continue;

        final filtered = _applyTimeFilter(dayResult, timeFilter);
        final availableCount =
            filtered.slots.where((s) => s.status == SlotStatus.available).length;
        if (availableCount > 0) {
          availableDays.add(_DayInfo(
            date: date,
            availableCount: availableCount,
            dayResult: filtered,
          ));
        }
      }

      if (availableDays.isNotEmpty) {
        availableCenters.add(_CenterAvailability(
          center: center,
          days: availableDays,
        ));
      }
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              slivers: [
                // 進度條
                if (anyLoading || progress.$1 < progress.$2)
                  SliverToBoxAdapter(
                    child: _ProgressBar(
                      done: progress.$1,
                      total: progress.$2,
                    ),
                  ),

                // 篩選摘要列
                SliverToBoxAdapter(
                  child: _FilterSummaryBar(
                    sportType: sportType,
                    centersCount: centers.length,
                    datesCount: dates.length,
                  ),
                ),

                // 骨架屏（載入中場館）
                if (anyLoading)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => const _SkeletonCard(),
                      childCount: centers
                          .where((c) =>
                              ref.read(sportCenterQueryProvider(c.id)).isLoading)
                          .length
                          .clamp(1, 3),
                    ),
                  ),

                // 有可預約場館的卡片
                if (availableCenters.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => _CenterCard(
                        data: availableCenters[index],
                        sportType: sportType,
                      ),
                      childCount: availableCenters.length,
                    ),
                  ),

                // 完全無可預約場館（且已全部載入完畢）
                if (!anyLoading &&
                    progress.$1 >= progress.$2 &&
                    availableCenters.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: _EmptyHint(message: '目前無可預約的場地\n請調整篩選條件後重新查詢'),
                    ),
                  ),

                // 底部空白
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DayVenueResult _applyTimeFilter(DayVenueResult result, int filter) {
    if (filter == 0) return result;

    final filtered = result.slots.where((slot) {
      final hour = int.tryParse(slot.startTime.split(':').first) ?? 0;
      switch (filter) {
        case 1:
          return hour >= 6 && hour < 12; // 早上
        case 2:
          return hour >= 12 && hour < 18; // 下午
        case 3:
          return hour >= 18 && hour < 22; // 晚上
        default:
          return true;
      }
    }).toList();

    final hasAvailable = filtered.any((s) => s.status == SlotStatus.available);
    final allFull =
        filtered.isNotEmpty && filtered.every((s) => s.status == SlotStatus.full);

    return DayVenueResult(
      sportCenterId: result.sportCenterId,
      date: result.date,
      slots: filtered,
      overallStatus: filtered.isEmpty
          ? SlotStatus.unavailable
          : hasAvailable
              ? SlotStatus.available
              : allFull
                  ? SlotStatus.full
                  : SlotStatus.unavailable,
    );
  }
}

// ─────────────────────────────────────────────
// 資料模型
// ─────────────────────────────────────────────

class _DayInfo {
  final String date;
  final int availableCount;
  final DayVenueResult dayResult;

  const _DayInfo({
    required this.date,
    required this.availableCount,
    required this.dayResult,
  });
}

class _CenterAvailability {
  final SportCenter center;
  final List<_DayInfo> days;

  const _CenterAvailability({required this.center, required this.days});
}

// ─────────────────────────────────────────────
// 進度條
// ─────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    if (done >= total) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '載入中 $done / $total 場館',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total > 0 ? done / total : null,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 篩選摘要列
// ─────────────────────────────────────────────

class _FilterSummaryBar extends ConsumerWidget {
  final SportType sportType;
  final int centersCount;
  final int datesCount;

  const _FilterSummaryBar({
    required this.sportType,
    required this.centersCount,
    required this.datesCount,
  });

  static const List<String> _timeFilterLabels = ['全天', '早上', '下午', '晚上'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilter = ref.watch(timeFilterProvider);
    final timeLabel = _timeFilterLabels[timeFilter.clamp(0, 3)];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      margin: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SummaryChip(icon: Icons.sports_tennis, label: sportType.name),
          _SummaryChip(
              icon: Icons.location_on_outlined, label: '$centersCount 場館'),
          _SummaryChip(
              icon: Icons.calendar_today_outlined, label: '$datesCount 天'),
          _SummaryChip(icon: Icons.schedule_outlined, label: timeLabel),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const chipColor = Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 場館卡片
// ─────────────────────────────────────────────

class _CenterCard extends StatelessWidget {
  final _CenterAvailability data;
  final SportType sportType;

  const _CenterCard({required this.data, required this.sportType});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 場館標題（頭像 + 名稱）
            Row(
              children: [
                // 圓形頭像
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1565C0).withAlpha(20),
                  backgroundImage: AssetImage(
                      'assets/images/${data.center.id}.png'),
                  onBackgroundImageError: (e, _) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.center.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data.center.district,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 可預約日數摘要
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.days.length} 天可預約',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 日期 Tag 列
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.days.map((day) {
                return _DateTag(
                  date: day.date,
                  count: day.availableCount,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SlotDetailSheet(
                        dayResult: day.dayResult,
                        center: data.center,
                        categoryName: sportType.name,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 日期 Tag
// ─────────────────────────────────────────────

class _DateTag extends StatelessWidget {
  final String date; // 格式 "2026-03-08"
  final int count;
  final VoidCallback onTap;

  const _DateTag({
    required this.date,
    required this.count,
    required this.onTap,
  });

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.month}/${d.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 5),
            Text(
              '${_formatDate(date)} ×$count',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 骨架屏卡片
// ─────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.5).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Card(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        elevation: 1,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _anim.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color:
                                Colors.grey.withValues(alpha: _anim.value),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color:
                                Colors.grey.withValues(alpha: _anim.value),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 70,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _anim.value),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 空狀態提示
// ─────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String message;

  const _EmptyHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
