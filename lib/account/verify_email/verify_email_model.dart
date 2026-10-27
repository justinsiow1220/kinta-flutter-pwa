import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'verify_email_widget.dart' show VerifyEmailWidget;
import 'package:flutter/material.dart';

class VerifyEmailModel extends FlutterFlowModel<VerifyEmailWidget> {
  ///  Local state fields for this page.

  String? timeEmailSent;

  bool isNavigating = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (CheckVerificationStatus)] action in VerifyEmail widget.
  ApiCallResponse? apiResultfb6;
  InstantTimer? instantTimer;
  // Stores action output result for [Backend Call - API (CheckVerificationStatus)] action in VerifyEmail widget.
  ApiCallResponse? apiResultuux;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
