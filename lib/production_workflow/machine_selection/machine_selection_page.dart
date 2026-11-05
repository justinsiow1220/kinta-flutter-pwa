import 'dart:async';

import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';
import '/auth/kinta_auth_service.dart';
import '/offline/kinta_local_repository.dart';
import '/offline/kinta_sync_service.dart';
import '/production_workflow/process_records/process_records_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:provider/provider.dart';
import 'machine_selection_model.dart';
export 'machine_selection_model.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'Home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _machines = [];
  bool _machinesLoading = true;
  String? _machineLoadError;
  int _pendingSyncCount = 0;
  int _pendingSalesOrderCount = 0;
  int _syncAttentionCount = 0;
  bool _syncing = false;
  Timer? _pendingCountTimer;

  List<String> get _machineValues =>
      _machines.map((machine) => machine['id'].toString()).toList();
  List<String> get _machineLabels => _machines
      .map((machine) =>
          '${machine['machine_code']} - ${machine['machine_name']}')
      .toList();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());
    _model.dropDownValue = KintaProcessDraft.instance.machineId?.toString();
    _pendingCountTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshPendingSyncCount(),
    );
    _loadMachines();
    _refreshPendingSyncCount();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _pendingCountTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  Future<void> _refreshPendingSyncCount() async {
    try {
      final actorUserId = KintaAuthService.currentUser?['id']?.toString();
      final counts = await Future.wait<int>([
        KintaLocalRepository.countPendingLocalProcesses(),
        if (actorUserId != null)
          KintaLocalRepository.countPendingSalesOrders(
            actorUserId: actorUserId,
          )
        else
          Future<int>.value(0),
      ]);
      final localProcesses = await KintaLocalRepository.readAllLocalProcesses();
      final processErrorCount = localProcesses
          .where((process) =>
              actorUserId != null &&
              process['actor_user_id']?.toString() == actorUserId &&
              (process['sync_error']?.toString().trim().isNotEmpty ?? false))
          .length;
      if (mounted) {
        setState(() {
          _pendingSyncCount = counts[0];
          _pendingSalesOrderCount = counts[1];
          _syncAttentionCount = counts[1] + processErrorCount;
        });
      }
    } catch (_) {
      // Keep the sync action available even when the pending count is unavailable.
    }
  }

  Future<void> _syncPendingProcesses({bool silent = false}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final report = await KintaSyncService.syncPendingProcesses(
        forceRetry: true,
      );
      await _refreshPendingSyncCount();
      if (!mounted) return;
      final orderMessage = report.salesOrdersSynced > 0
          ? '${report.salesOrdersSynced} sales order(s) synced. '
          : '';
      final message = report.needsReview > 0
          ? '$orderMessage${report.synced} process(es) synced. '
              '${report.needsReview} process(es) need review. '
              'Open Process Records for details.'
          : report.waitingForMasterData > 0
              ? '$orderMessage${report.synced} process(es) synced. '
                  '${report.waitingForMasterData} process(es) are waiting for '
                  'master data reactivation.'
              : report.hasErrors && _pendingSyncCount > 0
                  ? '$orderMessage${report.synced} process(es) synced. '
                      '$_pendingSyncCount process(es) remain saved on this '
                      'device. KINTA will retry automatically. '
                      'Open Process Records for details.'
                  : report.hasErrors
                      ? 'Sync encountered an error. Check Process Records '
                          'to confirm the saved record status.'
                      : report.synced == 0 && report.salesOrdersSynced == 0
                          ? 'No pending processes to sync.'
                          : report.synced == 0
                              ? '${report.salesOrdersSynced} sales order(s) synced successfully.'
                              : '$orderMessage${report.synced} process(es) synced successfully.';
      if (!silent)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _showOfflineRecords() async {
    await ProcessRecordsDialog.showBottomSheet(context);
    await _refreshPendingSyncCount();
  }

  Future<void> _showSyncAttention() async {
    final actorUserId = KintaAuthService.currentUser?['id']?.toString();
    final pendingOrders = await KintaLocalRepository.readPendingSalesOrders(
      actorUserId: actorUserId,
    );
    final localProcesses = await KintaLocalRepository.readAllLocalProcesses();
    final processesWithErrors = localProcesses
        .where((process) =>
            actorUserId != null &&
            process['actor_user_id']?.toString() == actorUserId &&
            (process['sync_error']?.toString().trim().isNotEmpty ?? false))
        .toList();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Pending sync and errors',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 1),
                if (pendingOrders.isEmpty && processesWithErrors.isEmpty)
                  const Expanded(
                    child: Center(
                        child: Text('No pending sales orders or sync errors.')),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        if (pendingOrders.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 6),
                            child: Text('Pending sales orders',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          for (final order in pendingOrders)
                            Card(
                              child: ListTile(
                                leading:
                                    const Icon(Icons.receipt_long_outlined),
                                title: Text(order['so_number']?.toString() ??
                                    'Sales order'),
                                subtitle: Text([
                                  'Customer: ${order['customer_name'] ?? '-'}',
                                  'Batch quantity: ${order['batch_qty'] ?? '-'}',
                                  order['last_sync_error']?.toString() ??
                                      'Waiting to sync',
                                ].join('\n')),
                                isThreeLine: true,
                              ),
                            ),
                        ],
                        if (processesWithErrors.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 6),
                            child: Text('Process sync errors',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          for (final process in processesWithErrors)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.error_outline,
                                    color: Colors.red),
                                title: Text(
                                    'Process ${process['server_process_id'] ?? process['local_id'] ?? ''}'),
                                subtitle:
                                    Text(process['sync_error'].toString()),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _syncing
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            _syncPendingProcesses();
                          },
                    icon: const Icon(Icons.sync),
                    label: const Text('Retry Sync'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _prepareOfflineData() async {
    try {
      await KintaAuthService.retryOfflinePreload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Offline data is ready on this device.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offline setup failed: $error')));
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await KintaAuthService.logout();
    if (mounted) context.goNamed(LoginWidget.routeName);
  }

  void _continueToWorkflow(String routeName) {
    if (KintaProcessDraft.instance.machineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a machine to proceed.')),
      );
      return;
    }
    context.pushNamed(routeName);
  }

  Future<void> _loadMachines() async {
    setState(() {
      _machinesLoading = true;
      _machineLoadError = null;
    });
    try {
      final records = await KintaApiService.getList('master-data/machines');
      if (!mounted) return;
      final draft = KintaProcessDraft.instance;
      final savedMachine = draft.machineId?.toString();
      final savedRow = records
          .where((row) => row['id'].toString() == savedMachine)
          .firstOrNull;
      setState(() {
        _machines = records;
        _model.dropDownValue = savedRow == null ? null : savedMachine;
        _model.dropDownValueController?.value = _model.dropDownValue;
        draft.machineId =
            savedRow == null ? null : int.tryParse(savedMachine ?? '');
        draft.machineLabel = savedRow == null
            ? null
            : '${savedRow['machine_code']} - ${savedRow['machine_name']}';
      });
      draft.persistInBackground();
    } catch (error) {
      if (!mounted) return;
      setState(() => _machineLoadError = error.toString());
    } finally {
      if (mounted) setState(() => _machinesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).info,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Select Machine',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.manrope(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).info,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [
            if (!KintaAuthService.offlineReady)
              IconButton(
                tooltip: 'Retry offline data preload',
                onPressed: _prepareOfflineData,
                icon: const Icon(Icons.cloud_download, color: Colors.white),
              ),
            IconButton(
                tooltip: 'View process records',
                onPressed: _showOfflineRecords,
                icon: const Icon(Icons.inventory_2_outlined,
                    color: Colors.white)),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
            TextButton.icon(
              onPressed: _syncing ? null : _syncPendingProcesses,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label:
                  Text('Sync (${_pendingSyncCount + _pendingSalesOrderCount})'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            TextButton.icon(
              onPressed: _showSyncAttention,
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text('(${_syncAttentionCount})'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 15.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      DateFormat('d MMMM yyyy')
                                          .format(DateTime.now()),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w900,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w900,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      DateFormat('hh:mm a')
                                          .format(DateTime.now())
                                          .toLowerCase(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w900,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w900,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Divider(
                                      height: 20.0,
                                      thickness: 2.0,
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 10.0),
                                    child: Text(
                                      'Select Your Machine',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.manrope(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 15.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              FlutterFlowDropDown<String>(
                                                controller: _model
                                                        .dropDownValueController ??=
                                                    FormFieldController<String>(
                                                        _model.dropDownValue),
                                                options: _machineValues,
                                                optionLabels: _machineLabels,
                                                width: double.infinity,
                                                height: 54.0,
                                                searchHintTextStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                searchTextStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                hintText: _machinesLoading
                                                    ? 'Loading machines...'
                                                    : (_machineLoadError == null
                                                        ? 'Select Machine'
                                                        : 'Could not load machines'),
                                                disabled: _machinesLoading ||
                                                    _machines.isEmpty,
                                                searchHintText: 'Search...',
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  size: 24.0,
                                                ),
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                elevation: 2.0,
                                                borderColor:
                                                    FlutterFlowTheme.of(context)
                                                        .border,
                                                focusBorderColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                borderWidth: 2.0,
                                                borderRadius: 10.0,
                                                margin:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        12.0, 0.0, 12.0, 0.0),
                                                hidesUnderline: true,
                                                isOverButton: false,
                                                isSearchable: true,
                                                isMultiSelect: false,
                                                onChanged: (value) {
                                                  safeSetState(() => _model
                                                      .dropDownValue = value);
                                                  final draft =
                                                      KintaProcessDraft
                                                          .instance;
                                                  draft.machineId =
                                                      int.tryParse(value ?? '');
                                                  final selected = _machines
                                                      .where((row) =>
                                                          row['id']
                                                              .toString() ==
                                                          value)
                                                      .firstOrNull;
                                                  draft
                                                      .machineLabel = selected ==
                                                          null
                                                      ? null
                                                      : '${selected['machine_code']} - ${selected['machine_name']}';
                                                  draft.persistInBackground();
                                                },
                                              ),
                                              if (_machineLoadError !=
                                                  null) ...[
                                                Text(
                                                  _machineLoadError!,
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: _machinesLoading
                                                      ? null
                                                      : _loadMachines,
                                                  icon:
                                                      const Icon(Icons.refresh),
                                                  label: const Text(
                                                      'Retry machine load'),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 15.0, 0.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        0.0, 0.0, 0.0, 10.0),
                                                child: Text(
                                                  'Process with S/O Scan ?',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleSmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.manrope(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(10.0,
                                                              0.0, 10.0, 0.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          FFButtonWidget(
                                                            onPressed: () {
                                                              _continueToWorkflow(
                                                                ScanSalesOrderWidget
                                                                    .routeName,
                                                              );
                                                            },
                                                            text: 'Yes',
                                                            options:
                                                                FFButtonOptions(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  1.0,
                                                              height: 52.0,
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                              iconPadding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .success,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .manrope(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .titleSmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleSmall
                                                                            .fontStyle,
                                                                      ),
                                                              elevation: 0.0,
                                                              borderSide:
                                                                  const BorderSide(
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(10.0,
                                                              0.0, 10.0, 0.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          FFButtonWidget(
                                                            onPressed: () {
                                                              _continueToWorkflow(
                                                                ManualSalesOrderWidget
                                                                    .routeName,
                                                              );
                                                            },
                                                            text: 'No',
                                                            options:
                                                                FFButtonOptions(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  1.0,
                                                              height: 52.0,
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                              iconPadding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .manrope(
                                                                          fontWeight: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleSmall
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .titleSmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleSmall
                                                                            .fontStyle,
                                                                      ),
                                                              elevation: 3.0,
                                                              borderSide:
                                                                  const BorderSide(
                                                                width: 0.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
