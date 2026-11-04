import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '/kinta_api_service.dart';
import '/auth/kinta_auth_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class ProcessEndWidget extends StatefulWidget {
  const ProcessEndWidget({super.key, this.confirmationOnly = false});

  final bool confirmationOnly;
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

  @override
  void initState() {
    super.initState();
    final draft = KintaProcessDraft.instance;
    _passed.text = draft.qtyPassed?.toString() ?? '';
    _rejected.text = draft.qtyRejected?.toString() ?? '';
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
  Widget build(BuildContext context) {
    if (widget.confirmationOnly) return _buildConfirmation(context);
    return SafeArea(
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

  Widget _buildConfirmation(BuildContext context) {
    final timestamp = DateFormat('yyyy-MM-dd | hh:mma').format(DateTime.now());
    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Process End',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              timestamp,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(_saving ? 'Saving...' : 'Confirm'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

