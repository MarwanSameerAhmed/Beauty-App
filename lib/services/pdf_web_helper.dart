import 'dart:typed_data';

/// على الويب: حفظ PDF يرجع Uint8List مباشرة (لا يوجد ملفات)
Future<dynamic> savePdfToFile(Uint8List pdfBytes, String fileName) async {
  return pdfBytes;
}

/// على الويب: المشاركة غير مدعومة بنفس الشكل
Future<void> platformSharePdf(dynamic pdfFile, {String? orderNumber, double? totalPrice}) async {
  // على الويب يتم التحميل مباشرة عبر downloadPdfWeb
}

/// على الويب: قراءة bytes - إذا كان Uint8List يرجعه مباشرة
Future<Uint8List?> platformReadFileBytes(dynamic pdfFile) async {
  if (pdfFile is Uint8List) {
    return pdfFile;
  }
  return null;
}
