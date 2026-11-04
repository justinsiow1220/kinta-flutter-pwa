import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';
import '/utils/kinta_time.dart';

class QCInspectionWidget extends StatefulWidget {
  const QCInspectionWidget({super.key});
  @override
  State<QCInspectionWidget> createState() => _QCInspectionWidgetState();
}

class _QCInspectionWidgetState extends State<QCInspectionWidget> {
  List<Map<String, dynamic>> _qcUsers = [];
  List<Map<String, dynamic>> _inspections = [];
  int? _qcUserId;
  final _quantity = TextEditingController();
  final _qcSearch = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadQcUsers();
    _loadInspectionHistory();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _qcSearch.dispose();
    super.dispose();
  }

  Future<void> _loadQcUsers() async {
    try {
      final users = await KintaApiService.getList('master-data/users?role=qc');
      if (mounted) setState(() => _qcUsers = users);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadInspectionHistory() async {
    final draft = KintaProcessDraft.instance;
    final localId = draft.localProcessId;
    final processId = draft.processId;
    var history = <Map<String, dynamic>>[];
    if (processId != null) {
      try {
        history = await KintaApiService.getList(
            'processes/$processId/qc-inspections');
      } catch (_) {
        // Use the local process copy while offline.
      }
    }
    if (localId != null) {
      final local = await KintaLocalRepository.readLocalProcess(localId);
      final queued = (local?['qc_inspections'] as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => row['_sync_status'] != 'synced')
          .toList();
      history = [...queued, ...history];
      if (processId == null && history.isEmpty) {
        history = (local?['qc_inspections'] as List? ?? [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
    }
    if (mounted) setState(() => _inspections = history);
  }

  Future<void> _submit() async {
    if (!KintaAuthService.hasPermission('qc.write')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your offline grant does not permit QC inspection.')));
      return;
    }
    final draft = KintaProcessDraft.instance;
    final processId = draft.processId;
    final localId = draft.localProcessId;
    final qty = int.tryParse(_quantity.text.trim());
    if ((processId == null && localId == null) ||
        _qcUserId == null ||
        qty == null ||
        qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Select one QC person and enter a whole-number quantity.')));
      return;
    }
    final user = _qcUsers.firstWhere(
        (row) => int.tryParse(row['id'].toString()) == _qcUserId,
        orElse: () => <String, dynamic>{});
    final item = <String, Object?>{
      'qc_user_id': _qcUserId,
      'qc_user_name': user['name']?.toString(),
      'quantity': qty,
      'inspected_at': DateTime.now().toUtc().toIso8601String()
    };
    var offline = processId == null;
    setState(() => _saving = true);
    try {
      if (processId != null) {
        try {
          final saved = await KintaApiService.postJson(
              'processes/$processId/qc-inspections',
              {'qc_user_id': _qcUserId, 'quantity': qty});
          if (localId != null) {
            try {
              await KintaLocalRepository.appendLocalProcessItem(localId,
                  'qc_inspections', {...saved, '_sync_status': 'synced'});
            } catch (_) {}
          }
        } on http.ClientException {
          if (localId == null) rethrow;
          await KintaLocalRepository.appendLocalProcessItem(
              localId, 'qc_inspections', item,
              pendingSync: true);
          offline = true;
        }
      } else {
        await KintaLocalRepository.appendLocalProcessItem(
            localId!, 'qc_inspections', item,
            pendingSync: true);
      }
      if (mounted) {
        if (offline)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'QC inspection saved on this device; it is not on the server yet.')));
        _quantity.clear();
        setState(() => _qcUserId = null);
        await _loadInspectionHistory();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save QC inspection: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final search = _qcSearch.text.trim().toLowerCase();
    final visibleUsers = _qcUsers.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final employeeNo = user['employee_no']?.toString().toLowerCase() ?? '';
      return name.contains(search) || employeeNo.contains(search);
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QC Inspection',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              DateFormat('hh:mm a').format(DateTime.now()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (_inspections.isNotEmpty) ...[
              Table(
                border: TableBorder.all(
                  color: Colors.black54,
                  width: 1,
                  borderRadius: BorderRadius.circular(4),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1.35),
                  1: FlexColumnWidth(0.65),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    children: [
                      _tableCell('Time', theme, header: true),
                      _tableCell('Qty', theme, header: true),
                    ],
                  ),
                  ..._inspections.map((row) {
                    final person =
                        (row['qc_user_name'] ?? row['name'] ?? 'QC staff')
                            .toString();
                    final inspectedAt = row['inspection_time'] ??
                        row['inspected_at'] ??
                        row['created_at'] ??
                        '';
                    final time = KintaTime.formatLocal(
                      inspectedAt,
                      pattern: 'hh:mm a',
                      assumeLocalWhenUnmarked: row['inspection_time'] == null,
                    );
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(time, textAlign: TextAlign.center),
                              Text(
                                person,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _tableCell(row['quantity']?.toString() ?? '—', theme),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Text('QC Personnel', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _qcSearch,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search QC',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      shrinkWrap: true,
                      primary: false,
                      children: visibleUsers.map((user) {
                        final id = int.tryParse(user['id'].toString());
                        if (id == null) return const SizedBox.shrink();
                        final name = user['name']?.toString() ?? 'QC staff';
                        final employeeNo =
                            user['employee_no']?.toString() ?? '';
                        return RadioListTile<int>(
                          value: id,
                          groupValue: _qcUserId,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          title: Text(name + ' ' + employeeNo),
                          onChanged: (value) =>
                              setState(() => _qcUserId = value),
                        );
                      }).toList(),
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Confirm'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 104,
                  height: 42,
                  child: ElevatedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String value, ThemeData theme, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: header
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}
