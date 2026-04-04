import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:glamify/controller/web_image_service.dart';
import '../utils/logger.dart';

// Conditional import for mobile-only compression
import 'image_compress_io_helper.dart'
    if (dart.library.html) 'image_compress_web_helper.dart';

class ImageService {
  /// ضغط الصورة من مسار ملف (للموبايل فقط)
  /// على الويب يرجع null - استخدم compressImageBytes بدلاً منه
  static Future<Uint8List?> compressImageFromPath(String filePath) async {
    try {
      if (kIsWeb) {
        // على الويب لا يمكن الضغط من مسار ملف
        AppLogger.warning('compressImageFromPath غير مدعوم على الويب', tag: 'IMAGE_SERVICE');
        return null;
      }
      // على الموبايل - استخدام flutter_image_compress
      return await platformCompressFile(filePath);
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
        return await platformCompressList(imageBytes);
      }
    } catch (e) {
      AppLogger.error('فشل ضغط بيانات الصورة', tag: 'IMAGE_SERVICE', error: e);
      return null;
    }
  }
}

