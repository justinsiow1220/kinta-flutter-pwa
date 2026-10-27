import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _ci4TestEndpoint = 'http://localhost:8080/api/flutter-test';
const _ci4DatabaseEndpoint = 'http://localhost:8080/api/flutter-db-test';
const _ci4CrudEndpoint = 'http://localhost:8080/api/flutter-crud-test';
const _ci4MasterDataBaseUrl = 'http://localhost:8080/api/master-data';
const _masterDataEndpoints = <String, String>{
  'Users': 'users',
  'Machines': 'machines',
  'Sectors': 'sectors',
  'Activities': 'activities',
  'Sales orders': 'sales-orders',
  'Problem codes': 'problems',
};

class Ci4ConnectionTestApp extends StatelessWidget {
  const Ci4ConnectionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CI4 Connection Test',
      home: Ci4ConnectionTestPage(),
    );
  }
}

class Ci4ConnectionTestPage extends StatefulWidget {
  const Ci4ConnectionTestPage({super.key});

  @override
  State<Ci4ConnectionTestPage> createState() => _Ci4ConnectionTestPageState();
}

class _Ci4ConnectionTestPageState extends State<Ci4ConnectionTestPage> {
  bool _isLoading = false;
  bool _isMasterDataLoading = false;
  bool _hasLoadedMasterData = false;
  String _result = 'Choose a test to contact CI4.';
  String? _masterDataError;
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  Map<String, List<Map<String, dynamic>>> _masterData = {};

  @override
  void initState() {
    super.initState();
    _loadCrudRecords();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    await _sendRequest('GET', _ci4TestEndpoint);
  }

  Future<void> _readDatabase() async {
    await _sendRequest('GET', _ci4DatabaseEndpoint);
  }

  Future<void> _loadCrudRecords() async {
    await _sendRequest('GET', _ci4CrudEndpoint);
  }

  Future<void> _createCrudRecord() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _result = 'Enter a title for the test record.');
      return;
    }

    final created = await _sendRequest(
      'POST',
      _ci4CrudEndpoint,
      body: {'title': title},
    );

    if (created) {
      _titleController.clear();
      await _loadCrudRecords();
    }
  }

  Future<void> _updateCrudRecord(Map<String, dynamic> record) async {
    final controller = TextEditingController(
      text: record['title']?.toString() ?? '',
    );
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit test record'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (title == null || title.trim().isEmpty) return;

    final id = record['id'];
    final updated = await _sendRequest(
      'PUT',
      '$_ci4CrudEndpoint/$id',
      body: {'title': title.trim()},
    );

    if (updated) await _loadCrudRecords();
  }

  Future<void> _deleteCrudRecord(Map<String, dynamic> record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete test record?'),
        content: Text('Delete "${record['title']}" from the test table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final deleted = await _sendRequest(
      'DELETE',
      '$_ci4CrudEndpoint/${record['id']}',
    );

    if (deleted) await _loadCrudRecords();
  }

  Future<bool> _sendRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    setState(() {
      _isLoading = true;
      _result = '$method $endpoint';
    });

    try {
      final request = http.Request(method, Uri.parse(endpoint))
        ..headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final message = payload['message']?.toString() ?? response.body;
      final data = payload['data'];

      if (data is List) {
        _records = data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }

      if (!mounted) return false;
      setState(() {
        _result = response.statusCode >= 200 && response.statusCode < 300
            ? '$message (HTTP ${response.statusCode})'
            : 'Request failed (HTTP ${response.statusCode}): $message';
      });

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _result = 'Request failed: $error');
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMasterData(String path) async {
    final response = await http.get(
      Uri.parse('$_ci4MasterDataBaseUrl/$path'),
      headers: const {'Accept': 'application/json'},
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? response.body
          : response.body;
      throw Exception('GET $path failed (HTTP ${response.statusCode}): $message');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['success'] != true ||
        decoded['data'] is! List) {
      throw const FormatException('CI4 returned an unexpected master-data response.');
    }

    return (decoded['data'] as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _loadMasterData() async {
    setState(() {
      _isMasterDataLoading = true;
      _masterDataError = null;
    });

    try {
      final entries = await Future.wait(
        _masterDataEndpoints.entries.map((entry) async {
          final records = await _fetchMasterData(entry.value);
          return MapEntry(entry.key, records);
        }),
      );

      if (!mounted) return;
      setState(() {
        _masterData = Map.fromEntries(entries);
        _hasLoadedMasterData = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _masterDataError = error.toString());
    } finally {
      if (mounted) setState(() => _isMasterDataLoading = false);
    }
  }

  String _masterDataLabel(String category, Map<String, dynamic> record) {
    switch (category) {
      case 'Users':
        return '${record['name']} · ${record['role']} · ${record['employee_no']}';
      case 'Machines':
        return '${record['machine_code']} · ${record['machine_name']}';
      case 'Sectors':
        return record['name']?.toString() ?? '';
      case 'Activities':
        return '${record['name']} · Sector ${record['sector_id']}';
      case 'Sales orders':
        return '${record['so_number']} · ${record['customer_name']} · Qty ${record['batch_qty']}';
      case 'Problem codes':
        return '${record['code']} · ${record['name']}';
      default:
        return record.toString();
    }
  }

  Widget _buildMasterDataCard(
    String category,
    List<Map<String, dynamic>> records,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (records.isEmpty)
              const Text('No records available yet.')
            else
              for (final record in records)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_masterDataLabel(category, record)),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter → CI4 test')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Checkpoint 2: call the dummy CI4 API',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  child: const Text('Test CI4 Connection'),
                ),
                const Divider(height: 32),
                const Text(
                  'Checkpoint 4: read test data through CI4 from MySQL',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _readDatabase,
                  child: const Text('Read MySQL Test Data'),
                ),
                const Divider(height: 32),
                const Text(
                  'Checkpoint 5: isolated test-table CRUD',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Test record title',
                    border: OutlineInputBorder(),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createCrudRecord,
                      child: const Text('Create'),
                    ),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _loadCrudRecords,
                      child: const Text('Refresh list'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(_result, textAlign: TextAlign.center),
                for (final record in _records)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record['title']?.toString() ?? ''),
                    subtitle: Text('Test record #${record['id']}'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Edit test record',
                          onPressed: _isLoading
                              ? null
                              : () => _updateCrudRecord(record),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Delete test record',
                          onPressed: _isLoading
                              ? null
                              : () => _deleteCrudRecord(record),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 32),
                const Text(
                  'Checkpoint 6: load KINTA master data from CI4',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isMasterDataLoading ? null : _loadMasterData,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _isMasterDataLoading ? 'Loading master data…' : 'Load master data',
                  ),
                ),
                if (_isMasterDataLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_masterDataError != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    'Could not load master data: $_masterDataError',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (_hasLoadedMasterData)
                  for (final entry in _masterData.entries)
                    _buildMasterDataCard(entry.key, entry.value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
