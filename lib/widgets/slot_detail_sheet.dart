import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/slot_availability.dart';
import '../models/sport_center.dart';

/// 時段詳細資訊彈窗
class SlotDetailSheet extends StatelessWidget {
  final DayVenueResult dayResult;
  final SportCenter center;
  final String categoryName;

  const SlotDetailSheet({
    super.key,
    required this.dayResult,
    required this.center,
    required this.categoryName,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}（$weekday）';
  }

  Future<void> _openBookingUrl(String? url, BuildContext context) async {
    // API 不提供直接預約 URL，統一開啟官方預約系統首頁
    final target = (url != null && url.isNotEmpty)
        ? url
        : 'https://booking-tpsc.sporetrofit.com/';
    await _launchUrl(target, context);
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟瀏覽器')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots =
        dayResult.slots.where((s) => s.status == SlotStatus.available).toList();
    final fullSlots =
        dayResult.slots.where((s) => s.status == SlotStatus.full).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$categoryName・${_formatDate(dayResult.date)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 時段列表
              Expanded(
                child: dayResult.slots.isEmpty
                    ? const Center(
                        child: Text(
                          '此日期無場地資料',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (availableSlots.isNotEmpty) ...[
                            _SectionHeader(
                              title: '可預約時段',
                              color: Colors.green,
                              count: availableSlots.length,
                            ),
                            const SizedBox(height: 8),
                            ...availableSlots.map(
                              (slot) => _SlotCard(
                                slot: slot,
                                onTap: () => _openBookingUrl(
                                    slot.directBookingUrl, context),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (fullSlots.isNotEmpty) ...[
                            _SectionHeader(
                              title: '已額滿時段',
                              color: Colors.red,
                              count: fullSlots.length,
                            ),
                            const SizedBox(height: 8),
                            ...fullSlots.map(
                              (slot) => _SlotCard(slot: slot, onTap: null),
                            ),
                          ],
                        ],
                      ),
              ),

              // 前往官方網站按鈕
              if (availableSlots.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final url = availableSlots.first.directBookingUrl;
                          _openBookingUrl(url, context);
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('前往官方網站預約'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count 個',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotAvailability slot;
  final VoidCallback? onTap;

  const _SlotCard({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = slot.status == SlotStatus.available;
    final color = isAvailable ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withAlpha(77)),
      ),
      color: color.withAlpha(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.venueName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.startTime} ～ ${slot.endTime}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (slot.price != null)
                Text(
                  'NT\$ ${slot.price}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              if (isAvailable) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.green,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
