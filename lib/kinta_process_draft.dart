/// Temporary state shared between the existing process setup screens.
/// Values live only in memory and are not persisted locally.
class KintaProcessDraft {
  KintaProcessDraft._();

  static final KintaProcessDraft instance = KintaProcessDraft._();

  int? machineId;
  int? sectorId;
  int? activityId;
  int? supervisorId;
  int? processId;
  int? salesOrderId;
  String? soNumber;
  String? customerName;
  int? batchQty;
  String? machineLabel;
  String? sectorLabel;
  String? activityLabel;
  String? supervisorName;
  List<String> operatorNames = [];
  Set<int> operatorIds = {};
}
