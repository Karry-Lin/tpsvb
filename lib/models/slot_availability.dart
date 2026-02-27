/// 時段可用狀態列舉
enum SlotStatus {
  available, // 可預約（綠色）
  full, // 已額滿（紅色）
  unavailable, // 未開放（灰色）
  loading, // 載入中（骨架屏）
  error, // 載入失敗
}

/// 單一時段的場地可用狀態
class SlotAvailability {
  final String venueId;
  final String venueName; // 場地名稱，例：羽球場 A
  final String sportCenterId; // 場館 LID
  final DateTime date;
  final String startTime; // 例：14:00
  final String endTime; // 例：15:00
  final SlotStatus status;
  final int? price; // 費用（元）
  final String? directBookingUrl; // 此時段的直接預約連結

  const SlotAvailability({
    required this.venueId,
    required this.venueName,
    required this.sportCenterId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.price,
    this.directBookingUrl,
  });
}

/// 某場館某日期的查詢結果（包含多個時段）
class DayVenueResult {
  final String sportCenterId;
  final DateTime date;
  final List<SlotAvailability> slots;
  final SlotStatus overallStatus; // 整體狀態（用於矩陣格子顯示）

  const DayVenueResult({
    required this.sportCenterId,
    required this.date,
    required this.slots,
    required this.overallStatus,
  });

  /// 是否有任何可預約的時段
  bool get hasAvailable =>
      slots.any((s) => s.status == SlotStatus.available);
}

/// 某場館的查詢狀態（含所有日期）
class SportCenterQueryState {
  final String sportCenterId;
  final Map<String, DayVenueResult> resultsByDate; // key: yyyy-MM-dd
  final bool isLoading;
  final String? errorMessage;

  const SportCenterQueryState({
    required this.sportCenterId,
    required this.resultsByDate,
    required this.isLoading,
    this.errorMessage,
  });

  SportCenterQueryState copyWith({
    Map<String, DayVenueResult>? resultsByDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SportCenterQueryState(
      sportCenterId: sportCenterId,
      resultsByDate: resultsByDate ?? this.resultsByDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
