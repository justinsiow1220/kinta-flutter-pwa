// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:crop_your_image/crop_your_image.dart';

class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    this.width,
    this.height,
    this.imageFile,
    this.callBackAction,
    this.currentUserId,
  });

  final double? width;
  final double? height;
  final FFUploadedFile? imageFile;
  final Future Function(String? base64String)? callBackAction;
  final String? currentUserId;

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  bool loading = false;
  final _crop_controller = CropController();

  @override
  Widget build(BuildContext context) {
    if (widget.imageFile == null || widget.imageFile!.bytes == null) {
      return const Center(child: Text("No image selected"));
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Column(
            children: [
              // 1. CROP AREA
              Expanded(
                child: Crop(
                  image: widget.imageFile!.bytes!,
                  controller: _crop_controller,
                  // If 'result' is not CropSuccess, it is treated as Uint8List
                  onCropped: (dynamic result) async {
                    Uint8List? imageBytes;

                    if (result is Uint8List) {
                      imageBytes = result;
                    } else {
                      // Fallback for versions that use the 'croppedImage' property
                      try {
                        imageBytes = result.croppedImage;
                      } catch (e) {
                        print("Error parsing crop result: $e");
                      }
                    }

                    if (imageBytes != null) {
                      String base64Image = base64Encode(imageBytes);
                      if (widget.callBackAction != null) {
                        await widget.callBackAction!(base64Image);
                      }
                    }

                    if (mounted) {
                      setState(() => loading = false);
                      Navigator.pop(context);
                    }
                  },
                  aspectRatio: 1 / 1,
                  withCircleUi: false,
                  baseColor: const Color.fromARGB(255, 0, 3, 22),
                  maskColor: Colors.white.withAlpha(100),
                  interactive: true,
                ),
              ),

              // 2. BUTTON AREA
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!loading) {
                          setState(() => loading = true);
                          _crop_controller.crop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Crop & Save',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. CLOSE BUTTON
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}
