import '/flutter_flow/flutter_flow_util.dart';
import 'change_password_widget.dart' show ChangePasswordWidget;
import 'package:flutter/material.dart';

class ChangePasswordModel extends FlutterFlowModel<ChangePasswordWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for ExistingPassword widget.
  late FocusNode existingPasswordPasswordVisibilityFocusNode;
  FocusNode? existingPasswordFocusNode;
  TextEditingController? existingPasswordTextController;
  late bool existingPasswordVisibility;
  String? Function(BuildContext, String?)?
      existingPasswordTextControllerValidator;
  // State field(s) for NewPassword widget.
  late FocusNode newPasswordPasswordVisibilityFocusNode;
  FocusNode? newPasswordFocusNode;
  TextEditingController? newPasswordTextController;
  late bool newPasswordVisibility;
  String? Function(BuildContext, String?)? newPasswordTextControllerValidator;
  // State field(s) for ConfirmNewPassword widget.
  late FocusNode confirmNewPasswordPasswordVisibilityFocusNode;
  FocusNode? confirmNewPasswordFocusNode;
  TextEditingController? confirmNewPasswordTextController;
  late bool confirmNewPasswordVisibility;
  String? Function(BuildContext, String?)?
      confirmNewPasswordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    existingPasswordPasswordVisibilityFocusNode = FocusNode();
    existingPasswordVisibility = false;
    newPasswordPasswordVisibilityFocusNode = FocusNode();
    newPasswordVisibility = false;
    confirmNewPasswordPasswordVisibilityFocusNode = FocusNode();
    confirmNewPasswordVisibility = false;
  }

  @override
  void dispose() {
    existingPasswordFocusNode?.dispose();
    existingPasswordTextController?.dispose();
    existingPasswordPasswordVisibilityFocusNode.dispose();
    newPasswordFocusNode?.dispose();
    newPasswordTextController?.dispose();
    newPasswordPasswordVisibilityFocusNode.dispose();
    confirmNewPasswordFocusNode?.dispose();
    confirmNewPasswordTextController?.dispose();
    confirmNewPasswordPasswordVisibilityFocusNode.dispose();
  }
}
