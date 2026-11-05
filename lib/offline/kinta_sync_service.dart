import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class KintaSyncReport {
  const KintaSyncReport({
    required this.synced,
    required this.errors,
    this.salesOrdersSynced = 0,
    this.needsReview = 0,
    this.waitingForMasterData = 0,
  });

  final int synced;
  final List<String> errors;
  final int salesOrdersSynced;
  final int needsReview;
  final int waitingForMasterData;

  bool get hasErrors => errors.isNotEmpty;
}

/// Sends locally saved process actions to CI4 in a retry-safe order.
class KintaSyncService {
  KintaSyncService._();

  static Future<KintaSyncReport>? _runningSync;
  static DateTime? _lastMasterDataRetryCheckAt;

  static Future<int> retryWaitingProcessesWhenMasterDataIsActive({
    required String actorUserId,
  }) async {
    final localProcesses = await KintaLocalRepository.readAllLocalProcesses();
    final waiting = localProcesses.where((process) {
      if (process['actor_user_id']?.toString() != actorUserId) return false;
      final status = process['sync_status'];
      final code = process['conflict_code'];
      return (status == 'waiting_for_master_data' &&
              ['MACHINE_INACTIVE', 'SECTOR_INACTIVE'].contains(code)) ||
          (status == 'conflict' &&
              code == 'HTTP_422' &&
              process['sync_error'] ==
                  'The selected machine or sector is no longer active.');
    }).toList();
    if (waiting.isEmpty) return 0;

    final now = DateTime.now();
    if (_lastMasterDataRetryCheckAt != null &&
        now.difference(_lastMasterDataRetryCheckAt!) <
            const Duration(seconds: 15)) {
      return 0;
    }
    _lastMasterDataRetryCheckAt = now;

    final needsMachineList = waiting.any((process) =>
        process['conflict_code'] == 'MACHINE_INACTIVE' ||
        process['conflict_code'] == 'HTTP_422');
    final needsSectorList = waiting.any((process) =>
        process['conflict_code'] == 'SECTOR_INACTIVE' ||
        process['conflict_code'] == 'HTTP_422');
    final results = await Future.wait<List<Map<String, dynamic>>>([
      if (needsMachineList)
        KintaApiService.getList(
          'master-data/machines',
          allowCachedOfflineFallback: false,
        )
      else
        Future.value(<Map<String, dynamic>>[]),
      if (needsSectorList)
        KintaApiService.getList(
          'master-data/sectors',
          allowCachedOfflineFallback: false,
        )
      else
        Future.value(<Map<String, dynamic>>[]),
    ]);
    final activeMachineIds =
        results[0].map((machine) => machine['id'].toString()).toSet();
    final activeSectorIds =
        results[1].map((sector) => sector['id'].toString()).toSet();

    var requeued = 0;
    for (final process in waiting) {
      final code = process['conflict_code'];
      final isLegacyMachineOrSectorError = code == 'HTTP_422';
      final machineReady = !needsMachineList ||
          activeMachineIds.contains(process['machine_id']?.toString());
      final sectorReady = !needsSectorList ||
          activeSectorIds.contains(process['sector_id']?.toString());
      final relevantMasterDataReady = isLegacyMachineOrSectorError
          ? machineReady && sectorReady
          : code == 'MACHINE_INACTIVE'
              ? machineReady
              : sectorReady;
      if (!relevantMasterDataReady) continue;

      await KintaLocalRepository.updateLocalProcess(
        process['local_id'].toString(),
        {
          'sync_pending': true,
          'sync_status': 'pending',
          'sync_error': null,
          'sync_retry_count': 0,
          'next_sync_attempt_at': null,
          'conflict_code': null,
          'conflict_snapshot': null,
          'conflict_detected_at': null,
        },
      );
      requeued++;
    }
    return requeued;
  }

  static Future<KintaSyncReport> syncPendingProcesses(
      {bool forceRetry = false}) {
    if (!KintaAuthService.hasPermission('process.sync')) {
      return Future.value(const KintaSyncReport(
        synced: 0,
        errors: [
          'The saved offline grant is expired or does not allow sync. Sign in online to renew it.',
        ],
      ));
    }

    // Auto-retry and manual Sync callers share one result instead of
    // reporting a misleading error when they overlap.
    final runningSync = _runningSync;
    if (runningSync != null) return runningSync;

    final sync = _performSync(forceRetry: forceRetry);
    _runningSync = sync;
    return sync;
  }

  static Future<KintaSyncReport> _performSync(
      {required bool forceRetry}) async {
    var synced = 0;
    var salesOrdersSynced = 0;
    var needsReview = 0;
    var waitingForMasterData = 0;
    final errors = <String>[];
    try {
      final actorUserId = KintaAuthService.currentUser?['id']?.toString();
      if (actorUserId != null) {
        final pendingOrders = await KintaLocalRepository.readPendingSalesOrders(
          actorUserId: actorUserId,
        );
        for (final order in pendingOrders) {
          final soNumber = order['so_number']?.toString() ?? '';
          try {
            await KintaApiService.postJson('master-data/sales-orders', {
              'so_number': soNumber,
              'customer_name': order['customer_name'],
              'batch_qty': order['batch_qty'],
            });
            await KintaLocalRepository.removePendingSalesOrder(soNumber);
            salesOrdersSynced++;
          } catch (error) {
            errors.add('Sales order $soNumber: $error');
            try {
              final savedAt = DateTime.now().toUtc();
              await KintaLocalRepository.savePendingSalesOrder({
                ...order,
                'last_sync_error': error.toString(),
                'last_sync_attempt_at': savedAt.toIso8601String(),
                'sync_retry_count':
                    ((_asInt(order['sync_retry_count']) ?? 0) + 1),
              });
            } catch (_) {
              // Keep the queued order even if recording its error fails.
            }
          }
        }
      }
      final pending = await KintaLocalRepository.readPendingLocalProcesses();
      for (final process in pending) {
        final localId = process['local_id']?.toString();
        if (localId == null || localId.isEmpty) {
          errors.add('A pending local process is missing its local ID.');
          continue;
        }

        if (!forceRetry && !_retryIsDue(process)) continue;

        final currentUserId = KintaAuthService.currentUser?['id']?.toString();
        if (currentUserId == null ||
            process['actor_user_id']?.toString() != currentUserId) {
          const message =
              'This queued process is not bound to the currently signed-in account. It was preserved and not uploaded.';
          errors.add('Process $localId: $message');
          await KintaLocalRepository.updateLocalProcess(localId, {
            'sync_pending': false,
            'sync_status': 'conflict',
            'sync_error': message,
            'conflict_code': 'ACTOR_MISMATCH',
            'conflict_detected_at': DateTime.now().toUtc().toIso8601String(),
          });
          needsReview++;
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
        final processPayload = <String, dynamic>{
          'machine_id': process['machine_id'],
          'sector_id': process['sector_id'],
          'activity_id': process['activity_id'],
          'sales_order_id': process['sales_order_id'],
          'current_supervisor_id': process['current_supervisor_id'],
          'operator_ids': process['operator_ids'] ?? <int>[],
          'description': process['description'],
          'started_at': process['started_at'],
        };
        final body = <String, dynamic>{
          'local_process_id': localId,
          'actor_user_id': KintaAuthService.currentUser?['id'],
          'server_process_id': _asInt(process['server_process_id']),
          'process': processPayload,
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
          if (processPayload['sales_order_id'] == null &&
              (process['so_number']?.toString().trim().isNotEmpty ?? false) &&
              (process['customer_name']?.toString().trim().isNotEmpty ??
                  false) &&
              _asInt(process['batch_qty']) != null) {
            final order = await KintaApiService.postJson(
              'master-data/sales-orders',
              {
                'so_number': process['so_number'],
                'customer_name': process['customer_name'],
                'batch_qty': _asInt(process['batch_qty']),
              },
            );
            final salesOrderId = _asInt(order['id']);
            if (salesOrderId == null) {
              throw const FormatException(
                  'CI4 did not return the synchronized sales-order ID.');
            }
            processPayload['sales_order_id'] = salesOrderId;
            await KintaLocalRepository.updateLocalProcess(localId, {
              'sales_order_id': salesOrderId,
            });
            try {
              await KintaLocalRepository.removePendingSalesOrder(
                process['so_number'].toString(),
              );
            } catch (_) {}
          }
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
            'sync_retry_count': 0,
            'next_sync_attempt_at': null,
            'last_sync_attempt_at': null,
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
            draft.salesOrderId = _asInt(processPayload['sales_order_id']);
            draft.persistInBackground();
          }
          synced++;
        } catch (error) {
          errors.add('Process $localId: $error');
          try {
            if (error is KintaApiException &&
                ['MACHINE_INACTIVE', 'SECTOR_INACTIVE']
                    .contains(error.errorCode)) {
              await KintaLocalRepository.updateLocalProcess(localId, {
                'sync_pending': false,
                'sync_status': 'waiting_for_master_data',
                'sync_error': error.message,
                'conflict_code': error.errorCode,
                'conflict_snapshot': error.data ?? <String, dynamic>{},
                'conflict_detected_at':
                    DateTime.now().toUtc().toIso8601String(),
                'sync_retry_count': 0,
                'next_sync_attempt_at': null,
              });
              waitingForMasterData++;
            } else if (error is KintaApiException && _requiresReview(error)) {
              await KintaLocalRepository.updateLocalProcess(localId, {
                'sync_pending': false,
                'sync_status': 'conflict',
                'sync_error': error.message,
                'conflict_code': error.errorCode ?? 'HTTP_${error.statusCode}',
                'conflict_snapshot': error.data ?? <String, dynamic>{},
                'conflict_detected_at':
                    DateTime.now().toUtc().toIso8601String(),
                'sync_retry_count': 0,
                'next_sync_attempt_at': null,
              });
              needsReview++;
            } else {
              final retryCount = (_asInt(process['sync_retry_count']) ?? 0) + 1;
              final exponent = (retryCount - 1).clamp(0, 5).toInt();
              final delaySeconds =
                  (10 * (1 << exponent)).clamp(10, 300).toInt();
              final attemptedAt = DateTime.now().toUtc();
              await KintaLocalRepository.updateLocalProcess(localId, {
                'sync_pending': true,
                'sync_status': 'pending',
                'sync_error': error.toString(),
                'sync_retry_count': retryCount,
                'last_sync_attempt_at': attemptedAt.toIso8601String(),
                'next_sync_attempt_at': attemptedAt
                    .add(Duration(seconds: delaySeconds))
                    .toIso8601String(),
              });
            }
          } catch (_) {}
        }
      }
      return KintaSyncReport(
        synced: synced,
        salesOrdersSynced: salesOrdersSynced,
        errors: errors,
        needsReview: needsReview,
        waitingForMasterData: waitingForMasterData,
      );
    } finally {
      _runningSync = null;
    }
  }

  static List<Map<String, dynamic>> _maps(Object? value) =>
      (value as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  static bool _requiresReview(KintaApiException error) {
    final status = error.statusCode;
    // Timeouts, throttling, and server errors can recover, so keep them queued.
    if (status == 408 || status == 425 || status == 429 || status >= 500) {
      return false;
    }

    // Other 4xx responses and explicit API error codes need review/fixing.
    return (status >= 400 && status < 500) || error.errorCode != null;
  }

  static int? _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static bool _retryIsDue(Map<String, dynamic> process) {
    final nextAttempt = DateTime.tryParse(
      process['next_sync_attempt_at']?.toString() ?? '',
    );
    return nextAttempt == null || !DateTime.now().toUtc().isBefore(nextAttempt);
  }
}
