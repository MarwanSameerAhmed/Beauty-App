import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// ضغط صورة من مسار ملف (موبايل فقط)
Future<Uint8List?> platformCompressFile(String filePath) async {
  return await FlutterImageCompress.compressWithFile(
    filePath,
    quality: 70,
    minWidth: 1024,
    minHeight: 1024,
  );
}

/// ضغط صورة من Uint8List (موبايل)
Future<Uint8List?> platformCompressList(Uint8List imageBytes) async {
  return await FlutterImageCompress.compressWithList(
    imageBytes,
    quality: 70,
    minWidth: 1024,
    minHeight: 1024,
  );
}
