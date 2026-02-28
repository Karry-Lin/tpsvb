import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slot_availability.dart';
import '../models/sport_center.dart';
import '../models/sport_type.dart';
import '../providers/center_query_provider.dart';
import '../providers/query_providers.dart';
import '../providers/service_providers.dart';
import '../widgets/slot_detail_sheet.dart';

/// 查詢主畫面（場館總覽矩陣）
/// [hasQueried]：是否已進行過查詢（由 MainScreen 傳入）
/// [onRefresh]：下拉重新整理回呼（由 MainScreen 管理查詢邏輯）
class QueryScreen extends ConsumerWidget {
  final bool hasQueried;
  final Future<void> Function() onRefresh;

  const QueryScreen({
    super.key,
    required this.hasQueried,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(selectedCentersProvider);
    final sportType = ref.watch(selectedSportTypeProvider);
    final dates = ref.watch(activeDatesProvider);
    final progress = ref.watch(queryProgressProvider);
    final lastUpdated = ref.watch(lastUpdatedProvider);

    // 尚未查詢時顯示空白提示
    if (!hasQueried) {
      return const Center(
        child: _EmptyState(message: '請點選右上角篩選圖示\n設定條件後開始查詢'),
      );
    }

    // Column + Expanded：讓 _OverviewMatrix 填滿剩餘高度
    // RefreshIndicator 需要可滾動子 widget，在此用 NotificationListener 轉接
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          // 進度條（loading 時才顯示，高度自適應）
          _ProgressBar(done: progress.$1, total: progress.$2),

          // 篩選摘要列
          _FilterSummaryBar(
            sportType: sportType,
            centersCount: centers.length,
            datesCount: dates.length,
            lastUpdated: lastUpdated,
          ),

          // 總覽矩陣：Expanded 填滿剩餘高度
          Expanded(
            child: _OverviewMatrix(
              centers: centers,
              dates: dates,
              sportType: sportType,
            ),
          ),

          // 錯誤場館彙總列（固定在底部）
          _ErrorSummaryBar(centers: centers),
        ],
      ),
    );
  }
}

/// 進度條元件
class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressBar({
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = done < total;
    if (!isLoading) return const SizedBox.shrink();

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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
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

/// 篩選摘要列
class _FilterSummaryBar extends ConsumerWidget {
  final SportType sportType;
  final int centersCount;
  final int datesCount;
  final DateTime? lastUpdated;

  const _FilterSummaryBar({
    required this.sportType,
    required this.centersCount,
    required this.datesCount,
    required this.lastUpdated,
  });

  static const List<String> _timeFilterLabels = ['全天', '早上', '下午', '晚上'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilter = ref.watch(timeFilterProvider);
    final timeLabel = _timeFilterLabels[timeFilter.clamp(0, 3)];

    // 最後更新時間字串（UTC+8）
    String? updatedLabel;
    if (lastUpdated != null) {
      final taipei = lastUpdated!.toUtc().add(const Duration(hours: 8));
      updatedLabel =
          '更新 ${taipei.hour.toString().padLeft(2, '0')}:${taipei.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Chip(icon: Icons.sports_tennis, label: sportType.name),
          _Chip(icon: Icons.location_on_outlined, label: '$centersCount 場館'),
          _Chip(icon: Icons.calendar_today_outlined, label: '$datesCount 天'),
          _Chip(icon: Icons.schedule_outlined, label: timeLabel),
          if (updatedLabel != null)
            _Chip(
              icon: Icons.check_circle,
              label: updatedLabel,
              color: Colors.green,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF1565C0);
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
            style: TextStyle(
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

/// 總覽矩陣（自動填滿可用寬高）
class _OverviewMatrix extends ConsumerWidget {
  final List<SportCenter> centers;
  final List<String> dates;
  final SportType sportType;

  static const double _minCellWidth = 56;
  static const double _labelWidth = 80;
  static const double _headerHeight = 48;
  static const double _legendHeight = 40;
  static const double _minRowHeight = 48;

  const _OverviewMatrix({
    required this.centers,
    required this.dates,
    required this.sportType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (centers.isEmpty) {
      return const _EmptyState(message: '請選擇至少一個場館');
    }

    final timeFilter = ref.watch(timeFilterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // ── 寬度計算 ──────────────────────────────
        // 扣掉 Card margin (8*2) 和 label 欄後，平均分配給各日期欄
        final cardInnerWidth = constraints.maxWidth - 16;
        final cellWidth = dates.isEmpty
            ? _minCellWidth
            : ((cardInnerWidth - _labelWidth) / dates.length)
                .clamp(_minCellWidth, double.infinity);

        // ── 高度計算 ──────────────────────────────
        // 扣掉 Card margin (8*2)、header、legend 後，平均分配給各場館列
        final cardInnerHeight = constraints.maxHeight - 16;
        final rowsHeight = cardInnerHeight - _headerHeight - _legendHeight;
        final rowHeight = centers.isEmpty
            ? _minRowHeight
            : (rowsHeight / centers.length).clamp(_minRowHeight, double.infinity);

        // table 實際高度 = header + 各列 + legend
        final tableHeight =
            _headerHeight + rowHeight * centers.length + _legendHeight;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // 橫向超出時才允許捲動
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (cellWidth * dates.length + _labelWidth)
                  .clamp(cardInnerWidth, double.infinity),
              height: tableHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期標題列
                  SizedBox(
                    height: _headerHeight,
                    child: _DateHeaderRow(
                      dates: dates,
                      cellWidth: cellWidth,
                      labelWidth: _labelWidth,
                    ),
                  ),

                  // 各場館資料列
                  ...centers.map((center) => SizedBox(
                        height: rowHeight,
                        child: _CenterRow(
                          center: center,
                          dates: dates,
                          sportType: sportType,
                          timeFilter: timeFilter,
                          cellWidth: cellWidth,
                          labelWidth: _labelWidth,
                        ),
                      )),

                  // 圖例
                  SizedBox(
                    height: _legendHeight,
                    child: const _Legend(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 日期標題列
class _DateHeaderRow extends StatelessWidget {
  final List<String> dates;
  final double cellWidth;
  final double labelWidth;

  const _DateHeaderRow({
    required this.dates,
    required this.cellWidth,
    required this.labelWidth,
  });

  String _formatDateHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      // 以台北時區（UTC+8）判斷今天，與 queryDatesProvider 一致
      final nowTaipei = DateTime.now().toUtc().add(const Duration(hours: 8));
      final today = DateTime(nowTaipei.year, nowTaipei.month, nowTaipei.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = target.difference(today).inDays;

      if (diff == 0) return '今天\n${date.month}/${date.day}';
      if (diff == 1) return '明天\n${date.month}/${date.day}';
      if (diff == 2) return '後天\n${date.month}/${date.day}';

      const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      final weekday = weekdays[date.weekday - 1];
      return '周$weekday\n${date.month}/${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withAlpha(13),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '場館',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          ...dates.map((d) => SizedBox(
                width: cellWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    _formatDateHeader(d),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// 單一場館的資料列
class _CenterRow extends ConsumerWidget {
  final SportCenter center;
  final List<String> dates;
  final SportType sportType;
  final int timeFilter;
  final double cellWidth;
  final double labelWidth;

  const _CenterRow({
    required this.center,
    required this.dates,
    required this.sportType,
    required this.timeFilter,
    required this.cellWidth,
    required this.labelWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryState = ref.watch(sportCenterQueryProvider(center.id));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          // 場館名稱（寬度固定，高度由外層 SizedBox 決定）
          SizedBox(
            width: labelWidth,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name.replaceAll('運動中心', ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    center.district,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          // 各日期的狀態格（高度填滿列高）
          ...dates.map((date) {
            if (queryState.isLoading) {
              return _SkeletonCell(width: cellWidth, height: double.infinity);
            }

            if (queryState.errorMessage != null) {
              return Tooltip(
                message: queryState.errorMessage!,
                child: _StatusCell(
                  width: cellWidth,
                  height: double.infinity,
                  status: SlotStatus.error,
                  onTap: () {
                    ref.read(audioServiceProvider).playButton();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${center.name}：${queryState.errorMessage}'),
                        duration: const Duration(seconds: 5),
                        backgroundColor: Colors.orange[800],
                      ),
                    );
                  },
                ),
              );
            }

            final dayResult = queryState.resultsByDate[date];
            if (dayResult == null) {
              return _StatusCell(
                width: cellWidth,
                height: double.infinity,
                status: SlotStatus.unavailable,
                onTap: null,
              );
            }

            // 時段篩選
            final filteredResult = _applyTimeFilter(dayResult, timeFilter);

            return _StatusCell(
              width: cellWidth,
              height: double.infinity,
              status: filteredResult.overallStatus,
              onTap: filteredResult.overallStatus == SlotStatus.available ||
                      filteredResult.slots.isNotEmpty
                  ? () {
                      ref.read(audioServiceProvider).playButton();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SlotDetailSheet(
                          dayResult: filteredResult,
                          center: center,
                          categoryName: sportType.name,
                        ),
                      );
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }

  DayVenueResult _applyTimeFilter(DayVenueResult result, int filter) {
    if (filter == 0) return result; // 全天不篩選

    final filtered = result.slots.where((slot) {
      final hour = int.tryParse(slot.startTime.split(':').first) ?? 0;
      switch (filter) {
        case 1: return hour >= 6 && hour < 12; // 早上
        case 2: return hour >= 12 && hour < 18; // 下午
        case 3: return hour >= 18 && hour < 22; // 晚上
        default: return true;
      }
    }).toList();

    final hasAvailable = filtered.any((s) => s.status == SlotStatus.available);
    final allFull = filtered.isNotEmpty &&
        filtered.every((s) => s.status == SlotStatus.full);

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

/// 骨架屏格子（載入中動畫）
class _SkeletonCell extends StatefulWidget {
  final double width;
  final double height;

  const _SkeletonCell({required this.width, required this.height});

  @override
  State<_SkeletonCell> createState() => _SkeletonCellState();
}

class _SkeletonCellState extends State<_SkeletonCell>
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
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: _anim.value),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

/// 狀態格子
class _StatusCell extends StatelessWidget {
  final double width;
  final double height;
  final SlotStatus status;
  final VoidCallback? onTap;

  const _StatusCell({
    required this.width,
    required this.height,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      SlotStatus.available => (Colors.green, Icons.check_circle, '可預約'),
      SlotStatus.full => (Colors.red, Icons.cancel, '已額滿'),
      SlotStatus.unavailable => (Colors.grey, Icons.remove_circle, '未開放'),
      SlotStatus.error => (Colors.orange, Icons.error_outline, '錯誤'),
      SlotStatus.loading => (Colors.grey, Icons.hourglass_empty, '載入中'),
    };

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 圖例
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: const [
          _LegendItem(color: Colors.green, label: '可預約'),
          _LegendItem(color: Colors.red, label: '已額滿'),
          _LegendItem(color: Colors.grey, label: '未開放'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

/// 錯誤場館彙總列（持續顯示，無需點擊）
class _ErrorSummaryBar extends ConsumerWidget {
  final List<SportCenter> centers;

  const _ErrorSummaryBar({required this.centers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorCenters = centers.where((c) {
      final state = ref.watch(sportCenterQueryProvider(c.id));
      return !state.isLoading && state.errorMessage != null;
    }).toList();

    if (errorCenters.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[800]),
              const SizedBox(width: 6),
              Text(
                '${errorCenters.length} 個場館查詢失敗',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...errorCenters.map((c) {
            final msg = ref.read(sportCenterQueryProvider(c.id)).errorMessage ?? '';
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• ${c.name}：$msg',
                style: TextStyle(fontSize: 11, color: Colors.orange[900]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 空狀態提示
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

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
