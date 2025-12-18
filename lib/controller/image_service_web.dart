// Web-only image service
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class WebImageServiceImpl {
  /// ضغط الصورة للويب باستخدام Canvas
  static Future<Uint8List?> compressImage(Uint8List imageBytes, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      // إنشاء blob من البيانات
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrl(blob);
      
      // إنشاء عنصر صورة
      final img = html.ImageElement();
      img.src = url;
      
      // انتظار تحميل الصورة
      await img.onLoad.first;
      
      // حساب الأبعاد الجديدة
      final originalWidth = img.naturalWidth;
      final originalHeight = img.naturalHeight;
      
      double ratio = 1.0;
      if (originalWidth > maxWidth || originalHeight > maxHeight) {
        ratio = (maxWidth / originalWidth < maxHeight / originalHeight)
            ? maxWidth / originalWidth
            : maxHeight / originalHeight;
      }
      
      final newWidth = (originalWidth * ratio).round();
      final newHeight = (originalHeight * ratio).round();
      
      // إنشاء canvas لضغط الصورة
      final canvas = html.CanvasElement(width: newWidth, height: newHeight);
      final ctx = canvas.context2D;
      
      // رسم الصورة المضغوطة
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);
      
      // تحويل إلى blob مضغوط
      final compressedBlob = await canvas.toBlob('image/jpeg', quality / 100);
      
      // قراءة البيانات
      final reader = html.FileReader();
      reader.readAsArrayBuffer(compressedBlob);
      await reader.onLoad.first;
      
      // تنظيف الذاكرة
      html.Url.revokeObjectUrl(url);
      
      return Uint8List.fromList((reader.result as List<int>));
      
    } catch (e) {
      AppLogger.error('فشل ضغط الصورة على الويب', tag: 'IMAGE_WEB', error: e);
      return null;
    }
  }
  
  /// ضغط صورة من ملف مختار
  static Future<Uint8List?> compressFileImage(html.File file, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      // قراءة الملف كـ Uint8List
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final imageBytes = Uint8List.fromList((reader.result as List<int>));
      
      // ضغط الصورة
      return await compressImage(
        imageBytes,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
    } catch (e) {
      AppLogger.error('فشل ضغط ملف الصورة', tag: 'IMAGE_WEB', error: e);
      return null;
    }
  }
}
