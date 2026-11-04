import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/auth/kinta_auth_service.dart';
import '/components/change_pic_dialog_model.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';
import '/offline/kinta_local_repository.dart';

class ChangePICWidget extends StatefulWidget {
  const ChangePICWidget({super.key});

  @override
  State<ChangePICWidget> createState() => _ChangePICWidgetState();
}

class _ChangePICWidgetState extends State<ChangePICWidget> {
  late ChangePICModel _model;
  final _operatorSearch = TextEditingController();
  List<Map<String, dynamic>> _operators = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChangePICModel());
    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.dropDownValueController ??=
        FormFieldController<List<String>>(
      KintaProcessDraft.instance.operatorIds.map((id) => id.toString()).toList(),
    );
    _model.dropDownValue =
        List<String>.from(_model.dropDownValueController!.value ?? []);
    _loadOperators();
  }

  @override
  void dispose() {
    _operatorSearch.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _loadOperators() async {
    try {
      final rows = await KintaApiService.getList('master-data/users?role=operator');
      if (mounted) setState(() => _operators = rows);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not load operators: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleOperator(String id, bool selected) {
    final values = List<String>.from(_model.dropDownValueController!.value ?? []);
    if (selected && !values.contains(id)) values.add(id);
    if (!selected) values.remove(id);
    setState(() {
      _model.dropDownValue = values;
      _model.dropDownValueController!.value = values;
    });
  }

  Future<void> _submit() async {
    if (!KintaAuthService.hasPermission('pic.change') ||
        !KintaAuthService.hasPermission('operator.assign')) {
      _message('Your current supervisor account cannot change PIC and assign operators.');
      return;
    }
    final selectedOperatorIds =
        List<String>.from(_model.dropDownValueController!.value ?? []);
    final username = _model.textController1!.text.trim();
    final password = _model.textController2!.text;
    if (selectedOperatorIds.isEmpty || username.isEmpty || password.isEmpty) {
      _message('Select at least one operator and enter the next supervisor login.');
      return;
    }

    final draft = KintaProcessDraft.instance;
    final localId = draft.localProcessId;
    setState(() => _saving = true);
    try {
      final localProcess = localId == null
          ? null
          : await KintaLocalRepository.readLocalProcess(localId);
      if (localId != null && localProcess == null) {
        throw StateError('Saved process was not found locally. Reopen it from process records.');
      }
      final serverId = localId != null
          ? int.tryParse(localProcess?['server_process_id']?.toString() ?? '')
          : draft.processId;
      final isPreStartHandoff = localId == null && serverId == null;

      // Login verifies the incoming PIC and establishes their supervisor grant.
      // KintaAuthService also verifies that the returned signed grant is valid.
      final verifiedLogin = await KintaAuthService.verifySupervisorLoginForHandoff(
        username: username,
        password: password,
      );
      final newSupervisor = verifiedLogin['user'] is Map
          ? Map<String, dynamic>.from(verifiedLogin['user'] as Map)
          : <String, dynamic>{};
      final supervisorId = int.tryParse(newSupervisor['id']?.toString() ?? '');
      final supervisorName = newSupervisor['name']?.toString();
      if (supervisorId == null) {
        throw const FormatException('The supervisor login did not return a valid user ID.');
      }
      final operatorIds = selectedOperatorIds.map(int.parse).toList();
      final selectedOperators = _operators.where((row) =>
          operatorIds.contains(int.tryParse(row['id']?.toString() ?? '')));
      final operatorNames = selectedOperators
          .map((row) => row['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      // Before process creation, apply the handoff to the shared draft only.
      // A started process still gets its server/local records updated below.
      var offline = !isPreStartHandoff && serverId == null;
      if (serverId != null) {
        await KintaApiService.putJson(
            'processes/$serverId/operators', {'operator_ids': operatorIds});
        await KintaApiService.putJson(
            'processes/$serverId/pic', {'supervisor_id': supervisorId});
      }

      if (localId != null) {
        final now = DateTime.now().toUtc().toIso8601String();
        final current = localProcess!;
        final history = List<Map<String, dynamic>>.from(
          (current['pic_history'] as List? ?? [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)),
        );
        if (history.isNotEmpty && history.last['ended_at'] == null) {
          history.last['ended_at'] = now;
        }
        history.add({
          'supervisor_id': supervisorId,
          'supervisor_name': supervisorName,
          'started_at': now,
          'ended_at': null,
          '_sync_status': offline ? 'pending' : 'synced',
        });
        await KintaLocalRepository.updateLocalProcess(localId, {
          'current_supervisor_id': supervisorId,
          'current_supervisor_name': supervisorName,
          'operator_ids': operatorIds,
          'operator_names': operatorNames,
          'pic_history': history,
          if (offline) 'sync_pending': true,
        });
      }

      // Activate the incoming supervisor only after the process assignments
      // (or local update) have succeeded. A pre-start handoff has no process
      // record to update, so only the draft and session are changed.
      await KintaAuthService.activateVerifiedHandoffSession(verifiedLogin);
      draft.supervisorId = supervisorId;
      draft.supervisorName = supervisorName;
      draft.operatorIds = operatorIds.toSet();
      draft.operatorNames = operatorNames;
      draft.persistInBackground();
      if (mounted) {
        if (offline) {
          _message('Handoff saved on this device and will sync when a server process is available.');
        }
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) _message('Could not complete Change PIC: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _operators.where((row) {
      final query = _operatorSearch.text.trim().toLowerCase();
      final label = '${row['name'] ?? ''} ${row['employee_no'] ?? ''}'.toLowerCase();
      return label.contains(query);
    }).toList();
    final date = DateFormat('yyyy-MM-dd  |  hh:mm a').format(DateTime.now());
    final selected = _model.dropDownValueController?.value ?? <String>[];
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Change PIC', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(date, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                _sectionTitle('Update Your Operators'),
                const SizedBox(height: 6),
                TextField(
                  controller: _operatorSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 126,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _operators.isEmpty
                          ? Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(_error!, textAlign: TextAlign.center)))
                          : ListView(
                              padding: EdgeInsets.zero,
                              children: filtered.map((row) {
                                final id = row['id']?.toString() ?? '';
                                final label = '${row['name'] ?? 'Operator'} ${row['employee_no'] ?? ''}'.trim();
                                return SizedBox(
                                  height: 34,
                                  child: CheckboxListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(label, style: const TextStyle(fontSize: 13)),
                                    value: selected.contains(id),
                                    onChanged: (value) => _toggleOperator(id, value == true),
                                  ),
                                );
                              }).toList(),
                            ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('Supervisor Login'),
                const SizedBox(height: 8),
                TextField(
                  controller: _model.textController1,
                  focusNode: _model.textFieldFocusNode1,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  obscureText: !_model.passwordVisibility,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      focusNode: _model.textFieldPasswordVisibilityFocusNode2,
                      onPressed: () => setState(() => _model.passwordVisibility = !_model.passwordVisibility),
                      icon: Icon(_model.passwordVisibility ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                if (_error != null && _operators.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _saving || _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_saving ? 'Please wait...' : 'Confirm'),
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
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}
