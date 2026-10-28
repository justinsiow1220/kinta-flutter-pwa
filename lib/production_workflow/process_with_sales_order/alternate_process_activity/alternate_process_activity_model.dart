import '/flutter_flow/flutter_flow_util.dart';
import 'alternate_process_activity_page.dart' show ProcesswScan3Widget;
import 'package:flutter/material.dart';

class ProcesswScan3Model extends FlutterFlowModel<ProcesswScan3Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
