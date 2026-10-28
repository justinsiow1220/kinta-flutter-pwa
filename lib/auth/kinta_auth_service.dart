import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '/kinta_api_service.dart';
import '/offline/kinta_local_repository.dart';

/// Online login/register and device-local validation of a CI4 signed grant.
class KintaAuthService {
  KintaAuthService._();
  static const _issuer = 'kinta-ci4';
  static const _audience = 'kinta-flutter';
  static const _keyId = 'kinta-local-rsa-1';
  static const _modulus = 'u7U8-zKrUBQsmBXzW0fwHamj4AWN8I2ny3_5SbfGUvrs0TTfnc2sDv_vcm93Kz_FCCeL3WOhymZy0l8I-CpNOT39XHoIa8aytdXqVWXr7AO5X2SNN5GfyHnWoZZogC4v1gJKv1GPLOYnSYeze-6Bs8aCl7kbiO0_DBLEJgJ8naeC34dmCH338mge8sGGLWE3Hp55HFnc7N8cO0Vplhcq-1X5a4Tyv0rXqFVENockMxL8mbpWwwGvY1LCUgUC1SgDF4ugUUZwuzSoCuxtLwT5cKvq2pCc0wE_wrDRp4ckAhzVeSN1ju5mWgiK4xjMfPcbUcCkINtTGHqjABgyFuopwQ';
  static const _exponent = 'AQAB';
  static Map<String, dynamic>? _currentUser;
  static String? _grant;
  static int? _expiresAt;
  static bool _offlineReady = false;
  static List<String> _permissions = <String>[];
  static bool get isAuthenticated => _currentUser != null && _grant != null && _expiresAt != null && _expiresAt! > DateTime.now().millisecondsSinceEpoch ~/ 1000;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get bearerGrant => isAuthenticated ? _grant : null;
  static bool get offlineReady => _offlineReady && isAuthenticated;
  static int? get grantExpiresAt => _expiresAt;
  static List<String> get permissions => List.unmodifiable(_permissions);
  static bool hasPermission(String permission) => isAuthenticated && _permissions.contains(permission);

  static Future<void> restoreSavedSession() async {
    await KintaLocalRepository.clearLegacyOfflineCredentials();
    final saved = await KintaLocalRepository.readSignedSession();
    if (saved == null) return;
    final token = saved['grant'];
    if (token is! String) { await KintaLocalRepository.clearSignedSession(); return; }
    final claims = await _verifyGrant(token);
    if (claims == null) { await KintaLocalRepository.clearSignedSession(); return; }
    final cachedDataReady = await KintaLocalRepository.hasOfflineBootstrapData();
    _applySession(token, claims, user: saved['user'], offlineReady: saved['offline_ready'] == true && cachedDataReady);
  }

  static Future<Map<String, dynamic>> register({required String employeeNo, required String name, required String username, required String password}) async {
    final result = await KintaApiService.postJson('auth/register', {'employee_no': employeeNo.trim(), 'name': name.trim(), 'username': username.trim().toLowerCase(), 'password': password}, authenticated: false);
    await _acceptOnlineAuth(result);
    return _currentUser!;
  }

  static Future<Map<String, dynamic>> login({required String username, required String password}) async {
    final result = await KintaApiService.postJson('auth/login', {'username': username.trim().toLowerCase(), 'password': password}, authenticated: false);
    await _acceptOnlineAuth(result);
    return _currentUser!;
  }

  static Future<void> _acceptOnlineAuth(Map<String, dynamic> response) async {
    final token = response['offline_grant'];
    if (token is! String) throw const FormatException('CI4 did not return the signed offline access grant.');
    final claims = await _verifyGrant(token);
    if (claims == null) throw const FormatException('CI4 returned an invalid signed offline access grant.');
    _applySession(token, claims, user: response['user'], offlineReady: false);
    await KintaLocalRepository.saveSignedSession({'grant': token, 'user': response['user'], 'offline_ready': false, 'saved_at': DateTime.now().toIso8601String()});
    try {
      await KintaApiService.preloadMasterData();
      _offlineReady = true;
      await KintaLocalRepository.saveSignedSession({'grant': token, 'user': response['user'], 'offline_ready': true, 'saved_at': DateTime.now().toIso8601String()});
    } catch (error) {
      // Keep the online session usable; the home screen offers preload retry.
      _offlineReady = false;
    }
  }

  static Future<bool> retryOfflinePreload() async {
    if (!isAuthenticated) return false;
    await KintaApiService.preloadMasterData();
    _offlineReady = true;
    await KintaLocalRepository.saveSignedSession({'grant': _grant!, 'user': _currentUser, 'offline_ready': true, 'saved_at': DateTime.now().toIso8601String()});
    return true;
  }

  static Future<bool> continueOffline() async {
    final saved = await KintaLocalRepository.readSignedSession();
    if (saved == null || saved['offline_ready'] != true || saved['grant'] is! String || !await KintaLocalRepository.hasOfflineBootstrapData()) return false;
    final claims = await _verifyGrant(saved['grant'] as String);
    if (claims == null) return false;
    _applySession(saved['grant'] as String, claims, user: saved['user'], offlineReady: true);
    return true;
  }

  static void _applySession(String token, Map<String, dynamic> claims, {required Object? user, required bool offlineReady}) {
    _grant = token;
    _expiresAt = claims['exp'] as int;
    _offlineReady = offlineReady;
    _permissions = List<String>.from(claims['permissions'] as List);
    _currentUser = user is Map ? Map<String, dynamic>.from(user) : {'id': claims['user_id'], 'role': claims['role']};
  }

  static Future<Map<String, dynamic>?> _verifyGrant(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final header = jsonDecode(utf8.decode(_decode(parts[0]))) as Map<String, dynamic>;
      final claims = jsonDecode(utf8.decode(_decode(parts[1]))) as Map<String, dynamic>;
      if (header['alg'] != 'RS256' || header['typ'] != 'JWT' || header['kid'] != _keyId || claims['iss'] != _issuer || claims['aud'] != _audience || claims['offline_allowed'] != true) return null;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (claims['exp'] is! int || claims['exp'] <= now || claims['nbf'] is! int || claims['nbf'] > now + 60 || claims['iat'] is! int || claims['iat'] > now + 60 || claims['user_id'] is! int || claims['sub'] != '${claims['user_id']}' || claims['role'] is! String || claims['permissions'] is! List) return null;
      final algorithm = RsaSsaPkcs1v15(Sha256());
      final publicKey = RsaPublicKey(e: _decode(_exponent), n: _decode(_modulus));
      final signature = Signature(_decode(parts[2]), publicKey: publicKey);
      if (!await algorithm.verify(utf8.encode('${parts[0]}.${parts[1]}'), signature: signature)) return null;
      return claims;
    } catch (_) { return null; }
  }

  static List<int> _decode(String value) => base64Url.decode(base64Url.normalize(value));

  static Future<void> logout() async {
    _currentUser = null; _grant = null; _expiresAt = null; _offlineReady = false; _permissions = <String>[];
    await KintaLocalRepository.clearSignedSession();
  }
}





