import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBaseUrl = 'http://localhost:8080/api';

class Ci4ProcessStartApp extends StatelessWidget {
  const Ci4ProcessStartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KINTA Process API Test',
      home: Ci4ProcessStartPage(),
    );
  }
}

class Ci4ProcessStartPage extends StatefulWidget {
  const Ci4ProcessStartPage({super.key});

  @override
  State<Ci4ProcessStartPage> createState() => _Ci4ProcessStartPageState();
}

class _Ci4ProcessStartPageState extends State<Ci4ProcessStartPage> {
  final _descriptionController = TextEditingController();
  final Set<int> _operatorIds = {};

  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _sectors = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _operators = [];
  List<Map<String, dynamic>> _qcUsers = [];
  List<Map<String, dynamic>> _problems = [];
  List<Map<String, dynamic>> _salesOrders = [];
  List<Map<String, dynamic>> _activeProcesses = [];

  int? _machineId;
  int? _sectorId;
  int? _activityId;
  int? _supervisorId;
  int? _salesOrderId;
  bool _loading = true;
  bool _loadingActivities = false;
  bool _saving = false;
  String? _loadError;
  String? _activityError;
  String? _result;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  int? _recordId(Map<String, dynamic> record) =>
      int.tryParse(record['id']?.toString() ?? '');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';

    late http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
      default:
        response = await http.get(uri, headers: headers);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException('CI4 returned an invalid response for $path.');
    }
    final payload = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        payload['success'] != true) {
      final message = payload['message']?.toString() ?? response.body;
      throw Exception('$method $path failed (HTTP ${response.statusCode}): $message');
    }
    return payload;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final payload = await _request('GET', path);
    final data = payload['data'];
    if (data is! List) {
      throw const FormatException('CI4 returned an unexpected list response.');
    }
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _getList('master-data/machines'),
        _getList('master-data/sectors'),
        _getList('master-data/users?role=supervisor'),
        _getList('master-data/users?role=operator'),
        _getList('master-data/users?role=qc'),
        _getList('master-data/problems'),
        _getList('master-data/sales-orders'),
        _getList('processes/active'),
      ]);
      if (!mounted) return;
      setState(() {
        _machines = results[0];
        _sectors = results[1];
        _supervisors = results[2];
        _operators = results[3];
        _qcUsers = results[4];
        _problems = results[5];
        _salesOrders = results[6];
        _activeProcesses = results[7];
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadActivities(int sectorId) async {
    setState(() {
      _loadingActivities = true;
      _activityError = null;
      _activities = [];
      _activityId = null;
    });
    try {
      final activities = await _getList('master-data/activities?sector_id=$sectorId');
      if (!mounted || _sectorId != sectorId) return;
      setState(() => _activities = activities);
    } catch (error) {
      if (mounted) setState(() => _activityError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _loadActiveProcesses() async {
    try {
      final records = await _getList('processes/active');
      if (mounted) setState(() => _activeProcesses = records);
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  Future<void> _startProcess() async {
    setState(() {
      _saving = true;
      _result = null;
    });
    try {
      final payload = await _request('POST', 'processes', body: {
        'machine_id': _machineId,
        'sector_id': _sectorId,
        'activity_id': _activityId,
        'current_supervisor_id': _supervisorId,
        'sales_order_id': _salesOrderId,
        'operator_ids': _operatorIds.toList(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      });
      if (!mounted) return;
      setState(() => _result = '${payload['message']} (process #${payload['data']?['id']})');
      _descriptionController.clear();
      await _loadActiveProcesses();
    } catch (error) {
      if (mounted) setState(() => _result = 'Start failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _endProcess(Map<String, dynamic> process) async {
    final passed = TextEditingController();
    final rejected = TextEditingController();
    final remarks = TextEditingController();
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('End process #${process['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: passed, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity passed (optional)')),
            TextField(controller: rejected, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity rejected (optional)')),
            TextField(controller: remarks, minLines: 2, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Remarks (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, {
            'qty_passed': passed.text.trim(),
            'qty_rejected': rejected.text.trim(),
            'remarks': remarks.text.trim(),
          }), child: const Text('End process')),
        ],
      ),
    );
    passed.dispose();
    rejected.dispose();
    remarks.dispose();
    if (values == null) return;

    int? quantity(String value) => value.isEmpty ? null : int.tryParse(value);
    final qtyPassed = quantity(values['qty_passed'] ?? '');
    final qtyRejected = quantity(values['qty_rejected'] ?? '');
    if (((values['qty_passed']?.isNotEmpty ?? false) && qtyPassed == null) ||
        ((values['qty_rejected']?.isNotEmpty ?? false) && qtyRejected == null) ||
        (qtyPassed != null && qtyPassed < 0) ||
        (qtyRejected != null && qtyRejected < 0)) {
      setState(() => _result = 'Quantities must be zero or positive whole numbers.');
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await _request('PUT', 'processes/${process['id']}/end', body: {
        'qty_passed': qtyPassed,
        'qty_rejected': qtyRejected,
        'remarks': values['remarks']?.isEmpty == true ? null : values['remarks'],
      });
      if (!mounted) return;
      setState(() => _result = '${response['message']} (process #${process['id']})');
      await _loadActiveProcesses();
    } catch (error) {
      if (mounted) setState(() => _result = 'End failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewProcessDetails(Map<String, dynamic> process) async {
    final processId = _recordId(process);
    if (processId == null) return;

    Map<String, dynamic> details;
    try {
      final payload = await _request('GET', 'processes/$processId');
      final data = payload['data'];
      if (data is! Map) throw const FormatException('Process details are missing.');
      details = Map<String, dynamic>.from(data);
    } catch (error) {
      if (mounted) setState(() => _result = 'Could not load process details: $error');
      return;
    }
    if (!mounted) return;

    List<Map<String, dynamic>> rows(String key) {
      final value = details[key];
      if (value is! List) return [];
      return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }

    Widget section(String title, List<Map<String, dynamic>> records, String Function(Map<String, dynamic>) label) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (records.isEmpty) const Text('None recorded.'),
          for (final record in records) Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(label(record)),
          ),
        ]),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Process #$processId details'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('${details['machine_code']} - ${details['machine_name']}'),
              Text('${details['sector_name']} - ${details['activity_name']}'),
              Text('Status: ${details['status']}'),
              Text('PIC: ${details['current_supervisor_name']}'),
              Text('Sales order: ${details['so_number'] ?? 'None'}'),
              Text('Started: ${details['started_at'] ?? 'Not recorded'}'),
              Text('Ended: ${details['ended_at'] ?? 'Not ended'}'),
              Text('Passed: ${details['qty_passed'] ?? '-'} | Rejected: ${details['qty_rejected'] ?? '-'}'),
              if ((details['description']?.toString() ?? '').isNotEmpty)
                Text('Description: ${details['description']}'),
              if ((details['remarks']?.toString() ?? '').isNotEmpty)
                Text('Remarks: ${details['remarks']}'),
              section('Operators (assignment history)', rows('operators'), (row) =>
                '${row['operator_name']} (user ${row['user_id']}) - ${row['assigned_at']} to ${row['removed_at'] ?? 'Current'}'),
              section('QC inspections', rows('qc_inspections'), (row) =>
                '${row['qc_user_name']} inspected ${row['quantity']} units at ${row['inspection_time']}'),
              section('Problems', rows('problems'), (row) => '${row['code']} - ${row['name']}'),
              section('PIC history', rows('pic_history'), (row) =>
                '${row['supervisor_name']} - ${row['started_at']} to ${row['ended_at'] ?? 'Current'}'),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }
  Future<void> _recordQcInspection(Map<String, dynamic> process) async {
    final processId = _recordId(process);
    if (processId == null) return;
    List<Map<String, dynamic>> history;
    try {
      history = await _getList('processes/$processId/qc-inspections');
    } catch (error) {
      if (mounted) setState(() => _result = 'Could not load QC history: $error');
      return;
    }
    if (!mounted) return;
    if (_qcUsers.isEmpty) {
      setState(() => _result = 'No active QC users are available.');
      return;
    }

    final quantityController = TextEditingController();
    int? qcUserId;
    String? errorMessage;
    String? successMessage;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('QC inspection - Process #$processId'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final row in history)
                  ListTile(
                    dense: true,
                    title: Text('${row['qc_user_name']} - ${row['quantity']} units'),
                    subtitle: Text(row['inspection_time']?.toString() ?? ''),
                  ),
                DropdownButtonFormField<int>(
                  initialValue: qcUserId,
                  decoration: const InputDecoration(labelText: 'QC personnel'),
                  items: [
                    for (final user in _qcUsers)
                      if (_recordId(user) case final int userId)
                        DropdownMenuItem<int>(value: userId,
                            child: Text('${user['name']} - ${user['employee_no']}')),
                  ],
                  onChanged: saving ? null : (value) => setDialogState(() => qcUserId = value),
                ),
                TextField(controller: quantityController, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Inspected quantity')),
                if (errorMessage != null) Text(errorMessage!,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Close')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final amount = int.tryParse(quantityController.text.trim());
                if (qcUserId == null || amount == null || amount < 0) {
                  setDialogState(() => errorMessage = 'Select QC personnel and enter a non-negative whole quantity.');
                  return;
                }
                setDialogState(() { saving = true; errorMessage = null; });
                try {
                  final response = await _request('POST', 'processes/$processId/qc-inspections',
                      body: {'qc_user_id': qcUserId, 'quantity': amount});
                  successMessage = '${response['message']} (process #$processId)';
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (error) {
                  setDialogState(() { saving = false; errorMessage = error.toString(); });
                }
              },
              child: Text(saving ? 'Saving...' : 'Record inspection'),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
    if (successMessage != null && mounted) setState(() => _result = successMessage);
  }

  Future<void> _manageProcessProblems(Map<String, dynamic> process) async {
    final processId = _recordId(process);
    if (processId == null) return;
    List<Map<String, dynamic>> history;
    try {
      history = await _getList('processes/$processId/problems');
    } catch (error) {
      if (mounted) setState(() => _result = 'Could not load problem history: $error');
      return;
    }
    if (!mounted) return;
    if (_problems.isEmpty) {
      setState(() => _result = 'No active problems are available.');
      return;
    }
    final attached = history.map((row) => int.tryParse(row['problem_id'].toString())).whereType<int>().toSet();
    final selected = <int>{};
    String? errorMessage;
    String? successMessage;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Problems - Process #$processId'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final row in history)
                ListTile(dense: true, title: Text('${row['code']} - ${row['name']}')),
              for (final problem in _problems)
                if (_recordId(problem) case final int id)
                  CheckboxListTile(
                    value: attached.contains(id) || selected.contains(id),
                    title: Text('${problem['code']} - ${problem['name']}'),
                    subtitle: attached.contains(id) ? const Text('Already attached') : null,
                    onChanged: attached.contains(id) || saving ? null : (value) => setDialogState(() {
                      if (value == true) { selected.add(id); } else { selected.remove(id); }
                    }),
                  ),
              if (errorMessage != null) Text(errorMessage!,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
            ])),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Close')),
            ElevatedButton(onPressed: saving ? null : () async {
              if (selected.isEmpty) {
                setDialogState(() => errorMessage = 'Select at least one problem not already attached.');
                return;
              }
              setDialogState(() { saving = true; errorMessage = null; });
              try {
                final response = await _request('POST', 'processes/$processId/problems',
                    body: {'problem_ids': selected.toList()});
                successMessage = '${response['message']} (process #$processId)';
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                setDialogState(() { saving = false; errorMessage = error.toString(); });
              }
            }, child: Text(saving ? 'Saving...' : 'Attach selected')),
          ],
        ),
      ),
    );
    if (successMessage != null && mounted) setState(() => _result = successMessage);
  }

  Future<void> _changeProcessPic(Map<String, dynamic> process) async {
    final processId = _recordId(process);
    if (processId == null) return;
    List<Map<String, dynamic>> history;
    try {
      history = await _getList('processes/$processId/pic-history');
    } catch (error) {
      if (mounted) setState(() => _result = 'Could not load PIC history: $error');
      return;
    }
    if (!mounted) return;
    final currentId = int.tryParse(process['current_supervisor_id'].toString());
    final choices = _supervisors.where((row) => _recordId(row) != currentId).toList();
    if (choices.isEmpty) {
      setState(() => _result = 'No other active supervisors are available.');
      return;
    }
    int? supervisorId;
    String? errorMessage;
    String? successMessage;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Change PIC - Process #$processId'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final row in history)
              ListTile(dense: true, title: Text(row['supervisor_name'].toString()),
                  subtitle: Text('${row['started_at']} - ${row['ended_at'] ?? 'Current PIC'}')),
            DropdownButtonFormField<int>(
              initialValue: supervisorId,
              decoration: const InputDecoration(labelText: 'New supervisor'),
              items: [for (final row in choices)
                if (_recordId(row) case final int id)
                  DropdownMenuItem<int>(value: id, child: Text('${row['name']} - ${row['employee_no']}'))],
              onChanged: saving ? null : (value) => setDialogState(() => supervisorId = value),
            ),
            if (errorMessage != null) Text(errorMessage!,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ]))),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Close')),
            ElevatedButton(onPressed: saving ? null : () async {
              if (supervisorId == null) {
                setDialogState(() => errorMessage = 'Select a new supervisor.');
                return;
              }
              setDialogState(() { saving = true; errorMessage = null; });
              try {
                final response = await _request('PUT', 'processes/$processId/pic',
                    body: {'supervisor_id': supervisorId});
                successMessage = '${response['message']} (process #$processId)';
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                setDialogState(() { saving = false; errorMessage = error.toString(); });
              }
            }, child: Text(saving ? 'Saving...' : 'Change PIC')),
          ],
        ),
      ),
    );
    if (successMessage != null && mounted) {
      setState(() => _result = successMessage);
      await _loadActiveProcesses();
    }
  }

  Future<void> _manageProcessOperators(Map<String, dynamic> process) async {
    final processId = _recordId(process);
    if (processId == null) return;
    List<Map<String, dynamic>> history;
    try {
      history = await _getList('processes/$processId/operator-history');
    } catch (error) {
      if (mounted) setState(() => _result = 'Could not load operator history: $error');
      return;
    }
    if (!mounted) return;
    final selected = history
        .where((row) => row['removed_at'] == null)
        .map((row) => int.tryParse(row['user_id'].toString()))
        .whereType<int>()
        .toSet();
    String? errorMessage;
    String? successMessage;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Operators - Process #$processId'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Assignment history'),
            for (final row in history)
              ListTile(dense: true, title: Text(row['operator_name'].toString()),
                  subtitle: Text('${row['assigned_at']} - ${row['removed_at'] ?? 'Currently assigned'}')),
            const Divider(),
            for (final user in _operators)
              if (_recordId(user) case final int id)
                CheckboxListTile(
                  value: selected.contains(id),
                  title: Text('${user['name']} - ${user['employee_no']}'),
                  onChanged: saving ? null : (value) => setDialogState(() {
                    if (value == true) { selected.add(id); } else { selected.remove(id); }
                  }),
                ),
            if (errorMessage != null) Text(errorMessage!,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ]))),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(onPressed: saving ? null : () async {
              setDialogState(() { saving = true; errorMessage = null; });
              try {
                final response = await _request('PUT', 'processes/$processId/operators',
                    body: {'operator_ids': selected.toList()});
                successMessage = '${response['message']} (process #$processId)';
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                setDialogState(() { saving = false; errorMessage = error.toString(); });
              }
            }, child: Text(saving ? 'Saving...' : 'Save operators')),
          ],
        ),
      ),
    );
    if (successMessage != null && mounted) setState(() => _result = successMessage);
  }

  String _operatorNames(Map<String, dynamic> process) {
    final operators = process['operators'];
    if (operators is! List || operators.isEmpty) return 'Operators: None assigned';
    final names = operators.whereType<Map>()
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty).toList();
    return names.isEmpty ? 'Operators: None assigned' : 'Operators: ${names.join(', ')}';
  }

  bool get _canStart => !_loading && !_saving && _machineId != null &&
      _sectorId != null && _activityId != null && _supervisorId != null;

  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> rows,
    required String Function(Map<String, dynamic>) labelFor,
    required ValueChanged<int?> onChanged,
  }) {
    final items = rows.map((row) {
      final id = _recordId(row);
      if (id == null) return null;
      return DropdownMenuItem<int>(value: id, child: Text(labelFor(row)));
    }).whereType<DropdownMenuItem<int>>().toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No active ${label.toLowerCase()} available.'),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KINTA Process API Test')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('One process uses one machine, sector, activity, and supervisor. Operators can be assigned as a group.'),
              OutlinedButton.icon(
                onPressed: _loading || _saving ? null : _loadOptions,
                icon: const Icon(Icons.refresh),
                label: Text(_loading ? 'Loading options...' : 'Refresh options'),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_loadError != null) SelectableText('Could not load options: $_loadError'),
              const SizedBox(height: 12),
              _dropdown(label: 'Machine', value: _machineId, rows: _machines,
                  labelFor: (row) => '${row['machine_code']} - ${row['machine_name']}',
                  onChanged: (value) => setState(() => _machineId = value)),
              const SizedBox(height: 10),
              _dropdown(label: 'Sector', value: _sectorId, rows: _sectors,
                  labelFor: (row) => row['name'].toString(), onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sectorId = value);
                    _loadActivities(value);
                  }),
              if (_loadingActivities) const LinearProgressIndicator(),
              _dropdown(label: 'Activity', value: _activityId, rows: _activities,
                  labelFor: (row) => row['name'].toString(),
                  onChanged: (value) => setState(() => _activityId = value)),
              if (_activityError != null) Text('Could not load activities: $_activityError'),
              const SizedBox(height: 10),
              _dropdown(label: 'Current supervisor', value: _supervisorId, rows: _supervisors,
                  labelFor: (row) => '${row['name']} - ${row['employee_no']}',
                  onChanged: (value) => setState(() => _supervisorId = value)),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _salesOrderId ?? 0,
                decoration: const InputDecoration(labelText: 'Sales order (optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int>(value: 0, child: Text('No sales order')),
                  for (final row in _salesOrders)
                    if (_recordId(row) case final int id)
                      DropdownMenuItem<int>(value: id, child: Text('${row['so_number']} - ${row['customer_name']}')),
                ],
                onChanged: (value) => setState(() => _salesOrderId = value == 0 ? null : value),
              ),
              const SizedBox(height: 12),
              Text('Operators (${_operatorIds.length} selected)'),
              Wrap(spacing: 8, children: [
                for (final row in _operators)
                  if (_recordId(row) case final int id)
                    FilterChip(
                      label: Text(row['name'].toString()),
                      selected: _operatorIds.contains(id),
                      onSelected: (value) => setState(() {
                        if (value) { _operatorIds.add(id); } else { _operatorIds.remove(id); }
                      }),
                    ),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _descriptionController, minLines: 2, maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _canStart ? _startProcess : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(_saving ? 'Saving...' : 'Start process'),
              ),
              if (_result != null) Padding(
                padding: const EdgeInsets.all(8), child: SelectableText(_result!, textAlign: TextAlign.center)),
              const Divider(height: 32),
              Text('Active processes (${_activeProcesses.length})', style: Theme.of(context).textTheme.titleMedium),
              if (_activeProcesses.isEmpty) const Text('No active processes.'),
              for (final process in _activeProcesses)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('${process['machine_code']} | ${process['sector_name']} | ${process['activity_name']}',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('Process #${process['id']} | PIC ${process['supervisor_name']} | ${process['so_number'] ?? 'No sales order'}'),
                      Text(_operatorNames(process)),
                      Wrap(spacing: 4, runSpacing: 2, children: [
                        TextButton.icon(onPressed: _saving ? null : () => _viewProcessDetails(process),
                            icon: const Icon(Icons.info_outline), label: const Text('Details')),
                        TextButton.icon(onPressed: _saving ? null : () => _recordQcInspection(process),
                            icon: const Icon(Icons.fact_check_outlined), label: const Text('QC')),
                        TextButton.icon(onPressed: _saving ? null : () => _manageProcessProblems(process),
                            icon: const Icon(Icons.warning_amber_outlined), label: const Text('Problems')),
                        TextButton.icon(onPressed: _saving ? null : () => _changeProcessPic(process),
                            icon: const Icon(Icons.person_outline), label: const Text('PIC')),
                        TextButton.icon(onPressed: _saving ? null : () => _manageProcessOperators(process),
                            icon: const Icon(Icons.groups_outlined), label: const Text('Operators')),
                        TextButton.icon(onPressed: _saving ? null : () => _endProcess(process),
                            icon: const Icon(Icons.stop_circle_outlined), label: const Text('End')),
                      ]),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}