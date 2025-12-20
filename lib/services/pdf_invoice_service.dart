import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../controller/company_settings_service.dart';

class PdfInvoiceService {
  // Helper function to ensure Arabic text is properly handled
  static String _processArabicText(String text) {
    return text.replaceAll(RegExp(r'[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u0020-\u007F]'), '');
  }

  static Future<dynamic> generateInvoice({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String customerName,
    required String customerEmail,
    String? orderNumber,
  }) async {
    final pdf = pw.Document();
    
    // Load company settings from Firestore
    final companySettings = CompanySettingsService();
    final companyName = await companySettings.getCompanyName();
    final companyPhone = await companySettings.getCompanyPhone();
    final taxNumber = await companySettings.getTaxNumber();
    final commercialRegister = await companySettings.getCommercialRegister();
    final supportPhone = await companySettings.getSupportPhone();
    final supportEmail = await companySettings.getSupportEmail();
    
    // Load Arabic font
    late pw.Font arabicFont;
    late pw.Font arabicBoldFont;
    
    // Load logo image - استخدام صورة Android 512x512
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('images/android/play_store_512.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      AppLogger.info('Successfully loaded logo image', tag: 'PDF');
    } catch (e) {
      AppLogger.warning('Failed to load logo image', tag: 'PDF', error: e);
    }
    
    try {
      final fontData = await rootBundle.load('fonts/Tajawal-Regular.ttf');
      arabicFont = pw.Font.ttf(fontData);
      arabicBoldFont = pw.Font.ttf(fontData);
      AppLogger.info('Successfully loaded Tajawal font', tag: 'PDF');
    } catch (e) {
      AppLogger.warning('Failed to load local fonts', tag: 'PDF', error: e);
      try {
        arabicFont = await PdfGoogleFonts.amiriRegular();
        arabicBoldFont = await PdfGoogleFonts.amiriBold();
      } catch (e2) {
        arabicFont = await PdfGoogleFonts.robotoRegular();
        arabicBoldFont = await PdfGoogleFonts.robotoBold();
      }
    }
    
    orderNumber ??= 'INV-${DateTime.now().millisecondsSinceEpoch}';
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        build: (pw.Context context) {
          return [
            _buildHeader(arabicBoldFont, arabicFont, logoImage,
              companyName: companyName,
              companyPhone: companyPhone,
              taxNumber: taxNumber,
              commercialRegister: commercialRegister,
            ),
            pw.SizedBox(height: 30),
            _buildInvoiceDetails(orderNumber!, customerName, customerEmail, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 30),
            _buildItemsTable(items, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 30),
            _buildTotalSection(totalPrice, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 50),
            _buildFooter(arabicFont, supportPhone: supportPhone, supportEmail: supportEmail),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      return pdfBytes;
    } else {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_$orderNumber.pdf');
      await file.writeAsBytes(pdfBytes);
      return file;
    }
  }

  static pw.Widget _buildHeader(
    pw.Font boldFont, 
    pw.Font regularFont, 
    pw.MemoryImage? logoImage, {
    required String companyName,
    required String companyPhone,
    required String taxNumber,
    required String commercialRegister,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#52002C'),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _processArabicText(companyName),
                style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.white),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                _processArabicText('سجل تجاري: $commercialRegister'),
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.white),
              ),
              pw.Text(
                _processArabicText('الرقم الضريبي: $taxNumber'),
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.white),
              ),
              pw.Text(
                _processArabicText('جوال: $companyPhone'),
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
          pw.Container(
            width: 70,
            height: 70,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: logoImage != null 
              ? pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                )
              : pw.Center(
                  child: pw.Text('LOGO', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColor.fromHex('#52002C'))),
                ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetails(
    String orderNumber,
    String customerName,
    String customerEmail,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_processArabicText('تفاصيل الفاتورة'), style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(_processArabicText('رقم الفاتورة: $orderNumber'), style: pw.TextStyle(font: regularFont)),
              pw.Text(_processArabicText('التاريخ: $formattedDate'), style: pw.TextStyle(font: regularFont)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_processArabicText('بيانات العميل'), style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(_processArabicText('الاسم: $customerName'), style: pw.TextStyle(font: regularFont)),
              pw.Text(_processArabicText('البريد: $customerEmail'), style: pw.TextStyle(font: regularFont)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<Map<String, dynamic>> items, pw.Font regularFont, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
          children: [
            _buildTableCell(_processArabicText('المجموع'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('الكمية'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('السعر'), boldFont, isHeader: true),
            _buildTableCell(_processArabicText('المنتج'), boldFont, isHeader: true),
          ],
        ),
        ...items.where((item) => item['userAction'] != 'rejected').map((item) {
          final price = (item['price'] ?? 0.0).toDouble();
          final quantity = (item['quantity'] ?? 1).toInt();
          final total = price * quantity;
          
          return pw.TableRow(
            children: [
              _buildTableCell('${total.toStringAsFixed(2)} ر.س', regularFont),
              _buildTableCell(quantity.toString(), regularFont),
              _buildTableCell('${price.toStringAsFixed(2)} ر.س', regularFont),
              _buildTableCell(_processArabicText(item['name'] ?? ''), regularFont),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 12 : 10, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _buildTotalSection(double totalPrice, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F9FA'),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_processArabicText('الإجمالي النهائي:'), style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.Text('${totalPrice.toStringAsFixed(2)} ر.س', 
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColor.fromHex('#52002C'))),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font regularFont, {required String supportPhone, required String supportEmail}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F9FA'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(_processArabicText('شكراً لك على تعاملك معنا'), style: pw.TextStyle(font: regularFont, fontSize: 14), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 10),
          pw.Text(_processArabicText('للاستفسارات: $supportPhone'), style: pw.TextStyle(font: regularFont, fontSize: 11), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 5),
          pw.Text(_processArabicText('البريد الإلكتروني: $supportEmail'), style: pw.TextStyle(font: regularFont, fontSize: 11), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static void downloadPdfWeb(Uint8List pdfBytes, String fileName) {
    if (!kIsWeb) return;
    try {
      Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      AppLogger.error('خطأ في تحميل PDF', tag: 'PDF', error: e);
    }
  }

  static Future<void> shareInvoice(dynamic pdfFile, {String? orderNumber, double? totalPrice}) async {
    if (kIsWeb) {
      if (pdfFile is Uint8List) {
        downloadPdfWeb(pdfFile, 'invoice_${orderNumber ?? DateTime.now().millisecondsSinceEpoch}.pdf');
      }
    } else {
      final String message = '''🧾 *فاتورة طلب*

📋 رقم الطلب: ${orderNumber ?? 'غير محدد'}
💰 المبلغ الإجمالي: ${totalPrice?.toStringAsFixed(2) ?? '0.00'} ر.س

📄 فاتورة مفصلة مرفقة.

شكراً لكم 🙏''';

      if (pdfFile is File) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: message,
          subject: 'فاتورة طلب رقم: ${orderNumber ?? 'غير محدد'}',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
    }
  }

  static Future<void> printInvoice(dynamic pdfFile) async {
    if (kIsWeb) {
      if (pdfFile is Uint8List) {
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfFile);
      }
    } else {
      if (pdfFile is File) {
        final bytes = await pdfFile.readAsBytes();
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
      }
    }
  }
}
