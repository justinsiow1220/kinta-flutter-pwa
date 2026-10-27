import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'signup_widget.dart' show SignupWidget;
import 'package:flutter/material.dart';

class SignupModel extends FlutterFlowModel<SignupWidget> {
  ///  Local state fields for this page.

  String? email;

  /// email sent at this time
  String? timeEmailSent;

  bool agreeTerm = false;

  bool isPdfLoading = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for name_Create widget.
  FocusNode? nameCreateFocusNode;
  TextEditingController? nameCreateTextController;
  String? Function(BuildContext, String?)? nameCreateTextControllerValidator;
  // State field(s) for emailAddress_Create widget.
  FocusNode? emailAddressCreateFocusNode;
  TextEditingController? emailAddressCreateTextController;
  String? Function(BuildContext, String?)?
      emailAddressCreateTextControllerValidator;
  // State field(s) for password_Create widget.
  late FocusNode passwordCreatePasswordVisibilityFocusNode;
  FocusNode? passwordCreateFocusNode;
  TextEditingController? passwordCreateTextController;
  late bool passwordCreateVisibility;
  String? Function(BuildContext, String?)?
      passwordCreateTextControllerValidator;
  // State field(s) for passwordConfirm widget.
  late FocusNode passwordConfirmPasswordVisibilityFocusNode;
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  late bool passwordConfirmVisibility;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    passwordCreatePasswordVisibilityFocusNode = FocusNode();
    passwordCreateVisibility = false;
    passwordConfirmPasswordVisibilityFocusNode = FocusNode();
    passwordConfirmVisibility = false;
  }

  @override
  void dispose() {
    nameCreateFocusNode?.dispose();
    nameCreateTextController?.dispose();

    emailAddressCreateFocusNode?.dispose();
    emailAddressCreateTextController?.dispose();

    passwordCreateFocusNode?.dispose();
    passwordCreateTextController?.dispose();
    passwordCreatePasswordVisibilityFocusNode.dispose();
    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
    passwordConfirmPasswordVisibilityFocusNode.dispose();
  }
}
