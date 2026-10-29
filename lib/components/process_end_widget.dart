import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class ProcessEndWidget extends StatefulWidget {
  const ProcessEndWidget({super.key});
  @override
  State<ProcessEndWidget> createState() => _ProcessEndWidgetState();
}

class _ProcessEndWidgetState extends State<ProcessEndWidget> {
  final _passed = TextEditingController(),
      _rejected = TextEditingController(),
      _remarks = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _passed.dispose();
    _rejected.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!KintaAuthService.hasPermission('process.write')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your offline grant does not permit process updates.'))); return; }
    final draft = KintaProcessDraft.instance;
    final id = draft.processId;
    final localId = draft.localProcessId;
    final passed = int.tryParse(_passed.text.trim()),
        rejected = int.tryParse(_rejected.text.trim());
    if ((id == null && localId == null) ||
        (_passed.text.trim().isNotEmpty && (passed == null || passed < 0)) ||
        (_rejected.text.trim().isNotEmpty &&
            (rejected == null || rejected < 0))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Enter whole numbers for passed and rejected quantities.')));
      return;
    }
    final remarks = _remarks.text.trim().isEmpty ? null : _remarks.text.trim();
    final changes = <String, Object?>{
      'status': 'completed',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'qty_passed': passed,
      'qty_rejected': rejected,
      'remarks': remarks,
      'end_sync_status': id == null ? 'pending' : 'synced',
      if (id == null) 'sync_pending': true
    };
    setState(() => _saving = true);
    try {
      var offline = id == null;
      if (id != null) {
        try {
          final saved = await KintaApiService.putJson('processes/$id/end', {
            'qty_passed': passed,
            'qty_rejected': rejected,
            'remarks': remarks
          });
          if (localId != null) {
            try {
              await KintaLocalRepository.updateLocalProcess(localId, {
                ...saved,
                'end_sync_status': 'synced',
              });
            } catch (_) {}
          }
        } on http.ClientException {
          if (localId == null) rethrow;
          await KintaLocalRepository.updateLocalProcess(localId, changes);
          offline = true;
        }
      } else {
        await KintaLocalRepository.updateLocalProcess(localId!, changes);
      }
      draft.qtyPassed = passed;
      draft.qtyRejected = rejected;
      draft.persistInBackground();
      if (mounted) {
        if (offline)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Process end saved on this device; it is not on the server yet.')));
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not end process: $error')));
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
                Text('End Process',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(
                    controller: _passed,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Quantity passed',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _rejected,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Quantity rejected',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _remarks,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Remarks (optional)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? 'Saving...' : 'Confirm End'))),
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

