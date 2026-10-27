// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

Future openCasePdfInBrowser(String caseId) async {
  try {
    // 1. Replicate Yanwu's 'encode_case_id' logic using Base64
    final String plainText = "dfx-$caseId-mydefix";

    // Encode to base64 URL format and remove trailing padding characters
    final String encodedId =
        base64Url.encode(utf8.encode(plainText)).replaceAll('=', '');

    // 2. Build the final download URL target
    const String downloadUrl = "https://mydefix.com";
    final Uri url = Uri.parse(downloadUrl);

    // 3. Force launch directly inside the device's default web browser
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch browser application.');
    }
  } catch (e) {
    print('Error opening PDF: $e');
  }
}
