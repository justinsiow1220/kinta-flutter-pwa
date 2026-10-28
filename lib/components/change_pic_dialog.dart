import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class ChangePICWidget extends StatefulWidget {
  const ChangePICWidget({super.key});
  @override
  State<ChangePICWidget> createState() => _ChangePICWidgetState();
}

class _ChangePICWidgetState extends State<ChangePICWidget> {
  List<Map<String, dynamic>> _supervisors = [];
  int? _supervisorId;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    try {
      final rows =
          await KintaApiService.getList('master-data/users?role=supervisor');
      if (mounted) setState(() => _supervisors = rows);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!KintaAuthService.hasPermission('pic.change')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your offline grant does not permit changing the PIC.'))); return; }
    final draft = KintaProcessDraft.instance;
    final processId = draft.processId;
    final localId = draft.localProcessId;
    if (_supervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select a supervisor to become the new PIC.')));
      return;
    }
    final row = _supervisors
        .where((item) => int.tryParse(item['id'].toString()) == _supervisorId)
        .firstOrNull;
    final name = row?['name']?.toString();
    setState(() => _saving = true);
    try {
      var offline = false;
      if (processId != null) {
        try {
          await KintaApiService.putJson(
              'processes/$processId/pic', {'supervisor_id': _supervisorId});
        } on http.ClientException {
          if (localId == null) rethrow;
          offline = true;
        }
      } else if (localId != null) {
        offline = true;
      }
      if (localId != null) {
        final now = DateTime.now().toIso8601String();
        final current = await KintaLocalRepository.readLocalProcess(localId);
        if (current == null)
          throw StateError('Saved process was not found locally.');
        final history = List<Map<String, dynamic>>.from(
            (current['pic_history'] as List? ?? [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item)));
        if (history.isNotEmpty && history.last['ended_at'] == null)
          history.last['ended_at'] = now;
        history.add({
          'supervisor_id': _supervisorId,
          'supervisor_name': name,
          'started_at': now,
          'ended_at': null,
          '_sync_status': offline ? 'pending' : 'synced'
        });
        await KintaLocalRepository.updateLocalProcess(localId, {
          'current_supervisor_id': _supervisorId,
          'current_supervisor_name': name,
          'pic_history': history,
          if (offline) 'sync_pending': true
        });
      }
      draft.supervisorId = _supervisorId;
      draft.supervisorName = name;
      draft.persistInBackground();
      if (mounted) {
        if (offline)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'PIC change saved on this device; it is not on the server yet.')));
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not change PIC: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Change PIC',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                    initialValue: _supervisorId,
                    decoration: const InputDecoration(
                        labelText: 'New supervisor / PIC',
                        border: OutlineInputBorder()),
                    hint: Text(_loading
                        ? 'Loading supervisors...'
                        : 'Select supervisor'),
                    items: _supervisors
                        .map((row) => DropdownMenuItem<int>(
                            value: int.tryParse(row['id'].toString()),
                            child:
                                Text('${row['employee_no']} - ${row['name']}')))
                        .where((item) => item.value != null)
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (id) => setState(() => _supervisorId = id)),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? 'Saving...' : 'Confirm PIC'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancel')))
                ]),
              ])));
}

