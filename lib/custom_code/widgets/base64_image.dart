// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:typed_data';

class Base64Image extends StatefulWidget {
  const Base64Image({
    super.key,
    this.width,
    this.height,
    this.base64String,
  });

  final double? width;
  final double? height;
  final String? base64String;

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  @override
  Widget build(BuildContext context) {
    // 1. Check if the string is null or empty
    if (widget.base64String == null || widget.base64String!.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFEEEEEE),
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    // 2. Check if it's a URL (Network Image)
    if (widget.base64String!.startsWith('http')) {
      String finalUrl = widget.base64String!;

      return Image.network(
        finalUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.fill,
        gaplessPlayback: true, // 🟢 FIXED: Stops network image
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.red),
        ),
      );
    }

    // 3. Otherwise, try to decode as Base64 (Memory Image)
    try {
      String cleanString = widget.base64String!.contains(',')
          ? widget.base64String!.split(',').last
          : widget.base64String!;

      Uint8List bytes = base64Decode(cleanString);

      return Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.fill,
        gaplessPlayback: true, // 🟢 FIXED: Stops base64 decoding
      );
    } catch (e) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.red),
      );
    }
  }
}
