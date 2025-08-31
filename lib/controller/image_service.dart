import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  // Compresses the image file and returns the compressed file as Uint8List.
  static Future<Uint8List?> compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 70, 
        minWidth: 1024, 
        minHeight: 1024,
      );
      return result;
    } catch (e) {
      debugPrint('Failed to compress image: $e');
      return null;
    }
  }
}
