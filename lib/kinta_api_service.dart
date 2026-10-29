import 'dart:convert';
import 'package:http/http.dart' as http;
import '/auth/kinta_auth_service.dart';
import '/offline/kinta_local_repository.dart';

class KintaApiException implements Exception {
  KintaApiException(this.message, {required this.statusCode, this.errorCode, this.data});
  final String message;
  final int statusCode;
  final String? errorCode;
  final Map<String, dynamic>? data;
  @override String toString() => 'HTTP $statusCode: $message';
}

/// HTTP boundary for CI4; only transport failures may use reference-data cache.
class KintaApiService {
  KintaApiService._();
  static const String baseUrl = 'http://localhost/kinta/public/api';
  static Map<String, String> _headers({bool json = false, bool authenticated = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final grant = authenticated ? KintaAuthService.bearerGrant : null;
    if (grant != null) headers['Authorization'] = 'Bearer $grant';
    return headers;
  }

  static Future<List<Map<String, dynamic>>> getList(String path, {bool allowCachedOfflineFallback = true}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$path'), headers: _headers());
      final payload = _decode(response.body, 'GET $path');
      if (response.statusCode < 200 || response.statusCode >= 300 || payload?['success'] != true || payload?['data'] is! List) {
        throw _exception(response.statusCode, payload, 'GET $path failed.');
      }
      final rows = (payload!['data'] as List).whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();
      try { await KintaLocalRepository.cacheMasterDataList(_cacheKey(path), rows); } catch (_) {}
      return rows;
    } on http.ClientException {
      if (!allowCachedOfflineFallback) rethrow;
      var cached = await KintaLocalRepository.readMasterDataList(_cacheKey(path));
      if (cached == null && path.startsWith('master-data/activities?sector_id=')) {
        final allActivities = await KintaLocalRepository.readMasterDataList('master-data/activities');
        final sectorId = Uri.parse('http://localhost/$path').queryParameters['sector_id'];
        if (allActivities != null) cached = allActivities.where((row) => row['sector_id'].toString() == sectorId).toList();
      }
      if (cached != null) return cached;
      rethrow;
    }
  }

  static String _cacheKey(String path) {
    if (path != 'processes') return path;
    final userId = KintaAuthService.currentUser?['id']?.toString();
    return 'processes/user/${userId ?? 'unknown'}';
  }
  static String processHistoryCacheKey() => _cacheKey('processes');

  /// Refreshes all lists required by process setup while online; only then is
  /// the current account marked as offline-ready.
  static Future<void> preloadMasterData() async {
    const paths = [
      'master-data/machines', 'master-data/sectors', 'master-data/activities',
      'master-data/users?role=supervisor', 'master-data/users?role=operator',
      'master-data/users?role=qc', 'master-data/sales-orders', 'master-data/problems', 'processes/active', 'processes',
    ];
    await Future.wait(paths.map((p) => getList(p, allowCachedOfflineFallback: false)));
  }

  static Future<Map<String, dynamic>> getMap(String path) async {
    final response = await http.get(Uri.parse('$baseUrl/$path'), headers: _headers());
    final payload = _decode(response.body, 'GET $path');
    if (response.statusCode < 200 || response.statusCode >= 300 || payload?['success'] != true || payload?['data'] is! Map) throw _exception(response.statusCode, payload, 'GET $path failed.');
    return Map<String, dynamic>.from(payload!['data'] as Map);
  }

  static Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final response = await http.put(Uri.parse('$baseUrl/$path'), headers: _headers(json: true), body: jsonEncode(body));
    final payload = _decode(response.body, 'PUT $path');
    if (response.statusCode < 200 || response.statusCode >= 300 || payload?['success'] != true) throw _exception(response.statusCode, payload, 'PUT $path failed.');
    return payload?['data'] is Map ? Map<String, dynamic>.from(payload!['data'] as Map) : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body, {bool authenticated = true}) async {
    final response = await http.post(Uri.parse('$baseUrl/$path'), headers: _headers(json: true, authenticated: authenticated), body: jsonEncode(body));
    final payload = _decode(response.body, 'POST $path');
    if (response.statusCode < 200 || response.statusCode >= 300 || payload?['success'] != true || payload?['data'] is! Map) throw _exception(response.statusCode, payload, 'POST $path failed.');
    return Map<String, dynamic>.from(payload!['data'] as Map);
  }

  static Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl/$path'), headers: _headers());
    final payload = _decode(response.body, 'DELETE $path');
    if (response.statusCode < 200 || response.statusCode >= 300 || payload?['success'] != true) {
      throw _exception(response.statusCode, payload, 'DELETE $path failed.');
    }
    return payload?['data'] is Map ? Map<String, dynamic>.from(payload!['data'] as Map) : <String, dynamic>{};
  }
  static Map<String, dynamic>? _decode(String body, String label) {
    try { final value = jsonDecode(body); return value is Map<String, dynamic> ? value : null; }
    on FormatException { throw FormatException('CI4 returned invalid JSON for $label.'); }
  }
  static KintaApiException _exception(int status, Map<String, dynamic>? p, String fallback) => KintaApiException(p?['message']?.toString() ?? fallback, statusCode: status, errorCode: p?['error_code']?.toString(), data: p?['data'] is Map ? Map<String, dynamic>.from(p!['data'] as Map) : null);
}


