import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'change_p_i_c_widget.dart' show ChangePICWidget;
import 'package:flutter/material.dart';

class ChangePICModel extends FlutterFlowModel<ChangePICWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for DropDown widget.
  List<String>? dropDownValue;
  FormFieldController<List<String>>? dropDownValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  late FocusNode textFieldPasswordVisibilityFocusNode2;
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController2Validator;

  @override
  void initState(BuildContext context) {
    textFieldPasswordVisibilityFocusNode2 = FocusNode();
    passwordVisibility = false;
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();
    textFieldPasswordVisibilityFocusNode2.dispose();
  }
}
