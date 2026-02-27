import 'package:flutter/foundation.dart';
import '../models/slot_availability.dart';
import '../models/api_response.dart';
import 'booking_api_service.dart';
import 'query_cache.dart';

/// 負責協調 API 呼叫與快取，並將原始 API 資料轉換為 Domain Model
class BookingRepository {
  final BookingApiService _api;
  final QueryCache _cache;

  BookingRepository({BookingApiService? api, QueryCache? cache})
      : _api = api ?? BookingApiService(),
        _cache = cache ?? QueryCache();

  /// 查詢某場館在指定日期區間內，所有有效日期的場地狀態
  ///
  /// 兩段式流程：
  ///   1. API-01 取得有開放的日期
  ///   2. 對每個有效日期呼叫 API-02（由外部分批並發控制）
  ///
  /// [sportCenterId] 場館 LID
  /// [categoryId] 球類
  /// [dates] 要查詢的日期清單（yyyy-MM-dd）
  /// [forceRefresh] 是否強制略過快取
  ///
  /// 回傳：各日期的查詢結果 Map（key = yyyy-MM-dd）
  Future<Map<String, DayVenueResult>> queryCenter({
    required String sportCenterId,
    required String categoryId,
    required List<String> dates,
    bool forceRefresh = false,
  }) async {
    if (dates.isEmpty) return {};

    final startDate = dates.first;
    final endDate = dates.last;

    // 檢查快取
    if (!forceRefresh) {
      final cached = _cache.get(sportCenterId, categoryId, startDate, endDate);
      if (cached != null) return cached;
    }

    // 第一階段：取得有開放預約的日期
    List<String> allowedDates;
    try {
      allowedDates = await _api.fetchAllowBookingCalendars(
        lid: sportCenterId,
        categoryId: categoryId,
        start: startDate,
        end: endDate,
      );
      debugPrint('[Repo] $sportCenterId/$categoryId allowedDates=$allowedDates');
    } catch (e) {
      debugPrint('[Repo] $sportCenterId API-01 failed: $e');
      rethrow;
    }

    final allowedSet = Set<String>.from(allowedDates);

    // 對沒有開放的日期，直接標記為未開放
    final results = <String, DayVenueResult>{};
    for (final date in dates) {
      if (!allowedSet.contains(date)) {
        results[date] = DayVenueResult(
          sportCenterId: sportCenterId,
          date: _parseDate(date),
          slots: [],
          overallStatus: SlotStatus.unavailable,
        );
      }
    }

    // 第二階段：對有開放的日期查詢時段清單
    final validDates = dates.where((d) => allowedSet.contains(d)).toList();
    for (final date in validDates) {
      final dayResult = await _fetchDaySlots(
        sportCenterId: sportCenterId,
        categoryId: categoryId,
        date: date,
      );
      results[date] = dayResult;
    }

    // 儲存快取
    _cache.set(sportCenterId, categoryId, startDate, endDate, results);
    return results;
  }

  /// 查詢某場館某日期的時段清單（API-02）
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
