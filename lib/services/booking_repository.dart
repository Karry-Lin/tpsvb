import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/slot_availability.dart';
import '../models/api_response.dart';
import 'booking_api_service.dart';
import 'query_cache.dart';

/// 簡單的 Semaphore，限制最大並發數
class _Semaphore {
  final int _maxConcurrent;
  int _current = 0;
  final Queue<Completer<void>> _queue = Queue();

  _Semaphore(this._maxConcurrent);

  Future<void> acquire() async {
    if (_current < _maxConcurrent) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeFirst();
      next.complete();
    } else {
      _current--;
    }
  }
}

/// 全域 API-02 並發 Semaphore
/// 10 個並發在速度與伺服器限流容忍度之間取得平衡：
///   - 太大（無限制）→ 伺服器回 302 限流，產生橙色錯誤格
///   - 太小（≤5）    → 等待排隊時間長，整體查詢慢
final _api2Semaphore = _Semaphore(10);

/// 負責協調 API 呼叫與快取，並將原始 API 資料轉換為 Domain Model
///
/// 查詢策略（兩段式，不浪費請求）：
///   1. 先呼叫 API-01 取得此場館有開放的日期清單
///   2. 只對「有開放」的日期透過全域 Semaphore(10) 並發呼叫 API-02
///   3. 沒有開放的日期直接標記為 unavailable，不發任何請求
class BookingRepository {
  final BookingApiService _api;
  final QueryCache _cache;

  BookingRepository({BookingApiService? api, QueryCache? cache})
      : _api = api ?? BookingApiService(),
        _cache = cache ?? QueryCache();

  Future<Map<String, DayVenueResult>> queryCenter({
    required String sportCenterId,
    required String categoryId,
    required List<String> dates,
    bool forceRefresh = false,
  }) async {
    if (dates.isEmpty) return {};

    final startDate = dates.first;
    final endDate = dates.last;

    if (!forceRefresh) {
      final cached = _cache.get(sportCenterId, categoryId, startDate, endDate);
      if (cached != null) return cached;
    }

    // ── 第一階段：API-01 取得有開放的日期清單 ─────────────────────────────
    Set<String> allowedSet;
    try {
      final list = await _api.fetchAllowBookingCalendars(
        lid: sportCenterId,
        categoryId: categoryId,
        start: startDate,
        end: endDate,
      );
      allowedSet = Set<String>.from(list);
      debugPrint('[Repo] $sportCenterId/$categoryId allowedDates=$list');
    } catch (e) {
      debugPrint('[Repo] $sportCenterId API-01 failed (allow all): $e');
      allowedSet = {};
    }

    final map = <String, DayVenueResult>{};

    // 未開放的日期直接填入 unavailable（不發 API-02）
    final validDates = <String>[];
    for (final date in dates) {
      if (allowedSet.isNotEmpty && !allowedSet.contains(date)) {
        map[date] = DayVenueResult(
          sportCenterId: sportCenterId,
          date: _parseDate(date),
          slots: [],
          overallStatus: SlotStatus.unavailable,
        );
      } else {
        validDates.add(date);
      }
    }

    debugPrint(
      '[Repo] $sportCenterId: ${dates.length} days requested, '
      '${validDates.length} valid, ${dates.length - validDates.length} skipped',
    );

    if (validDates.isEmpty) {
      _cache.set(sportCenterId, categoryId, startDate, endDate, map);
      return map;
    }

    // ── 第二階段：只對有開放的日期透過 Semaphore 並發呼叫 API-02 ─────────
    final dayResults = await Future.wait(
      validDates.map((date) => _fetchDaySlotsSemaphored(
            sportCenterId: sportCenterId,
            categoryId: categoryId,
            date: date,
          ).catchError((e) {
        debugPrint('[Repo] $sportCenterId API-02 $date failed: $e');
        return DayVenueResult(
          sportCenterId: sportCenterId,
          date: _parseDate(date),
          slots: [],
          overallStatus: SlotStatus.error,
        );
      })),
    );

    for (int i = 0; i < validDates.length; i++) {
      map[validDates[i]] = dayResults[i];
    }

    _cache.set(sportCenterId, categoryId, startDate, endDate, map);
    return map;
  }

  Future<DayVenueResult> _fetchDaySlotsSemaphored({
    required String sportCenterId,
    required String categoryId,
    required String date,
  }) async {
    await _api2Semaphore.acquire();
    try {
      return await _fetchDaySlots(
        sportCenterId: sportCenterId,
        categoryId: categoryId,
        date: date,
      );
    } finally {
      _api2Semaphore.release();
    }
  }

  Future<DayVenueResult> _fetchDaySlots({
    required String sportCenterId,
    required String categoryId,
    required String date,
  }) async {
    final items = await _api.fetchBookingList(
      lid: sportCenterId,
      categoryId: categoryId,
      useDate: date,
    );

    if (items.isEmpty) {
      return DayVenueResult(
        sportCenterId: sportCenterId,
        date: _parseDate(date),
        slots: [],
        overallStatus: SlotStatus.unavailable,
      );
    }

    final slots = items.map(_toSlotAvailability).toList();
    final hasAvailable = slots.any((s) => s.status == SlotStatus.available);
    final allFull = slots.every((s) => s.status == SlotStatus.full);
    final availableCount =
        slots.where((s) => s.status == SlotStatus.available).length;
    final fullCount = slots.where((s) => s.status == SlotStatus.full).length;
    debugPrint(
      '[Repo] $sportCenterId/$categoryId $date: '
      'total=${slots.length} available=$availableCount full=$fullCount '
      '→ ${hasAvailable ? "available" : allFull ? "full" : "unavailable"}',
    );

    return DayVenueResult(
      sportCenterId: sportCenterId,
      date: _parseDate(date),
      slots: slots,
      overallStatus: hasAvailable
          ? SlotStatus.available
          : allFull
              ? SlotStatus.full
              : SlotStatus.unavailable,
    );
  }

  SlotAvailability _toSlotAvailability(BookingListItem item) {
    return SlotAvailability(
      venueId: item.venueId,
      venueName: item.venueName,
      sportCenterId: item.sportCenterId,
      date: _parseDate(item.date),
      startTime: item.startTime,
      endTime: item.endTime,
      status: item.isAvailable ? SlotStatus.available : SlotStatus.full,
      price: item.price,
      directBookingUrl: item.bookingUrl,
    );
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  void invalidateAll() => _cache.invalidateAll();
}
