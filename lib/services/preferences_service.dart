import 'package:shared_preferences/shared_preferences.dart';

/// 使用者偏好設定（儲存於 SharedPreferences）
class PreferencesService {
  static const String _keySportType = 'pref_sport_type';
  static const String _keySelectedCenters = 'pref_selected_centers';
  static const String _keyDateRangeDays = 'pref_date_range_days';
  static const String _keyTimeFilter = 'pref_time_filter';

  final SharedPreferences _prefs;

  PreferencesService._(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  /// 偏好的運動類型（categoryId）
  String getSportType() => _prefs.getString(_keySportType) ?? 'Badminton';
  Future<void> setSportType(String value) => _prefs.setString(_keySportType, value);

  /// 選取的場館 LID 清單（空清單 = 全選）
  List<String> getSelectedCenters() => _prefs.getStringList(_keySelectedCenters) ?? [];
  Future<void> setSelectedCenters(List<String> value) =>
      _prefs.setStringList(_keySelectedCenters, value);

  /// 查詢日期範圍（天數，預設 7）
  int getDateRangeDays() => _prefs.getInt(_keyDateRangeDays) ?? 7;
  Future<void> setDateRangeDays(int value) => _prefs.setInt(_keyDateRangeDays, value);

  /// 時段篩選：0=全天, 1=早上, 2=下午, 3=晚上
  int getTimeFilter() => _prefs.getInt(_keyTimeFilter) ?? 0;
  Future<void> setTimeFilter(int value) => _prefs.setInt(_keyTimeFilter, value);
}
