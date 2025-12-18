import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/logger.dart';
import 'package:glamify/controller/web_image_service.dart';

class ImageService {
  /// ضغط الصورة - متوافق مع الويب والموبايل
  static Future<Uint8List?> compressImage(File file) async {
    try {
      if (kIsWeb) {
        // للويب - قراءة الملف كـ bytes ثم ضغطه
        final bytes = await file.readAsBytes();
        return await WebImageService.compressImage(bytes);
      } else {
        // للموبايل - استخدام flutter_image_compress
        final result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          quality: 70, 
          minWidth: 1024, 
          minHeight: 1024,
        );
        return result;
      }
    } catch (e) {
      AppLogger.error('فشل ضغط الصورة', tag: 'IMAGE_SERVICE', error: e);
      return null;
    }
  }

  /// ضغط الصورة من Uint8List - متوافق مع الويب والموبايل
  static Future<Uint8List?> compressImageBytes(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // للويب - استخدام WebImageService
        return await WebImageService.compressImage(imageBytes);
      } else {
        // للموبايل - استخدام flutter_image_compress
        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
        );
        return result;
      }
    } catch (e) {
      AppLogger.error('فشل ضغط بيانات الصورة', tag: 'IMAGE_SERVICE', error: e);
      return null;
    }
  }
}
