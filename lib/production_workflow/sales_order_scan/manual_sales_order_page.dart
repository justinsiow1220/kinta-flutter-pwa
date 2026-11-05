import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';
import '/auth/kinta_auth_service.dart';
import '/offline/kinta_local_repository.dart';

class ManualSalesOrderWidget extends StatefulWidget {
  const ManualSalesOrderWidget({super.key});

  static const String routeName = 'ManualSalesOrder';
  static const String routePath = '/manualSalesOrder';

  @override
  State<ManualSalesOrderWidget> createState() => _ManualSalesOrderWidgetState();
}

class _ManualSalesOrderWidgetState extends State<ManualSalesOrderWidget> {
  final _formKey = GlobalKey<FormState>();
  final _soNumberController = TextEditingController();
  final _customerController = TextEditingController();
  final _batchQtyController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _soNumberController.dispose();
    _customerController.dispose();
    _batchQtyController.dispose();
    super.dispose();
  }

  Future<void> _saveSalesOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final soNumber = _soNumberController.text.trim();
      final customerName = _customerController.text.trim();
      final batchQty = int.parse(_batchQtyController.text.trim());
      await _rejectKnownDuplicateSalesOrder(soNumber);
      Map<String, dynamic>? order;
      var queuedOffline = false;
      try {
        order = await KintaApiService.postJson(
          'master-data/sales-orders',
          {
            'so_number': soNumber,
            'customer_name': customerName,
            'batch_qty': batchQty,
          },
        );
      } on http.ClientException {
        // The process queue uploads this order before it uploads the process.
        queuedOffline = true;
        await KintaLocalRepository.savePendingSalesOrder({
          'so_number': soNumber,
          'customer_name': customerName,
          'batch_qty': batchQty,
          'actor_user_id': KintaAuthService.currentUser?['id'],
        });
      }
      if (order != null) {
        try {
          await KintaLocalRepository.removePendingSalesOrder(soNumber);
        } catch (_) {}
      }

      final draft = KintaProcessDraft.instance;
      draft.prepareForNewProcess();
      draft
        ..salesOrderId = int.tryParse(order?['id']?.toString() ?? '')
        ..soNumber = order?['so_number']?.toString() ?? soNumber
        ..customerName = order?['customer_name']?.toString() ?? customerName
        ..batchQty =
            int.tryParse(order?['batch_qty']?.toString() ?? '') ?? batchQty;
      draft.persistInBackground();

      if (mounted) {
        if (queuedOffline) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Sales order saved on this device. It will sync with the process when online.'),
          ));
        }
        await context.pushNamed('ProcessxScan0');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rejectKnownDuplicateSalesOrder(String soNumber) async {
    List<Map<String, dynamic>> cachedOrders;
    try {
      // This refreshes the cache when online and falls back to the last
      // downloaded sales-order list when the device is offline.
      cachedOrders = await KintaApiService.getList('master-data/sales-orders');
    } on http.ClientException {
      cachedOrders = await KintaLocalRepository.readMasterDataList(
            'master-data/sales-orders',
          ) ??
          <Map<String, dynamic>>[];
    }

    final normalizedNumber = soNumber.trim().toLowerCase();
    final existsOnServerCache = cachedOrders.any((order) =>
        order['so_number']?.toString().trim().toLowerCase() ==
        normalizedNumber);
    final actorUserId = KintaAuthService.currentUser?['id']?.toString();
    final pendingOrders = await KintaLocalRepository.readPendingSalesOrders(
      actorUserId: actorUserId,
    );
    final alreadyQueued = pendingOrders.any((order) =>
        order['so_number']?.toString().trim().toLowerCase() ==
        normalizedNumber);

    if (existsOnServerCache || alreadyQueued) {
      throw StateError(
        'Sales order number $soNumber already exists${alreadyQueued ? ' in the local queue' : ' in the cached sales orders'}. Enter a different sales order number.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.info,
        title: const Text('Manual Sales Order'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter Sales Order Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _soNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Sales Order Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a sales order number.'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _customerController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a customer name.'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _batchQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batch Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final quantity = int.tryParse(value?.trim() ?? '');
                        if (quantity == null || quantity < 1) {
                          return 'Enter a whole number greater than zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveSalesOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(_saving ? 'Saving...' : 'Save'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saving ? null : () => context.pop(),
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
            ),
          ),
        ),
      ),
    );
  }
}
