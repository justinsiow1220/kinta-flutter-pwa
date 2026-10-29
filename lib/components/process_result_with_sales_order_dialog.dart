import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';
import '/utils/kinta_time.dart';

class ProcessResultWidget extends StatefulWidget {
  const ProcessResultWidget({super.key});

  @override
  State<ProcessResultWidget> createState() => _ProcessResultWidgetState();
}

class _ProcessResultWidgetState extends State<ProcessResultWidget> {
  Map<String, dynamic>? _process;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProcess();
  }

  Future<void> _loadProcess() async {
    final draft = KintaProcessDraft.instance;
    Map<String, dynamic>? local;
    if (draft.localProcessId != null) {
      try {
        local =
            await KintaLocalRepository.readLocalProcess(draft.localProcessId!);
      } catch (_) {
        // Continue and try the server record below.
      }
    }

    Map<String, dynamic>? server;
    if (draft.processId != null) {
      try {
        server = await KintaApiService.getMap('processes/${draft.processId}');
      } catch (_) {
        // A server record may be unavailable while offline; use the local copy.
      }
    }

    if (!mounted) return;
    if (server == null && local == null) {
      setState(() {
        _loading = false;
        _error = 'No saved process result was found on this device or server.';
      });
      return;
    }

    final result = <String, dynamic>{...?local, ...?server};
    // Use the local event list when the server detail response has no entries.
    for (final field in ['qc_inspections', 'problems', 'pic_history']) {
      final serverRows = server?[field];
      final localRows = local?[field];
      if ((serverRows is! List || serverRows.isEmpty) && localRows is List) {
        result[field] = localRows;
      }
    }
    setState(() {
      _process = result;
      _loading = false;
    });
  }

  String _display(Object? value, {String empty = 'Not recorded'}) {
    if (value == null || value.toString().trim().isEmpty) return empty;
    return value.toString();
  }

  String _quantity(Object? value) =>
      value == null ? 'Not recorded' : '${value} unit(s)';

  Widget _detail(String label, Object? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 145,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(label == 'Started' || label == 'Ended'
                  ? KintaTime.formatLocal(
                      value,
                      assumeLocalWhenUnmarked:
                          KintaProcessDraft.instance.processId == null,
                  )
                  : _display(value)),
            ),
          ],
        ),
      );

  List<Map<String, dynamic>> _rows(String key) =>
      (_process?[key] as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Text('Process Result',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        children: [
                          _detail(
                              'Process ID',
                              _process?['id'] ??
                                  _process?['server_process_id'] ??
                                  KintaProcessDraft.instance.localProcessId),
                          _detail('Status', _process?['status']),
                          _detail(
                              'Machine',
                              _process?['machine_name'] ??
                                  _process?['machine_code']),
                          _detail('Sector', _process?['sector_name']),
                          _detail('Activity', _process?['activity_name']),
                          _detail(
                              'Sales order',
                              _process?['so_number'] ??
                                  KintaProcessDraft.instance.soNumber),
                          _detail(
                              'Customer',
                              _process?['customer_name'] ??
                                  KintaProcessDraft.instance.customerName),
                          _detail(
                              'Batch quantity',
                              _process?['batch_qty'] ??
                                  KintaProcessDraft.instance.batchQty),
                          _detail('Started', _process?['started_at']),
                          _detail('Ended', _process?['ended_at']),
                          _detail(
                              'Qty passed', _quantity(_process?['qty_passed'])),
                          _detail('Qty rejected',
                              _quantity(_process?['qty_rejected'])),
                          _sectionTitle('Problems'),
                          if (_rows('problems').isEmpty)
                            const Text('No problems recorded.')
                          else
                            ..._rows('problems').map((problem) {
                              final code =
                                  problem['code'] ?? problem['problem_code'];
                              final name =
                                  problem['name'] ?? problem['problem_name'];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                    '${code == null ? '' : '$code - '}${_display(name, empty: 'Problem ${problem['problem_id'] ?? ''}')}'),
                              );
                            }),
                          _sectionTitle('QC inspections'),
                          if (_rows('qc_inspections').isEmpty)
                            const Text('No QC inspections recorded.')
                          else
                            ..._rows('qc_inspections')
                                .map((inspection) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      child: Text(
                                          '${_display(inspection['qc_user_name'])}: ${_quantity(inspection['quantity'])} at ${KintaTime.formatLocal(inspection['inspection_time'] ?? inspection['inspected_at'], assumeLocalWhenUnmarked: inspection['inspection_time'] == null)}'),
                                    )),
                          _sectionTitle('PIC history'),
                          if (_rows('pic_history').isEmpty)
                            _detail(
                                'Current PIC',
                                _process?['current_supervisor_name'] ??
                                    _process?['current_supervisor_id'])
                          else
                            ..._rows('pic_history').map((pic) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Text(
                                      '${_display(pic['supervisor_name'])} (${KintaTime.formatLocal(pic['started_at'], assumeLocalWhenUnmarked: KintaProcessDraft.instance.processId == null)} ? ${KintaTime.formatLocal(pic['ended_at'], assumeLocalWhenUnmarked: KintaProcessDraft.instance.processId == null, empty: 'current')})'),
                                )),
                          _sectionTitle('Remarks'),
                          Text(_display(_process?['remarks'],
                              empty: 'No remarks.')),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.success,
                                  foregroundColor: Colors.white),
                              onPressed: () => context
                                  .pushNamed(ProcesswScan5Widget.routeName),
                              child: const Text('Confirm'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
