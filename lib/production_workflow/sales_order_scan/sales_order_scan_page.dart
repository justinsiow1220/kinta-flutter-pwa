import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:convert';
import '/index.dart';
import '/kinta_api_service.dart';
import '/kinta_process_draft.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_vision/qr_code_vision.dart';
import 'sales_order_scan_model.dart';
export 'sales_order_scan_model.dart';

class ScanSalesOrderWidget extends StatefulWidget {
  const ScanSalesOrderWidget({super.key});

  static String routeName = 'ScanSalesOrder';
  static String routePath = '/scanSalesOrder';

  @override
  State<ScanSalesOrderWidget> createState() => _ScanSalesOrderWidgetState();
}

class _ScanSalesOrderWidgetState extends State<ScanSalesOrderWidget> {
  late ScanSalesOrderModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handlingScan = false;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScanSalesOrderModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _handleQrCode(String value) async {
    if (_handlingScan) return;
    _handlingScan = true;
    try {
      final payload = jsonDecode(value);
      if (payload is! Map) {
        throw const FormatException(
            'The QR code must contain a JSON sales order.');
      }
      final orderPayload = payload['sales_order'] is Map
          ? Map<String, dynamic>.from(payload['sales_order'] as Map)
          : Map<String, dynamic>.from(payload);
      final soNumber = (orderPayload['so_number'] ??
              orderPayload['sales_order_number'] ??
              orderPayload['salesOrderNumber'])
          ?.toString()
          .trim();
      final customerName = (orderPayload['customer_name'] ??
              orderPayload['customer'] ??
              orderPayload['customerName'])
          ?.toString()
          .trim();
      final batchQty = int.tryParse(
        (orderPayload['batch_qty'] ??
                orderPayload['quantity'] ??
                orderPayload['batchQty'])
            .toString(),
      );
      if (soNumber == null || soNumber.isEmpty) {
        throw const FormatException('The QR code is missing so_number.');
      }
      if (customerName == null || customerName.isEmpty) {
        throw const FormatException('The QR code is missing customer_name.');
      }
      if (batchQty == null || batchQty < 1) {
        throw const FormatException(
            'The QR code must contain a positive batch_qty.');
      }

      final order = await KintaApiService.postJson(
        'master-data/sales-orders',
        {
          'so_number': soNumber,
          'customer_name': customerName,
          'batch_qty': batchQty,
        },
      );

      KintaProcessDraft.instance.prepareForNewProcess();
      KintaProcessDraft.instance
        ..salesOrderId = int.tryParse(order['id']?.toString() ?? '')
        ..soNumber = order['so_number']?.toString()
        ..customerName = order['customer_name']?.toString()
        ..batchQty = int.tryParse(order['batch_qty']?.toString() ?? '');
      KintaProcessDraft.instance.persistInBackground();
      if (mounted) context.pushNamed(ProcesswScan0Widget.routeName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      _handlingScan = false;
    }
  }

  Future<void> _scanFromImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final qrCode = QrCode();
      qrCode.scanImageBytes(await file.readAsBytes());
      final value = qrCode.content?.text;
      if (value == null || value.trim().isEmpty) {
        throw Exception('No QR code was found in that image.');
      }
      await _handleQrCode(value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
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
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(HomeWidget.routePath);
              }
            },
          ),
          title: Text(
            'Scan Sales Order',
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
          actions: const [],
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
                                  Container(
                                    width: 300,
                                    height: 300,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: MobileScanner(
                                      controller: _scannerController,
                                      errorBuilder: (context, error, child) {
                                        final message =
                                            switch (error.errorCode) {
                                          MobileScannerErrorCode.unsupported =>
                                            'No usable camera was found. Use “Scan from image” below.',
                                          MobileScannerErrorCode
                                                .permissionDenied =>
                                            'Camera access is blocked. Allow camera access or use “Scan from image” below.',
                                          _ =>
                                            'Live scanning is unavailable. Use “Scan from image” below.',
                                        };
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.no_photography_outlined,
                                                  color: Colors.white,
                                                  size: 42,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  message,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      onDetect: (capture) {
                                        final value = capture.barcodes.isEmpty
                                            ? null
                                            : capture.barcodes.first.rawValue;
                                        if (value != null) _handleQrCode(value);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed:
                                        _pickingImage ? null : _scanFromImage,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(240, 52),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    icon: _pickingImage
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.image_search),
                                    label: const Text('Scan from image'),
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
                                                            onPressed:
                                                                () async {
                                                              context.pushNamed(
                                                                  HomeWidget
                                                                      .routeName);
                                                            },
                                                            text: 'Cancel',
                                                            options:
                                                                FFButtonOptions(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  0.5,
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
