import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';

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
      final order = await KintaApiService.postJson(
        'master-data/sales-orders',
        {
          'so_number': _soNumberController.text.trim(),
          'customer_name': _customerController.text.trim(),
          'batch_qty': int.parse(_batchQtyController.text.trim()),
        },
      );

      final draft = KintaProcessDraft.instance;
      draft.prepareForNewProcess();
      draft
        ..salesOrderId = int.tryParse(order['id']?.toString() ?? '')
        ..soNumber = order['so_number']?.toString()
        ..customerName = order['customer_name']?.toString()
        ..batchQty = int.tryParse(order['batch_qty']?.toString() ?? '');
      draft.persistInBackground();

      if (mounted) {
        await context.pushNamed('ProcesswScan0');
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
                      validator: (value) => value == null || value.trim().isEmpty
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
                      validator: (value) => value == null || value.trim().isEmpty
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
