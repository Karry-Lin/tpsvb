/// 場館資料模型
class SportCenter {
  final String id; // LID 代號，例：ZSSC
  final String name; // 場館名稱，例：中山運動中心
  final String district; // 行政區，例：中山區

  const SportCenter({
    required this.id,
    required this.name,
    required this.district,
  });

  /// 官方預約網址（依球類與日期動態產生）
  String bookingUrl(String categoryId, String date) {
    return 'https://booking-tpsc.sporetrofit.com/Location/findAllowBookingList'
        '?LID=$id&categoryId=$categoryId&useDate=$date';
  }

  /// 全部 11 個場館清單
  static const List<SportCenter> all = [
    SportCenter(id: 'JJSC', name: '中正運動中心', district: '中正區'),
    SportCenter(id: 'NHSC', name: '內湖運動中心', district: '內湖區'),
    SportCenter(id: 'BTSC', name: '北投運動中心', district: '北投區'),
    SportCenter(id: 'DASC', name: '大安運動中心', district: '大安區'),
    SportCenter(id: 'DTSC', name: '大同運動中心', district: '大同區'),
    SportCenter(id: 'SLSC', name: '士林運動中心', district: '士林區'),
    SportCenter(id: 'SSSC', name: '松山運動中心', district: '松山區'),
    SportCenter(id: 'WHSC', name: '萬華運動中心', district: '萬華區'),
    SportCenter(id: 'WSSC', name: '文山運動中心', district: '文山區'),
    SportCenter(id: 'XYSC', name: '信義運動中心', district: '信義區'),
    SportCenter(id: 'ZSSC', name: '中山運動中心', district: '中山區'),
  ];
}
