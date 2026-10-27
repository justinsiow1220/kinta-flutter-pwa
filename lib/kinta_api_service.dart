import 'dart:convert';

import 'package:http/http.dart' as http;

/// Small HTTP client for this project's CI4 backend.
class KintaApiService {
  KintaApiService._();

  static const String baseUrl = 'http://localhost:8080/api';

  static Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$path'),
      headers: const {'Accept': 'application/json'},
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException('CI4 returned invalid JSON for GET $path.');
    }

    final payload = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload?['success'] != true ||
        payload?['data'] is! List) {
      final message = payload?['message']?.toString() ?? response.body;
      throw Exception(
          'GET $path failed (HTTP ${response.statusCode}): $message');
    }

    return (payload!['data'] as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<Map<String, dynamic>> getMap(String path) async {
    final response = await http.get(Uri.parse('$baseUrl/$path'),
        headers: const {'Accept': 'application/json'});
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['success'] != true ||
        payload['data'] is! Map) {
      throw Exception(payload['message']?.toString() ?? 'GET $path failed.');
    }
    return Map<String, dynamic>.from(payload['data'] as Map);
  }

  static Future<Map<String, dynamic>> putJson(
      String path, Map<String, dynamic> body) async {
    final response = await http.put(Uri.parse('$baseUrl/$path'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException('CI4 returned invalid JSON for PUT $path.');
    }
    final payload = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload?['success'] != true) {
      throw Exception(payload?['message']?.toString() ??
          'PUT $path failed (HTTP ${response.statusCode}).');
    }
    return payload?['data'] is Map
        ? Map<String, dynamic>.from(payload!['data'] as Map)
        : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException('CI4 returned invalid JSON for POST $path.');
    }
    final payload = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload?['success'] != true ||
        payload?['data'] is! Map) {
      final message = payload?['message']?.toString() ?? response.body;
      throw Exception(
          'POST $path failed (HTTP ${response.statusCode}): $message');
    }
    return Map<String, dynamic>.from(payload!['data'] as Map);
  }
}
