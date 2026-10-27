import 'package:flutter/material.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';

class QCInspectionWidget extends StatefulWidget {
  const QCInspectionWidget({super.key});
  @override
  State<QCInspectionWidget> createState() => _QCInspectionWidgetState();
}

class _QCInspectionWidgetState extends State<QCInspectionWidget> {
  List<Map<String, dynamic>> _qcUsers = [];
  int? _qcUserId;
  final _quantity = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadQcUsers();
  }

  @override
  void dispose() {
    _quantity.dispose();
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

  Future<void> _submit() async {
    final processId = KintaProcessDraft.instance.processId;
    final qty = int.tryParse(_quantity.text.trim());
    if (processId == null || _qcUserId == null || qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Select one QC person and enter a whole-number quantity.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await KintaApiService.postJson('processes/$processId/qc-inspections',
          {'qc_user_id': _qcUserId, 'quantity': qty});
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save QC inspection: $error')));
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
                Text('QC Inspection',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                    initialValue: _qcUserId,
                    decoration: const InputDecoration(
                        labelText: 'QC Personnel',
                        border: OutlineInputBorder()),
                    hint: Text(_loading
                        ? 'Loading QC personnel...'
                        : 'Select QC personnel'),
                    items: _qcUsers
                        .map((row) => DropdownMenuItem<int>(
                            value: int.tryParse(row['id'].toString()),
                            child:
                                Text('${row['employee_no']} - ${row['name']}')))
                        .where((item) => item.value != null)
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (id) => setState(() => _qcUserId = id)),
                const SizedBox(height: 12),
                TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Inspected quantity',
                        border: OutlineInputBorder())),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child:
                              Text(_saving ? 'Saving...' : 'Save Inspection'))),
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
