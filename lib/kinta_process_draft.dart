import 'package:flutter/foundation.dart';

import '/offline/kinta_local_repository.dart';

/// Process setup state shared by the existing screens and saved locally.
class KintaProcessDraft {
  KintaProcessDraft._();

  static final KintaProcessDraft instance = KintaProcessDraft._();

  int? machineId;
  int? sectorId;
  int? activityId;
  int? supervisorId;
  int? processId;
  String? localProcessId;
  int? salesOrderId;
  String? soNumber;
  String? customerName;
  int? batchQty;
  int? qtyPassed;
  int? qtyRejected;
  String? machineLabel;
  String? sectorLabel;
  String? activityLabel;
  String? supervisorName;
  List<String> operatorNames = [];
  Set<int> operatorIds = {};

  int get totalProcessed => (qtyPassed ?? 0) + (qtyRejected ?? 0);

  int? get remainingBatchQty {
    final quantity = batchQty;
    if (quantity == null) return null;
    return (quantity - totalProcessed).clamp(0, quantity).toInt();
  }

  Map<String, Object?> toMap() => {
        'machine_id': machineId,
        'sector_id': sectorId,
        'activity_id': activityId,
        'supervisor_id': supervisorId,
        'process_id': processId,
        'local_process_id': localProcessId,
        'sales_order_id': salesOrderId,
        'so_number': soNumber,
        'customer_name': customerName,
        'batch_qty': batchQty,
        'qty_passed': qtyPassed,
        'qty_rejected': qtyRejected,
        'machine_label': machineLabel,
        'sector_label': sectorLabel,
        'activity_label': activityLabel,
        'supervisor_name': supervisorName,
        'operator_names': operatorNames,
        'operator_ids': operatorIds.toList(),
      };

  static Future<void> restore() async {
    try {
      final saved = await KintaLocalRepository.readCurrentProcessDraft();
      if (saved == null) return;
      final draft = instance;
      draft.machineId = _asInt(saved['machine_id']);
      draft.sectorId = _asInt(saved['sector_id']);
      draft.activityId = _asInt(saved['activity_id']);
      draft.supervisorId = _asInt(saved['supervisor_id']);
      draft.processId = _asInt(saved['process_id']);
      draft.localProcessId = saved['local_process_id']?.toString();
      draft.salesOrderId = _asInt(saved['sales_order_id']);
      draft.soNumber = saved['so_number']?.toString();
      draft.customerName = saved['customer_name']?.toString();
      draft.batchQty = _asInt(saved['batch_qty']);
      draft.qtyPassed = _asInt(saved['qty_passed']);
      draft.qtyRejected = _asInt(saved['qty_rejected']);
      draft.machineLabel = saved['machine_label']?.toString();
      draft.sectorLabel = saved['sector_label']?.toString();
      draft.activityLabel = saved['activity_label']?.toString();
      draft.supervisorName = saved['supervisor_name']?.toString();
      draft.operatorNames = (saved['operator_names'] as List? ?? [])
          .map((name) => name.toString())
          .toList();
      draft.operatorIds = (saved['operator_ids'] as List? ?? [])
          .map(_asInt)
          .whereType<int>()
          .toSet();
    } catch (error) {
      debugPrint('Could not restore KINTA process draft: $error');
    }
  }

  /// Persists selection changes without blocking generated dropdown callbacks.
  void persistInBackground() {
    KintaLocalRepository.saveCurrentProcessDraft(toMap()).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not save KINTA process draft: $error');
      },
    );
  }

  static int? _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
