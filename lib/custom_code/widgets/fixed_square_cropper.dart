// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
import 'dart:convert';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

class FixedSquareCropper extends StatefulWidget {
  const FixedSquareCropper({
    super.key,
    this.width,
    this.height,
    this.imageFile,
    this.callBackAction,
    this.defectElement,
    this.projectTitle,
    this.seq,
    this.stampPhoto,
  });

  final double? width;
  final double? height;
  final FFUploadedFile? imageFile;
  final Future Function(String? base64String)? callBackAction;
  final String? defectElement;
  final String? projectTitle;
  final String? seq;
  final bool? stampPhoto;

  @override
  State<FixedSquareCropper> createState() => _FixedSquareCropperState();
}

class _FixedSquareCropperState extends State<FixedSquareCropper> {
  final _cropController = CropController();
  bool _isProcessing = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageFile?.bytes == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "No image data found",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // LAYER 1: Main UI (Always running so Crop can decode bytes)
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Crop(
                        // FIXED: Reverted back to raw bytes as required by your package version
                        image: widget.imageFile!.bytes!,
                        controller: _cropController,
                        aspectRatio: 1 / 1, // Matches Requirement: ratio 1:1
                        initialSize: 1.0,
                        interactive: !_isProcessing,
                        onStatusChanged: (CropStatus status) {
                          if (status == CropStatus.ready && _isInitialLoading) {
                            setState(() {
                              _isInitialLoading = false;
                            });
                          }
                        },
                        onCropped: (dynamic result) async {
                          Uint8List? croppedBytes;
                          if (result is Uint8List) {
                            croppedBytes = result;
                          } else {
                            try {
                              croppedBytes = result.croppedImage;
                            } catch (e) {}
                          }

                          if (croppedBytes != null) {
                            try {
                              // 1. Decode the cropped image using your existing package
                              img.Image? decodedImage =
                                  img.decodeImage(croppedBytes);

                              if (decodedImage != null) {
                                // 2. Force downscaling strictly to 800x800 box size
                                // Uses cubic interpolation to smooth out textures for tighter compression
                                img.Image resizedImage = img.copyResize(
                                  decodedImage,
                                  width: 800,
                                  height: 800,
                                  interpolation: img.Interpolation.cubic,
                                );

                                // 3. Re-encode directly to JPEG at 75% quality
                                // This strips all camera metadata and shrinks the file size down to ~100KB
                                croppedBytes = Uint8List.fromList(
                                    img.encodeJpg(resizedImage, quality: 75));

                                print(
                                    "SUCCESS! Compressed size: ${(croppedBytes.length / 1024).toStringAsFixed(2)} KB");
                              }
                            } catch (e) {
                              print("Compression error fallback: $e");
                            }

                            // 4. Encodes the highly compressed data array into Base64
                            final base64Image = base64Encode(croppedBytes!);
                            if (widget.callBackAction != null) {
                              await widget.callBackAction!(base64Image);
                            }
                          }

                          if (mounted) {
                            setState(() => _isProcessing = false);
                            Navigator.of(context, rootNavigator: false).pop();
                          }
                        },

                        baseColor: Colors.black,
                        maskColor: Colors.black.withValues(alpha: 0.7),
                        cornerDotBuilder: (size, edgeAlignment) =>
                            const SizedBox.shrink(),
                      ),
                      Positioned(
                        top: 40,
                        right: 15,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              if (!_isProcessing) {
                                Navigator.of(context, rootNavigator: false)
                                    .pop();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 50.0, top: 20.0),
                  color: Colors.black,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              setState(() => _isProcessing = true);
                              _cropController.crop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B39EF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(width: 24, height: 24)
                          : const Text("Crop & Save",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),

            // LAYER 2: Processing screen
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4B39EF)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Processing Image...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // LAYER 3: Initial loading
            if (_isInitialLoading)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4B39EF)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Loading Image...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
