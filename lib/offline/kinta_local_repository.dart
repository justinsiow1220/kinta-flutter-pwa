import 'package:sembast/sembast.dart';
import 'kinta_local_db.dart';

/// IndexedDB-backed cache for reference data and offline process work.
class KintaLocalRepository {
  KintaLocalRepository._();
  static final StoreRef<String, Map<String, Object?>> _masterDataStore = stringMapStoreFactory.store('master_data_cache');
  static final StoreRef<String, Map<String, Object?>> _processDraftStore = stringMapStoreFactory.store('process_drafts');
  static final StoreRef<String, Map<String, Object?>> _processStore = stringMapStoreFactory.store('local_processes');
  static final StoreRef<String, Map<String, Object?>> _offlineCredentialStore = stringMapStoreFactory.store('offline_auth_credentials');
  static final StoreRef<String, Map<String, Object?>> _offlineSessionStore = stringMapStoreFactory.store('offline_signed_sessions');

  /// Persists the CI4-signed short-lived grant and its public profile.
  static Future<void> saveSignedSession(Map<String, dynamic> session) async {
    final db = await KintaLocalDatabase.open();
    await _offlineSessionStore.record('current').put(db, Map<String, Object?>.from(session));
  }

  static Future<Map<String, dynamic>?> readSignedSession() async {
    final db = await KintaLocalDatabase.open();
    final record = await _offlineSessionStore.record('current').get(db);
    return record == null ? null : Map<String, dynamic>.from(record);
  }

  static Future<void> clearSignedSession() async {
    final db = await KintaLocalDatabase.open();
    await _offlineSessionStore.record('current').delete(db);
  }

  /// Deletes credentials created by the retired local PBKDF2 implementation.
  static Future<void> clearLegacyOfflineCredentials() async {
    final db = await KintaLocalDatabase.open();
    await _offlineCredentialStore.delete(db);
  }

  static Future<bool> hasOfflineBootstrapData({String? userId}) async {
    final keys = [
      'master-data/machines', 'master-data/sectors', 'master-data/activities',
      'master-data/users?role=supervisor', 'master-data/users?role=operator',
      'master-data/users?role=qc', 'master-data/sales-orders', 'master-data/problems',
      'processes/active', if (userId != null) 'processes/user/$userId' else 'processes/user/unknown',
    ];
    for (final key in keys) {
      if (await readMasterDataList(key) == null) return false;
    }
    return true;
  }
  static Future<void> cacheMasterDataList(String cacheKey, List<Map<String, dynamic>> rows) async {
    final db = await KintaLocalDatabase.open();
    await _masterDataStore.record(cacheKey).put(db, {'cached_at': DateTime.now().toUtc().toIso8601String(), 'rows': rows});
  }

  static Future<List<Map<String, dynamic>>?> readMasterDataList(String cacheKey) async {
    final db = await KintaLocalDatabase.open();
    final rows = (await _masterDataStore.record(cacheKey).get(db))?['rows'];
    if (rows is! List) return null;
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<void> clearCurrentProcessDraft() async {
    final db = await KintaLocalDatabase.open();
    await _processDraftStore.record('current').delete(db);
  }
  static Future<String> createLocalProcess(Map<String, Object?> process) async {
    final db = await KintaLocalDatabase.open();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _processStore.record(id).put(db, {...process, 'local_id': id, 'saved_locally_at': DateTime.now().toUtc().toIso8601String()});
    return id;
  }
  static Future<List<Map<String, dynamic>>> readAllLocalProcesses() async {
    final db = await KintaLocalDatabase.open();
    final rows = await _processStore.find(db);
    return rows.map((r) => Map<String, dynamic>.from(r.value)).toList();
  }
  static Future<List<Map<String, dynamic>>> readPendingLocalProcesses() async =>
      (await readAllLocalProcesses()).where(_needsSynchronization).toList();
  static Future<int> countPendingLocalProcesses() async => (await readPendingLocalProcesses()).length;

  static bool _needsSynchronization(Map<String, dynamic> p) {
    if (p['sync_status'] == 'conflict') return false;
    if (p['sync_pending'] == true || p['sync_status'] == 'pending' || p['server_process_id'] == null) return true;
    bool unsynced(List? rows) => (rows ?? []).whereType<Map>().any((r) => r['id'] == null && r['_sync_status'] != 'synced');
    if (unsynced(p['qc_inspections'] as List?) || unsynced(p['problems'] as List?)) return true;
    final pics = (p['pic_history'] as List? ?? []).whereType<Map>().toList();
    if (pics.skip(1).any((r) => r['_sync_status'] != 'synced')) return true;
    return p['status'] == 'completed' && p['end_sync_status'] != 'synced';
  }

  static Future<Map<String, dynamic>?> readLocalProcess(String id) async {
    final db = await KintaLocalDatabase.open();
    final value = await _processStore.record(id).get(db);
    return value == null ? null : Map<String, dynamic>.from(value);
  }
  static Future<void> updateLocalProcess(String id, Map<String, Object?> changes) async {
    final db = await KintaLocalDatabase.open();
    final current = await _processStore.record(id).get(db);
    if (current == null) throw StateError('Local process $id was not found.');
    await _processStore.record(id).put(db, {...current, ...changes, 'saved_locally_at': DateTime.now().toUtc().toIso8601String()});
  }
  /// Removes only an unsynced local draft; it never deletes a server row.
  static Future<void> deleteUnsyncedLocalProcess(String id) async {
    final db = await KintaLocalDatabase.open();
    final record = await _processStore.record(id).get(db);
    if (record == null) return;
    if (record['server_process_id'] != null || record['sync_status'] == 'synced') {
      throw StateError('Only a process that has never synced can be deleted locally.');
    }
    await _processStore.record(id).delete(db);
  }
  static Future<void> appendLocalProcessItem(String id, String field, Map<String, Object?> item, {bool pendingSync = false}) async {
    final current = await readLocalProcess(id);
    if (current == null) throw StateError('Local process $id was not found.');
    final values = List<Map<String, dynamic>>.from((current[field] as List? ?? []).whereType<Map>().map(Map<String, dynamic>.from));
    values.add({...Map<String, dynamic>.from(item), if (pendingSync) '_sync_status': 'pending'});
    await updateLocalProcess(id, {field: values, if (pendingSync) 'sync_pending': true});
  }
}

