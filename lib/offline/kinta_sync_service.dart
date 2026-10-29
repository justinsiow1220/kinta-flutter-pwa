import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class KintaSyncReport {
  const KintaSyncReport({required this.synced, required this.errors});

  final int synced;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
}

/// Sends locally saved process actions to CI4 in a retry-safe order.
class KintaSyncService {
  KintaSyncService._();

  static bool _isRunning = false;

  static Future<KintaSyncReport> syncPendingProcesses() async {
    if (_isRunning) {
      return const KintaSyncReport(
          synced: 0, errors: ['A sync is already running.']);
    }
    if (!KintaAuthService.hasPermission('process.sync')) return const KintaSyncReport(synced: 0, errors: ['The saved offline grant is expired or does not allow sync. Sign in online to renew it.']);
    _isRunning = true;
    var synced = 0;
    final errors = <String>[];
    try {
      final pending = await KintaLocalRepository.readPendingLocalProcesses();
      for (final process in pending) {
        final localId = process['local_id']?.toString();
        if (localId == null || localId.isEmpty) {
          errors.add('A pending local process is missing its local ID.');
          continue;
        }

        final currentUserId = KintaAuthService.currentUser?['id']?.toString();
        if (currentUserId == null || process['actor_user_id']?.toString() != currentUserId) {
          const message = 'This queued process is not bound to the currently signed-in account. It was preserved and not uploaded.';
          errors.add('Process $localId: $message');
          await KintaLocalRepository.updateLocalProcess(localId, {
            'sync_pending': false,
            'sync_status': 'conflict',
            'sync_error': message,
            'conflict_code': 'ACTOR_MISMATCH',
            'conflict_detected_at': DateTime.now().toUtc().toIso8601String(),
          });
          continue;
        }
        final qcSource = _maps(process['qc_inspections']);
        final qcPending = <Map<String, dynamic>>[];
        for (var index = 0; index < qcSource.length; index++) {
          final item = qcSource[index];
          if (item['id'] != null || item['_sync_status'] == 'synced') continue;
          qcPending.add({
            ...item,
            'client_action_key': '$localId:qc:$index',
          });
        }

        final picHistory = _maps(process['pic_history']);
        final picPayload = <Map<String, dynamic>>[];
        for (var index = 0; index < picHistory.length; index++) {
          picPayload.add({
            ...picHistory[index],
            if (index > 0) 'client_action_key': '$localId:pic:$index',
          });
        }

        final problemSource = _maps(process['problems']);
        final problemPending = <Map<String, dynamic>>[];
        for (var index = 0; index < problemSource.length; index++) {
          final item = problemSource[index];
          if (item['id'] != null || item['_sync_status'] == 'synced') continue;
          final problemId = item['problem_id'] ?? item['id'];
          if (problemId == null) continue;
          problemPending.add({
            ...item,
            'problem_id': problemId,
            'client_action_key': '$localId:problem:$problemId:$index',
          });
        }

        final completed = process['status'] == 'completed';
        final body = <String, dynamic>{
          'local_process_id': localId,
          'actor_user_id': KintaAuthService.currentUser?['id'],
          'server_process_id': _asInt(process['server_process_id']),
          'process': {
            'machine_id': process['machine_id'],
            'sector_id': process['sector_id'],
            'activity_id': process['activity_id'],
            'sales_order_id': process['sales_order_id'],
            'current_supervisor_id': process['current_supervisor_id'],
            'operator_ids': process['operator_ids'] ?? <int>[],
            'description': process['description'],
            'started_at': process['started_at'],
          },
          'qc_inspections': qcPending,
          'pic_history': picPayload,
          'problems': problemPending,
          'end': completed
              ? {
                  'client_action_key': '$localId:end',
                  'qty_passed': process['qty_passed'],
                  'qty_rejected': process['qty_rejected'],
                  'remarks': process['remarks'],
                  'ended_at': process['ended_at'],
                }
              : null,
        };

        try {
          final result = await KintaApiService.postJson('processes/sync', body);
          final serverId = _asInt(result['process_id']);
          if (serverId == null) {
            throw const FormatException(
                'CI4 did not return the synchronized process ID.');
          }

          final savedQc = qcSource
              .map((item) => item['id'] == null
                  ? <String, dynamic>{...item, '_sync_status': 'synced'}
                  : item)
              .toList();
          final savedPic = picHistory
              .asMap()
              .entries
              .map((entry) => entry.key == 0
                  ? entry.value
                  : <String, dynamic>{...entry.value, '_sync_status': 'synced'})
              .toList();
          final savedProblems = problemSource
              .map((item) => item['id'] == null
                  ? <String, dynamic>{...item, '_sync_status': 'synced'}
                  : item)
              .toList();

          await KintaLocalRepository.updateLocalProcess(localId, {
            'server_process_id': serverId,
            'sync_status': 'synced',
            'sync_pending': false,
            'sync_error': null,
            'synced_at': DateTime.now().toUtc().toIso8601String(),
            'end_sync_status':
                completed ? 'synced' : process['end_sync_status'],
            'qc_inspections': savedQc,
            'pic_history': savedPic,
            'problems': savedProblems,
          });

          final draft = KintaProcessDraft.instance;
          if (draft.localProcessId == localId) {
            draft.processId = serverId;
            draft.persistInBackground();
          }
          synced++;
        } catch (error) {
          errors.add('Process $localId: $error');
          try {
            if (error is KintaApiException && error.statusCode == 409) {
              await KintaLocalRepository.updateLocalProcess(localId, {
                'sync_pending': false,
                'sync_status': 'conflict',
                'sync_error': error.message,
                'conflict_snapshot': error.data ?? <String, dynamic>{},
                'conflict_detected_at': DateTime.now().toUtc().toIso8601String(),
              });
            } else {
              await KintaLocalRepository.updateLocalProcess(localId, {
                'sync_pending': true,
                'sync_status': 'pending',
                'sync_error': error.toString(),
                'last_sync_attempt_at': DateTime.now().toUtc().toIso8601String(),
              });
            }
          } catch (_) {}
        }
      }
      return KintaSyncReport(synced: synced, errors: errors);
    } finally {
      _isRunning = false;
    }
  }

  static List<Map<String, dynamic>> _maps(Object? value) =>
      (value as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  static int? _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}



