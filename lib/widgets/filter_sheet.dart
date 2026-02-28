import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sport_center.dart';
import '../models/sport_type.dart';
import '../providers/query_providers.dart';
import '../providers/service_providers.dart';

/// 查詢篩選面板（底部彈出）
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late SportType _selectedSportType;
  late List<SportCenter> _selectedCenters;
  late int _dateRangeDays;
  late int _timeFilter;

  static const List<(String label, int value)> _timeFilterOptions = [
    ('全天', 0),
    ('早上 (06-12)', 1),
    ('下午 (12-18)', 2),
    ('晚上 (18-22)', 3),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSportType = ref.read(selectedSportTypeProvider);
    _selectedCenters = List.from(ref.read(selectedCentersProvider));
    _dateRangeDays = ref.read(dateRangeDaysProvider);
    _timeFilter = ref.read(timeFilterProvider);
  }

  void _applyAndClose() async {
    ref.read(audioServiceProvider).playButton();
    // 更新 Providers
    ref.read(selectedSportTypeProvider.notifier).state = _selectedSportType;
    ref.read(selectedCentersProvider.notifier).state =
        _selectedCenters.isEmpty ? SportCenter.all : _selectedCenters;
    ref.read(dateRangeDaysProvider.notifier).state = _dateRangeDays;
    ref.read(timeFilterProvider.notifier).state = _timeFilter;

    // 儲存偏好設定
    final prefsAsync = ref.read(preferencesProvider);
    await prefsAsync.when(
      data: (prefs) async {
        await prefs.setSportType(_selectedSportType.id);
        await prefs.setSelectedCenters(
          _selectedCenters.map((c) => c.id).toList(),
        );
        await prefs.setDateRangeDays(_dateRangeDays);
        await prefs.setTimeFilter(_timeFilter);
      },
      loading: () {},
      error: (e, st) {},
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖曳把手
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 標題列
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      '篩選條件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedSportType = SportType.all.first;
                          _selectedCenters = SportCenter.all;
                          _dateRangeDays = 14;
                          _timeFilter = 0;
                        });
                      },
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 運動類型
                    _SectionTitle(title: '運動類型'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SportType.all.map((type) {
                        final selected = _selectedSportType.id == type.id;
                        return FilterChip(
                          label: Text(type.name),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedSportType = type),
                          selectedColor:
                              const Color(0xFF1565C0).withAlpha(51),
                          checkmarkColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // 查詢天數
                    _SectionTitle(title: '查詢天數'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('1', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Expanded(
                          child: Slider(
                            value: _dateRangeDays.toDouble(),
                            min: 1,
                            max: 14,
                            divisions: 13,
                            label: '$_dateRangeDays 天',
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (v) =>
                                setState(() => _dateRangeDays = v.round()),
                          ),
                        ),
                        const Text('14', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_dateRangeDays 天',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 時段篩選
                    _SectionTitle(title: '時段篩選'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeFilterOptions.map((opt) {
                        final selected = _timeFilter == opt.$2;
                        return ChoiceChip(
                          label: Text(opt.$1),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _timeFilter = opt.$2),
                          selectedColor:
                              const Color(0xFF1565C0).withAlpha(51),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // 場館選擇
                    Row(
                      children: [
                        _SectionTitle(title: '場館選擇'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(
                            () => _selectedCenters = SportCenter.all,
                          ),
                          child: const Text('全選'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedCenters = []),
                          child: const Text('全不選'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...SportCenter.all.map((center) {
                      final selected =
                          _selectedCenters.any((c) => c.id == center.id);
                      return CheckboxListTile(
                        title: Text(center.name),
                        subtitle: Text(
                          center.district,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedCenters.add(center);
                            } else {
                              _selectedCenters
                                  .removeWhere((c) => c.id == center.id);
                            }
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF1565C0),
                      );
                    }),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // 套用按鈕
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '套用',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black87,
      ),
    );
  }
}
