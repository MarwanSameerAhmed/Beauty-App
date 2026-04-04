import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

/// حفظ PDF كملف على الموبايل
Future<dynamic> savePdfToFile(Uint8List pdfBytes, String fileName) async {
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(pdfBytes);
  return file;
}

/// مشاركة PDF على الموبايل
Future<void> platformSharePdf(dynamic pdfFile, {String? orderNumber, double? totalPrice}) async {
  if (pdfFile is File) {
    final String message = '''🧾 *فاتورة طلب*

📋 رقم الطلب: ${orderNumber ?? 'غير محدد'}
💰 المبلغ الإجمالي: ${totalPrice?.toStringAsFixed(2) ?? '0.00'} ر.س

📄 فاتورة مفصلة مرفقة.

شكراً لكم 🙏''';

    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: message,
      subject: 'فاتورة طلب رقم: ${orderNumber ?? 'غير محدد'}',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }
}

/// قراءة bytes من ملف PDF على الموبايل
Future<Uint8List?> platformReadFileBytes(dynamic pdfFile) async {
  if (pdfFile is File) {
    return await pdfFile.readAsBytes();
  }
  return null;
}
