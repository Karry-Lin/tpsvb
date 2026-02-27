import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_api_service.dart';
import '../services/booking_repository.dart';
import '../services/preferences_service.dart';
import '../services/query_cache.dart';

/// 全域快取單例
final queryCacheProvider = Provider<QueryCache>((_) => QueryCache());

/// API Service
final apiServiceProvider = Provider<BookingApiService>((_) => BookingApiService());

/// Repository
final repositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    api: ref.read(apiServiceProvider),
    cache: ref.read(queryCacheProvider),
  );
});

/// 偏好設定（非同步初始化）
final preferencesProvider = FutureProvider<PreferencesService>(
  (_) => PreferencesService.create(),
);
