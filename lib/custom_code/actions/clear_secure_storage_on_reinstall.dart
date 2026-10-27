// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!

import 'package:shared_preferences/shared_preferences.dart';

Future clearSecureStorageOnReinstall() async {
  try {
    const key = "isFirstRun";
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(key) ?? true;

    if (isFirstRun) {
      // Manually wipe your sensitive fields to empty string or null values
      FFAppState().jwtToken = "";
      FFAppState().userRole = "";
      FFAppState().userID = "";
      FFAppState().companyID = "";
      FFAppState().userName = "";
      FFAppState().isAdmin = "";

      // Save that the first run is complete using regular SharedPreferences
      await prefs.setBool(key, false);

      debugPrint("First run detected: Targeted login tokens cleared.");
    } else {
      debugPrint("Not first run: App State preserved.");
    }
  } catch (e) {
    debugPrint("Error clearing storage on reinstall: ${e.toString()}");
  }
}
