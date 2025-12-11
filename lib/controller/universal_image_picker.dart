import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

class UniversalImagePicker {
  static final ImagePicker _imagePicker = ImagePicker();

  /// اختيار صورة واحدة - متوافق مع الويب والموبايل
  static Future<ImagePickerResult?> pickSingleImage() async {
    try {
      if (kIsWeb) {
        // للويب - استخدام file_picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          return ImagePickerResult(
            bytes: file.bytes!,
            name: file.name,
            size: file.size,
          );
        }
      } else {
        // للموبايل - استخدام image_picker
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (image != null) {
          final bytes = await image.readAsBytes();
          return ImagePickerResult(
            bytes: bytes,
            name: image.name,
            size: bytes.length,
            file: io.File(image.path),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في اختيار الصورة: $e');
    }
    return null;
  }

  /// اختيار صور متعددة - متوافق مع الويب والموبايل
  static Future<List<ImagePickerResult>> pickMultipleImages() async {
    List<ImagePickerResult> results = [];
    
    try {
      if (kIsWeb) {
        // للويب - استخدام file_picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null) {
          for (var file in result.files) {
            if (file.bytes != null) {
              results.add(ImagePickerResult(
                bytes: file.bytes!,
                name: file.name,
                size: file.size,
              ));
            }
          }
        }
      } else {
        // للموبايل - استخدام image_picker
        final List<XFile> images = await _imagePicker.pickMultiImage(
          imageQuality: 85,
        );

        for (var image in images) {
          final bytes = await image.readAsBytes();
          results.add(ImagePickerResult(
            bytes: bytes,
            name: image.name,
            size: bytes.length,
            file: io.File(image.path),
          ));
        }
      }
    } catch (e) {
      debugPrint('خطأ في اختيار الصور: $e');
    }
    
    return results;
  }

  /// التقاط صورة بالكاميرا (للموبايل فقط)
  static Future<ImagePickerResult?> captureImage() async {
    if (kIsWeb) {
      debugPrint('الكاميرا غير مدعومة على الويب');
      return null;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        return ImagePickerResult(
          bytes: bytes,
          name: image.name,
          size: bytes.length,
          file: io.File(image.path),
        );
      }
    } catch (e) {
      debugPrint('خطأ في التقاط الصورة: $e');
    }
    return null;
  }
}

/// فئة لتمثيل نتيجة اختيار الصورة
class ImagePickerResult {
  final Uint8List bytes;
  final String name;
  final int size;
  final io.File? file; // للموبايل فقط

  ImagePickerResult({
    required this.bytes,
    required this.name,
    required this.size,
    this.file,
  });

  /// التحقق من صحة الصورة
  bool get isValid => bytes.isNotEmpty && size > 0;

  /// الحصول على حجم الصورة بالميجابايت
  double get sizeInMB => size / (1024 * 1024);

  /// التحقق من أن حجم الصورة مقبول (أقل من 5 ميجا)
  bool get isSizeAcceptable => sizeInMB <= 5.0;

  /// الحصول على امتداد الملف
  String get extension {
    final parts = name.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  /// التحقق من أن نوع الملف مدعوم
  bool get isSupportedFormat {
    const supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return supportedFormats.contains(extension);
  }
}
