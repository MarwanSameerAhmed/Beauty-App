/// خدمة توليد الباركود الأوتوماتيكي للمنتجات
/// يستخدم صيغة EAN-13 (الأكثر شيوعاً تجارياً)
class BarcodeService {
  /// بادئة خاصة بالتطبيق (يمكن تخصيصها حسب الشركة)
  static const String _prefix = '628';

  /// عداد لضمان التفرد في حالة توليد أكثر من باركود بنفس الميلي ثانية
  static int _counter = 0;

  /// توليد باركود EAN-13 فريد
  static String generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    // أخذ آخر 9 أرقام من الـ timestamp + العداد
    _counter = (_counter + 1) % 10;
    final raw = _prefix + timestamp.substring(timestamp.length - 9) + _counter.toString();

    // حساب check digit لـ EAN-13 (أول 12 رقم)
    final digits12 = raw.substring(0, 12);
    final checkDigit = _calculateEAN13CheckDigit(digits12);

    return digits12 + checkDigit;
  }

  /// حساب check digit لـ EAN-13
  /// القاعدة: مجموع (الأرقام الفردية × 1) + (الأرقام الزوجية × 3)
  /// ثم (10 - المجموع % 10) % 10
  static String _calculateEAN13CheckDigit(String digits) {
    if (digits.length != 12) {
      throw ArgumentError('EAN-13 requires exactly 12 digits for check digit calculation');
    }

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(digits[i]);
      if (i % 2 == 0) {
        sum += digit * 1; // الموقع الفردي (0-indexed)
      } else {
        sum += digit * 3; // الموقع الزوجي
      }
    }

    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit.toString();
  }

  /// التحقق من صحة باركود EAN-13
  static bool isValidEAN13(String barcode) {
    if (barcode.length != 13) return false;
    if (!RegExp(r'^\d{13}$').hasMatch(barcode)) return false;

    final digits12 = barcode.substring(0, 12);
    final expectedCheckDigit = _calculateEAN13CheckDigit(digits12);
    return barcode[12] == expectedCheckDigit;
  }
}
