import '../models/slot_availability.dart';

/// 記憶體快取項目
class _CacheEntry {
  final Map<String, DayVenueResult> data;
  final DateTime expiredAt;

  _CacheEntry({required this.data, required Duration ttl})
      : expiredAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiredAt);
}

/// 場地查詢結果的記憶體快取（TTL 5 分鐘）
class QueryCache {
  static const Duration _ttl = Duration(minutes: 5);

  // key = "{sportCenterId}_{categoryId}_{startDate}_{endDate}"
  final Map<String, _CacheEntry> _cache = {};

  String _key(
    String sportCenterId,
    String categoryId,
    String startDate,
    String endDate,
  ) => '${sportCenterId}_${categoryId}_${startDate}_$endDate';

  /// 取得快取（若已過期回傳 null）
  Map<String, DayVenueResult>? get(
    String sportCenterId,
    String categoryId,
    String startDate,
    String endDate,
  ) {
    final key = _key(sportCenterId, categoryId, startDate, endDate);
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  /// 儲存快取
  void set(
    String sportCenterId,
    String categoryId,
    String startDate,
    String endDate,
    Map<String, DayVenueResult> data,
  ) {
    final key = _key(sportCenterId, categoryId, startDate, endDate);
    _cache[key] = _CacheEntry(data: data, ttl: _ttl);
  }

  /// 清除特定場館的快取
  void invalidate(String sportCenterId) {
    _cache.removeWhere((k, _) => k.startsWith(sportCenterId));
  }

  /// 清除全部快取
  void invalidateAll() {
    _cache.clear();
  }
}
