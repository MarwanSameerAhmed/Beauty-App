import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanySettingsService {
  final CollectionReference _settingsCollection = 
      FirebaseFirestore.instance.collection('company_settings');

  static const String _settingsDocId = 'main_settings';

  // جلب إعدادات الشركة
  Future<Map<String, dynamic>?> getCompanySettings() async {
    try {
      // جرب جلب البيانات من admin_data أولاً
      final adminCollection = FirebaseFirestore.instance.collection('admin_data');
      final adminDoc = await adminCollection.doc(_settingsDocId).get();
      
      if (adminDoc.exists) {
        return adminDoc.data() as Map<String, dynamic>;
      }
      
      // إذا لم توجد، جرب المكان القديم
      final doc = await _settingsCollection.doc(_settingsDocId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error getting company settings: $e');
      return null;
    }
  }

  // تحديث إعدادات الشركة
  Future<void> updateCompanySettings({
    String? phoneNumber,
    String? whatsappNumber,
  }) async {
    try {
      // استخدام collection مختلف للأدمن
      final adminCollection = FirebaseFirestore.instance.collection('admin_data');
      
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.email,
      };
      
      if (phoneNumber != null) {
        updateData['companyPhone'] = phoneNumber;
      }
      
      if (whatsappNumber != null) {
        updateData['whatsappNumber'] = whatsappNumber;
      }
      
      await adminCollection.doc(_settingsDocId).set(
        updateData,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating company settings: $e');
      rethrow;
    }
  }

  // تحديث رقم هاتف الشركة (للتوافق مع الكود القديم)
  Future<void> updateCompanyPhone(String phoneNumber) async {
    await updateCompanySettings(phoneNumber: phoneNumber);
  }

  // جلب رقم هاتف الشركة
  Future<String> getCompanyPhone() async {
    try {
      final settings = await getCompanySettings();
      return settings?['companyPhone'] ?? '0554055582'; // القيمة الافتراضية
    } catch (e) {
      print('Error getting company phone: $e');
      return '0554055582'; // القيمة الافتراضية في حالة الخطأ
    }
  }

  // جلب رقم الواتس للفواتير
  Future<String> getWhatsappNumber() async {
    try {
      final settings = await getCompanySettings();
      return settings?['whatsappNumber'] ?? '966554055582'; // القيمة الافتراضية
    } catch (e) {
      print('Error getting whatsapp number: $e');
      return '966554055582'; // القيمة الافتراضية في حالة الخطأ
    }
  }

  // مراقبة تغييرات إعدادات الشركة
  Stream<Map<String, dynamic>?> watchCompanySettings() {
    return _settingsCollection.doc(_settingsDocId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }
}
