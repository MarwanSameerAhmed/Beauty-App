import 'dart:typed_data';

/// على الويب: ضغط من مسار ملف غير مدعوم
Future<Uint8List?> platformCompressFile(String filePath) async {
  // غير مدعوم على الويب
  return null;
}

/// على الويب: ضغط من Uint8List - نرجع البيانات كما هي
/// (الضغط الفعلي يتم عبر WebImageService)
Future<Uint8List?> platformCompressList(Uint8List imageBytes) async {
  return imageBytes;
}
