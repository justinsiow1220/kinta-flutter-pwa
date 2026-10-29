/// Process setup selections shared by screens for the current app session.
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

  /// Starts a fresh process while preserving the selected order and team setup.
  void prepareForNewProcess() {
    processId = null;
    localProcessId = null;
    qtyPassed = null;
    qtyRejected = null;
    // Draft selections are intentionally session-only and are not restored.
  }

  /// Kept as a no-op so existing generated callbacks compile. Selection state
  /// is now memory-only and clears when the app is reloaded.
  void persistInBackground() {
    // Intentionally do not save selections into IndexedDB.
  }
}
