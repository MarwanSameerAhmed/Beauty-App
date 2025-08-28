import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  // Compresses the image file and returns the compressed file as Uint8List.
  static Future<Uint8List?> compressImage(File file) async {
    try {
      // Compress the image directly to a Uint8List.
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 70, // Adjust quality (0-100)
        minWidth: 1024, // Adjust resolution
        minHeight: 1024,
      );
      return result;
    } catch (e) {
      debugPrint('Failed to compress image: $e');
      return null;
    }
  }
}
