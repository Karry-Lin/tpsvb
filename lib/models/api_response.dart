/// API-01 回應項目
/// 實際回傳格式：[{"title":"開放預約","start":"2026-03-08","allDay":true,"color":"#5F6AAA"},...]
class AllowBookingCalendarItem {
  final String date; // yyyy-MM-dd

  const AllowBookingCalendarItem({required this.date});

  factory AllowBookingCalendarItem.fromJson(Map<String, dynamic> json) {
    // 實際 API 回傳 "start" 欄位，格式為 "2026-03-08"
    final raw =
        (json['start'] ?? json['Start'] ?? json['UseDate'] ?? json['useDate'] ?? json['date'] ?? '') as String;
    final dateOnly = raw.length >= 10 ? raw.substring(0, 10) : raw;
    return AllowBookingCalendarItem(date: dateOnly);
  }
}

/// API-02 回應中的單筆場地時段
/// 實際回傳格式：{"rows":[{
///   "LSID":"ZS4FBadmintonA",
///   "LSIDName":"4F羽球A",
///   "StartTime":{"Hours":6,"Minutes":0,...},
///   "EndTime":{"Hours":7,"Minutes":0,...},
///   "allowBooking":"Y",
///   "TotalPrice":300,
///   ...
/// }]}
class BookingListItem {
  final String venueId;    // 場地 ID（LSID）
  final String venueName;  // 場地名稱（LSIDName）
  final String sportCenterId;
  final String date;
  final String startTime;  // HH:mm
  final String endTime;    // HH:mm
  final bool isAvailable;  // true = 可預約
  final int? price;
  final String? bookingUrl;

  const BookingListItem({
    required this.venueId,
    required this.venueName,
    required this.sportCenterId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.price,
    this.bookingUrl,
  });

  factory BookingListItem.fromJson(
    Map<String, dynamic> json,
    String sportCenterId,
    String date,
  ) {
    // 解析時間物件：{"Hours":14,"Minutes":0,...} → "14:00"
    // 也相容字串格式 "14:00:00"
    String parseTimeObj(dynamic raw) {
      if (raw == null) return '';
      if (raw is Map) {
        final h = (raw['Hours'] ?? raw['hours'] ?? 0) as num;
        final m = (raw['Minutes'] ?? raw['minutes'] ?? 0) as num;
        return '${h.toInt().toString().padLeft(2, '0')}:${m.toInt().toString().padLeft(2, '0')}';
      }
      final s = raw.toString();
      if (s.length >= 5) return s.substring(0, 5);
      return s;
    }

    // 解析費用
    int? parsePrice(dynamic raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is double) return raw.toInt();
      final s = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
      return s.isEmpty ? null : int.tryParse(s);
    }

    // 可用性：allowBooking == "Y" 表示可預約
    bool parseAvailable(Map<String, dynamic> j) {
      final allowBooking = j['allowBooking'];
      if (allowBooking != null) {
        return allowBooking.toString().toUpperCase() == 'Y';
      }
      // 相容其他可能格式
      if (j.containsKey('CanBook')) return j['CanBook'] == true || j['CanBook'] == 1;
      if (j.containsKey('canBook')) return j['canBook'] == true || j['canBook'] == 1;
      return false;
    }

    // 場地名稱：優先用 LSIDName，其次 CourtName 等
    final venueName = (json['LSIDName'] ??
            json['CourtName'] ??
            json['courtName'] ??
            json['VenueName'] ??
            json['venueName'] ??
            '')
        .toString();

    // 場地 ID：優先用 LSID
    final venueId = (json['LSID'] ??
            json['CourtId'] ??
            json['courtId'] ??
            json['VenueId'] ??
            json['venueId'] ??
            venueName)
        .toString();

    return BookingListItem(
      venueId: venueId,
      venueName: venueName,
      sportCenterId: sportCenterId,
      date: date,
      startTime: parseTimeObj(json['StartTime'] ?? json['startTime']),
      endTime: parseTimeObj(json['EndTime'] ?? json['endTime']),
      isAvailable: parseAvailable(json),
      price: parsePrice(json['TotalPrice'] ?? json['Price'] ?? json['price'] ?? json['Fee'] ?? json['fee']),
      bookingUrl: (json['BookingUrl'] ?? json['bookingUrl'])?.toString(),
    );
  }
}
