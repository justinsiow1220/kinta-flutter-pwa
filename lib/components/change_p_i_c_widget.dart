import 'package:flutter/material.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';

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
    final processId = KintaProcessDraft.instance.processId;
    if (_supervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select a supervisor to become the new PIC.')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (processId != null)
        await KintaApiService.putJson(
            'processes/$processId/pic', {'supervisor_id': _supervisorId});
      final row = _supervisors
          .where((item) => int.tryParse(item['id'].toString()) == _supervisorId)
          .firstOrNull;
      KintaProcessDraft.instance.supervisorId = _supervisorId;
      KintaProcessDraft.instance.supervisorName = row?['name']?.toString();
      if (mounted) Navigator.of(context).pop(true);
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
