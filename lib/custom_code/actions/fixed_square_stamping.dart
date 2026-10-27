// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img; // The library import is right here!

// Set your action name, define your arguments and return ,
// and then add the boilerplate code using the green button on  right!
Future<List<dynamic>?> fixedSquareStamping(
  List<dynamic>? imageObjects,
  String? projectTitle,
  String? defectElement,
  String? defectElementID,
  String? seq,
) async {
  if (imageObjects == null || imageObjects.isEmpty) return [];

  List<dynamic> stampedJsonResults = [];

  final now = DateTime.now();
  final isPm = now.hour >= 12;
  final period = isPm ? 'pm' : 'am';
  int hour12 = now.hour % 12;
  if (hour12 == 0) hour12 = 12;

  final timestamp =
      "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}, "
      "${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}$period";

  final line1Text = projectTitle ?? 'Unknown';
  // final line2Text = "Defect #${seq ?? '0'} - ${defectElement ?? 'Unknown'}";

  int maxCharacters = line1Text.length;
  if (timestamp.length > maxCharacters) {
    maxCharacters = timestamp.length;
  }

  // Dynamic Box Width: Left Margin (10) + (Char Cont * Average Width of  24) + Extra Right Padding
  int dynamicX2 = 5 + (maxCharacters * 13);

  for (var item in imageObjects) {
    if (item is! Map) {
      stampedJsonResults.add(item);
      continue;
    }

    Map<String, dynamic> outputJsonMap = {};
    item.forEach((key, value) {
      outputJsonMap[key.toString()] = value;
    });

    outputJsonMap['needed_remove'] = false;
    Uint8List? fileBytes;

    if (outputJsonMap['photo_url'] is String &&
        outputJsonMap['photo_url'].toString().isNotEmpty) {
      String photoUrlStr = outputJsonMap['photo_url'].toString().trim();

      try {
        // Automatically strip headers like "data:image/jpeg;base64," if present
        if (photoUrlStr.contains(',')) {
          photoUrlStr = photoUrlStr.split(',').last;
        }
        fileBytes = base64Decode(photoUrlStr.trim());
      } catch (e) {
        print("Error decoding base64 from photo_url: $e");
      }
    }

    // Binary byte payload fallbacks for local memory buffers
    if (fileBytes == null) {
      final fileData = outputJsonMap['bytes'] ??
          outputJsonMap['fileBytes'] ??
          outputJsonMap['uploadedFile'];

      if (fileData is Uint8List) {
        fileBytes = fileData;
      } else if (fileData is List) {
        fileBytes = Uint8List.fromList(List<int>.from(fileData));
      } else if (fileData != null) {
        try {
          if (fileData.bytes is Uint8List) {
            fileBytes = fileData.bytes;
          }
        } catch (_) {}
      }
    }

    if (fileBytes == null) {
      stampedJsonResults.add(outputJsonMap);
      continue;
    }

    final isCurrentItemNew =
        outputJsonMap['is_new'] == true || outputJsonMap['is_new'] == 'true';

    try {
      if (isCurrentItemNew) {
        img.Image? workingImage = img.decodeImage(fileBytes);
        if (workingImage != null) {
          img.drawString(workingImage, line1Text,
              font: img.arial24,
              x: 20,
              y: 720,
              color: img.ColorRgb8(255, 255, 255));
          img.drawString(workingImage, timestamp,
              font: img.arial24,
              x: 20,
              y: 750,
              color: img.ColorRgb8(255, 255, 255));

          Uint8List stampedBytes =
              Uint8List.fromList(img.encodeJpg(workingImage, quality: 80));
          outputJsonMap['photo_url'] = base64Encode(stampedBytes);
        }
      }
    } catch (e) {
      print("Error during operational image execution pass: $e");
    }

    stampedJsonResults.add(outputJsonMap);
  }

  return stampedJsonResults;
}
