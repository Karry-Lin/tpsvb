import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';

/// 負責呼叫 booking-tpsc.sporetrofit.com 後端 API
class BookingApiService {
  static const String _baseUrl = 'https://booking-tpsc.sporetrofit.com';

  final Dio _dio;

  BookingApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            // 不在 BaseOptions.headers 設定 Content-Type
            // 讓各別請求的 Options.contentType 控制，避免干擾 JSON 回應解析
            headers: {
              'User-Agent': 'Mozilla/5.0 (Android; Mobile) tpsvb/1.0',
              'Accept': 'application/json, text/javascript, */*; q=0.01',
              'Referer': 'https://booking-tpsc.sporetrofit.com/',
              'X-Requested-With': 'XMLHttpRequest',
            },
            // 不自動跟隨重定向，改由程式邏輯判斷是否重試
            followRedirects: false,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[API] ▶ ${options.method} ${options.uri}');
            debugPrint('[API]   data=${options.data}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            final body = response.data?.toString() ?? '';
            debugPrint('[API] ◀ ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('[API]   body(500)=${body.substring(0, body.length.clamp(0, 500))}');
            handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint('[API] ✗ ${e.type} ${e.requestOptions.uri}');
            debugPrint('[API]   msg=${e.message}');
            debugPrint('[API]   resp=${e.response?.data}  status=${e.response?.statusCode}');
            handler.next(e);
          },
        ),
      );
    }
  }

  /// 判斷此狀態碼是否可以重試（302 限流重定向、429 太多請求、5xx 伺服器錯誤）
  bool _isRetryable(DioException e) {
    final status = e.response?.statusCode;
    if (status != null && (status == 302 || status == 429 || status >= 500)) {
      return true;
    }
    // 連線/逾時類錯誤也可重試
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  /// 帶重試機制的 POST 請求（最多重試 3 次，指數退避：500ms / 1000ms / 2000ms）
  Future<Response<dynamic>> _postWithRetry(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        attempt++;
        if (attempt > maxRetries || !_isRetryable(e)) {
          rethrow;
        }
        // 指數退避：500ms → 1000ms → 2000ms
        final delay = Duration(milliseconds: 500 * (1 << (attempt - 1)));
        debugPrint('[API] ↻ retry $attempt/$maxRetries after ${delay.inMilliseconds}ms (${e.response?.statusCode ?? e.type})');
        await Future.delayed(delay);
      }
    }
  }

  /// API-01：查詢特定場館、球類在日期區間內開放預約的日期
  ///
  /// 實際回傳格式：[{"title":"開放預約","start":"2026-03-08","allDay":true,...}]
  Future<List<String>> fetchAllowBookingCalendars({
    required String lid,
    required String categoryId,
    required String start,
    required String end,
  }) async {
    try {
      final response = await _postWithRetry(
        '/Location/findAllowBookingCalendars',
        data: 'LID=$lid&categoryId=$categoryId&start=$start&end=$end',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      return _extractDates(response.data);
    } on DioException catch (e) {
      throw ApiException(_formatDioError(e));
    } catch (e) {
      throw ApiException('資料解析錯誤：$e');
    }
  }

  /// 從 API-01 回應中提取日期清單
  List<String> _extractDates(dynamic data) {
    if (data == null) return [];

    // 若 Dio 未自動解析（回應是字串），手動解析
    dynamic decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } catch (_) {
        return [];
      }
    }

    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final raw = decoded['rows'] ?? decoded['data'] ?? decoded['items'];
      if (raw is List) {
        items = raw;
      } else {
        return [];
      }
    } else {
      return [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => AllowBookingCalendarItem.fromJson(item).date)
        .where((d) => d.isNotEmpty)
        .toList();
  }

  /// API-02：查詢特定場館、球類、特定日期的場地與時段清單
  ///
  /// 實際回傳格式：{"rows":[{"LSID":"...","LSIDName":"...","StartTime":{...},...}]}
  Future<List<BookingListItem>> fetchBookingList({
    required String lid,
    required String categoryId,
    required String useDate,
  }) async {
    try {
      final response = await _postWithRetry(
        '/Location/findAllowBookingList',
        queryParameters: {
          'LID': lid,
          'categoryId': categoryId,
          'useDate': useDate,
        },
        data: 'rows=200&page=1&sord=asc',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      return _extractBookingItems(response.data, lid, useDate);
    } on DioException catch (e) {
      throw ApiException(_formatDioError(e));
    } catch (e) {
      throw ApiException('資料解析錯誤：$e');
    }
  }

  /// 從 API-02 回應中提取場地時段清單
  List<BookingListItem> _extractBookingItems(
    dynamic data,
    String sportCenterId,
    String date,
  ) {
    if (data == null) return [];

    dynamic decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } catch (_) {
        return [];
      }
    }

    List<dynamic> rows;
    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map) {
      final raw = decoded['rows'] ?? decoded['data'] ?? decoded['items'];
      if (raw is List) {
        rows = raw;
      } else {
        return [];
      }
    } else {
      return [];
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map((item) => BookingListItem.fromJson(item, sportCenterId, date))
        .toList();
  }

  String _formatDioError(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '連線逾時，請確認網路後重試';
      case DioExceptionType.connectionError:
        return '無法連線，請確認網路連線';
      case DioExceptionType.badResponse:
        if (status == 302 || status == 429) {
          return '伺服器暫時限制請求，請稍後再試';
        }
        return 'API 回應異常（$status）';
      default:
        return '網路錯誤：${e.message}';
    }
  }
}

/// API 呼叫失敗例外
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
