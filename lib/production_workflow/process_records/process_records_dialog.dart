import 'package:flutter/material.dart';

import '/auth/kinta_auth_service.dart';
import '/kinta_api_service.dart';
import '/offline/kinta_local_repository.dart';
import '/utils/kinta_time.dart';

/// Displays server-side process history and local work waiting to synchronize.
class ProcessRecordsDialog extends StatefulWidget {
  const ProcessRecordsDialog({super.key, this.embedded = false});

  /// When true, renders the same records list inside Process Setup's Previous tab.
  /// The embedded history is read-only and does not include a dialog Close action.
  final bool embedded;

  @override
  State<ProcessRecordsDialog> createState() => _ProcessRecordsDialogState();
}

class _ProcessRecordsDialogState extends State<ProcessRecordsDialog> {
  List<Map<String, dynamic>> _serverRecords = [];
  List<Map<String, dynamic>> _localRecords = [];
  final Set<int> _expandedRecords = <int>{};
  final Map<int, Map<String, dynamic>> _details = <int, Map<String, dynamic>>{};
  final Set<int> _loadingDetails = <int>{};
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  List<Map<String, dynamic>> _sortByStartedAt(List<Map<String, dynamic>> rows) {
    rows.sort((a, b) {
      final aTime =
          KintaTime.parseUtc(a['started_at'], assumeLocalWhenUnmarked: true)
                  ?.millisecondsSinceEpoch ??
              0;
      final bTime =
          KintaTime.parseUtc(b['started_at'], assumeLocalWhenUnmarked: true)
                  ?.millisecondsSinceEpoch ??
              0;
      final byTime = bTime.compareTo(aTime);
      if (byTime != 0) return byTime;
      return (int.tryParse('${b['id'] ?? b['local_id'] ?? 0}') ?? 0)
          .compareTo(int.tryParse('${a['id'] ?? a['local_id'] ?? 0}') ?? 0);
    });
    return rows;
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        KintaApiService.getList('processes'),
        KintaLocalRepository.readAllLocalProcesses(),
      ]);
      if (!mounted) return;
      final currentUserId = KintaAuthService.currentUser?['id']?.toString();
      final serverRows = results[0]
          .where((row) =>
              row['created_by_workforce_id']?.toString() == currentUserId)
          .toList();
      final serverIds = serverRows
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .toSet();
      setState(() {
        _serverRecords = _sortByStartedAt(serverRows);
        _localRecords = results[1].where((row) {
          final serverId = row['server_process_id']?.toString();
          return row['actor_user_id']?.toString() == currentUserId &&
              row['server_record_archived'] != true &&
              (serverId == null ||
                  !serverIds.contains(serverId) ||
                  row['sync_status'] == 'conflict' ||
                  row['sync_pending'] == true);
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      try {
        final local = await KintaLocalRepository.readAllLocalProcesses();
        if (mounted) {
          final currentUserId = KintaAuthService.currentUser?['id']?.toString();
          setState(() => _localRecords = local
              .where((row) =>
                  row['actor_user_id']?.toString() == currentUserId &&
                  row['server_record_archived'] != true &&
                  (row['server_process_id'] == null ||
                      row['sync_status'] == 'conflict' ||
                      row['sync_pending'] == true))
              .toList());
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleDetails(int processId) async {
    if (_expandedRecords.contains(processId)) {
      setState(() => _expandedRecords.remove(processId));
      return;
    }
    setState(() => _expandedRecords.add(processId));
    if (_details.containsKey(processId)) return;
    setState(() => _loadingDetails.add(processId));
    try {
      final details = await KintaApiService.getMap('processes/$processId');
      if (mounted) setState(() => _details[processId] = details);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not load full process details: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDetails.remove(processId));
    }
  }

  Future<bool> _confirmDelete(
          {required String title, required String message}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Archive'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteServerRecord(Map<String, dynamic> row) async {
    if (row['status'] == 'active') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('End the active process before deleting its record.'),
      ));
      return;
    }
    final accepted = await _confirmDelete(
      title: 'Delete process #${row['id']}?',
      message:
          'This hides the completed process from the normal app list. Its process and operator history remains in MySQL for audit.',
    );
    if (!accepted || !mounted) return;
    setState(() => _deleting = true);
    try {
      await KintaApiService.deleteJson('processes/${row['id']}');
      try {
        final localRows = await KintaLocalRepository.readAllLocalProcesses();
        for (final localRow in localRows.where((item) =>
            item['server_process_id']?.toString() == row['id'].toString())) {
          await KintaLocalRepository.updateLocalProcess(
              localRow['local_id'].toString(),
              {'server_record_archived': true});
        }
        final historyCacheKey = KintaApiService.processHistoryCacheKey();
        final cached =
            await KintaLocalRepository.readMasterDataList(historyCacheKey);
        if (cached != null) {
          await KintaLocalRepository.cacheMasterDataList(
              historyCacheKey,
              cached
                  .where(
                      (item) => item['id'].toString() != row['id'].toString())
                  .toList());
        }
      } catch (_) {}
      await _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Process archived from the app list; its history remains in MySQL.'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete process: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _deleteLocalRecord(Map<String, dynamic> row) async {
    final accepted = await _confirmDelete(
      title: 'Delete local process ${row['local_id']}?',
      message:
          'This permanently removes this unsynced record from this browser. It has not been uploaded to CI4.',
    );
    if (!accepted || !mounted) return;
    try {
      await KintaLocalRepository.deleteUnsyncedLocalProcess(
        row['local_id'].toString(),
      );
      await _loadRecords();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete local record: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        !widget.embedded && KintaAuthService.hasPermission('process.delete');
    final content = Column(
      children: [
        ListTile(
          title: const Text(
            'Process Records',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Server records visible to this account and local copies',
          ),
          trailing: IconButton(
            onPressed: _loading ? null : _loadRecords,
            tooltip: 'Refresh records',
            icon: const Icon(Icons.refresh),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Could not refresh server records: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: _loading && _serverRecords.isEmpty && _localRecords.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  children: [
                    const _SectionHeader(
                        'Saved in CI4 / MySQL (visible to this account)'),
                    if (_serverRecords.isEmpty)
                      const ListTile(
                          title: Text('No server process records found.')),
                    for (final row in _serverRecords)
                      _serverTile(row, canDelete),
                    const Divider(height: 24),
                    const _SectionHeader(
                        'Local copies or work not shown in the server list'),
                    if (_localRecords.isEmpty)
                      const ListTile(
                          title:
                              Text('No unsynced or conflicted local records.')),
                    for (final row in _localRecords)
                      _localTile(row, allowDelete: !widget.embedded),
                  ],
                ),
        ),
        if (!widget.embedded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
      ],
    );

    if (widget.embedded) return content;
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      child: SizedBox(
        width: width > 760 ? 720 : width * .94,
        height: MediaQuery.sizeOf(context).height * .82,
        child: content,
      ),
    );
  }

  Widget _serverTile(Map<String, dynamic> row, bool canDelete) {
    final id = int.tryParse(row['id'].toString());
    final active = row['status'] == 'active';
    final owner = row['created_by_user_id']?.toString() ==
        KintaAuthService.currentUser?['id']?.toString();
    final privileged =
        ['admin', 'supervisor'].contains(KintaAuthService.currentUser?['role']);
    final expanded = id != null && _expandedRecords.contains(id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: [
          ListTile(
            onTap: id == null ? null : () => _toggleDetails(id),
            title: Text('#${row['id']} - ${row['activity_name'] ?? 'Process'}'),
            subtitle: Text([
              '${row['machine_name'] ?? 'Machine'} - ${row['sector_name'] ?? 'Sector'}',
              'S/O: ${row['so_number'] ?? 'None'} - Status: ${row['status']}',
              if (row['created_by_name'] != null)
                'Created by: ${row['created_by_name']}',
              if (row['started_at'] != null)
                'Started: ${KintaTime.formatLocal(row['started_at'])}',
              if (row['ended_at'] != null)
                'Ended: ${KintaTime.formatLocal(row['ended_at'])}',
              if (row['qty_passed'] != null || row['qty_rejected'] != null)
                'Passed: ${row['qty_passed'] ?? 0} - Rejected: ${row['qty_rejected'] ?? 0}',
              if (row['remarks'] != null &&
                  row['remarks'].toString().isNotEmpty)
                'Remarks: ${row['remarks']}',
            ].join('\n')),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: expanded ? 'Hide details' : 'View full details',
                  onPressed: id == null ? null : () => _toggleDetails(id),
                  icon: Icon(
                      expanded ? Icons.expand_less : Icons.visibility_outlined),
                ),
                if (canDelete && (owner || privileged))
                  IconButton(
                    tooltip: active
                        ? 'End the process before deleting'
                        : 'Delete this record',
                    onPressed: active || _deleting
                        ? null
                        : () => _deleteServerRecord(row),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
          if (expanded) _detailsPanel(id),
        ],
      ),
    );
  }

  Widget _detailsPanel(int id) {
    if (_loadingDetails.contains(id)) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final details = _details[id];
    if (details == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Full details need a connection to CI4.'),
      );
    }
    final operators = (details['operators'] as List? ?? [])
        .whereType<Map>()
        .map((row) => row['operator_name']?.toString())
        .whereType<String>()
        .toList();
    final inspections = (details['qc_inspections'] as List? ?? [])
        .whereType<Map>()
        .map((row) =>
            '${row['qc_user_name']}: quantity ${row['quantity']} at ${KintaTime.formatLocal(row['inspection_time'])}')
        .toList();
    final problems = (details['problems'] as List? ?? [])
        .whereType<Map>()
        .map((row) => '${row['code']}: ${row['name']}')
        .toList();
    final pics = (details['pic_history'] as List? ?? [])
        .whereType<Map>()
        .map((row) =>
            '${row['supervisor_name']} (${KintaTime.formatLocal(row['started_at'])})')
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text([
        'Customer: ${details['customer_name'] ?? 'None'}',
        'Batch quantity: ${details['batch_qty'] ?? 'None'}',
        'Operators: ${operators.isEmpty ? 'None' : operators.join(', ')}',
        'QC inspections: ${inspections.isEmpty ? 'None' : inspections.join('; ')}',
        'Problems: ${problems.isEmpty ? 'None' : problems.join('; ')}',
        'PIC history: ${pics.isEmpty ? 'None' : pics.join('; ')}',
        if (details['description'] != null)
          'Description: ${details['description']}',
      ].join('\n')),
    );
  }

  Widget _localTile(Map<String, dynamic> row, {required bool allowDelete}) =>
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ListTile(
          title: Text(
            '${row['activity_name'] ?? 'Process'} - Local ${row['local_id']}',
          ),
          subtitle: Text(
            'Status: ${row['sync_status'] ?? 'pending'}${row['sync_error'] == null ? '' : '\n${row['sync_error']}'}\n'
            'Machine: ${row['machine_name'] ?? 'Unknown'} - Sector: ${row['sector_name'] ?? 'Unknown'}\n'
            'Started: ${KintaTime.formatLocal(row['started_at'], assumeLocalWhenUnmarked: true, empty: 'Unknown')}\n'
            'Passed: ${row['qty_passed'] ?? 'Not entered'} - Rejected: ${row['qty_rejected'] ?? 'Not entered'}',
          ),
          trailing: allowDelete && row['server_process_id'] == null
              ? IconButton(
                  tooltip: 'Delete local unsynced record',
                  onPressed: () => _deleteLocalRecord(row),
                  icon: const Icon(Icons.delete_outline),
                )
              : null,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}
