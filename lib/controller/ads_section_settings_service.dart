import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/ads_section_settings.dart';
import 'package:test_pro/model/ad.dart';
import 'package:test_pro/model/product_section_item.dart';
import 'package:test_pro/model/product.dart';

class AdsSectionSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ads_section_settings';

  // جلب إعدادات الأقسام
  Stream<List<AdsSectionSettings>> getSectionSettings() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // إذا لم توجد إعدادات، إنشاء الإعدادات الافتراضية
        _createDefaultSettings();
        return AdsSectionSettings.getDefaultSettings();
      }
      
      return snapshot.docs
          .map((doc) => AdsSectionSettings.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // إنشاء الإعدادات الافتراضية
  Future<void> _createDefaultSettings() async {
    final defaultSettings = AdsSectionSettings.getDefaultSettings();
    final batch = _firestore.batch();

    for (var setting in defaultSettings) {
      final docRef = _firestore.collection(_collection).doc(setting.id);
      batch.set(docRef, setting.toMap());
    }

    await batch.commit();
  }

  // تحديث إعدادات قسم
  Future<void> updateSectionSettings(AdsSectionSettings settings) async {
    await _firestore
        .collection(_collection)
        .doc(settings.id)
        .update(settings.toMap());
  }

  // تحديث عنوان قسم
  Future<void> updateSectionTitle(String sectionId, String newTitle) async {
    await _firestore
        .collection(_collection)
        .doc(sectionId)
        .update({'title': newTitle});
  }

  // تحديث ترتيب الأقسام
  Future<void> updateSectionsOrder(List<AdsSectionSettings> sections) async {
    final batch = _firestore.batch();

    for (int i = 0; i < sections.length; i++) {
      final docRef = _firestore.collection(_collection).doc(sections[i].id);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }

  // تحديث موضع قسم
  Future<void> updateSectionPosition(String sectionId, String newPosition) async {
    await _firestore
        .collection(_collection)
        .doc(sectionId)
        .update({'position': newPosition});
  }

  // تحديث رؤية قسم
  Future<void> updateSectionVisibility(String sectionId, bool isVisible) async {
    await _firestore
        .collection(_collection)
        .doc(sectionId)
        .update({'isVisible': isVisible});
  }

  // إعادة تعيين الإعدادات للقيم الافتراضية
  Future<void> resetToDefaults() async {
    try {
      // حذف جميع الأقسام الموجودة
      final snapshot = await _firestore.collection('ads_section_settings').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      // إضافة الأقسام الافتراضية
      final defaultSettings = AdsSectionSettings.getDefaultSettings();
      for (var setting in defaultSettings) {
        await _firestore
            .collection('ads_section_settings')
            .doc(setting.id)
            .set(setting.toMap());
      }
    } catch (e) {
      print('Error resetting to defaults: $e');
      rethrow;
    }
  }

  // دالة لإنشاء الأقسام الافتراضية إذا لم تكن موجودة
  Future<void> initializeDefaultSections() async {
    try {
      final snapshot = await _firestore.collection('ads_section_settings').get();
      
      // إذا لم توجد أقسام، أنشئ الأقسام الافتراضية
      if (snapshot.docs.isEmpty) {
        final defaultSettings = AdsSectionSettings.getDefaultSettings();
        for (var setting in defaultSettings) {
          await _firestore
              .collection('ads_section_settings')
              .doc(setting.id)
              .set(setting.toMap());
        }
        print('✅ تم إنشاء الأقسام الافتراضية');
      }
    } catch (e) {
      print('Error initializing default sections: $e');
      rethrow;
    }
  }

  // جلب إعدادات قسم معين
  Future<AdsSectionSettings?> getSectionSetting(String sectionId) async {
    final doc = await _firestore.collection(_collection).doc(sectionId).get();
    
    if (doc.exists) {
      return AdsSectionSettings.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
    }
    
    return null;
  }

  // إضافة قسم جديد
  Future<void> addNewSection(AdsSectionSettings section) async {
    await _firestore
        .collection(_collection)
        .doc(section.id)
        .set(section.toMap());
  }

  // حذف قسم
  Future<void> deleteSection(String sectionId) async {
    await _firestore
        .collection(_collection)
        .doc(sectionId)
        .delete();
  }

  // جلب جميع الأقسام مع الإعلانات
  Stream<Map<String, dynamic>> getSectionsWithAds() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .asyncMap((sectionsSnapshot) async {
      
      final sections = sectionsSnapshot.docs
          .map((doc) => AdsSectionSettings.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      // جلب الإعلانات لكل قسم
      final adsSnapshot = await _firestore.collection('ads').get();
      final allAds = adsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      return {
        'sections': sections,
        'ads': allAds,
      };
    });
  }

  // جلب أقسام الإعلانات فقط
  Stream<List<AdsSectionSettings>> getAdsSections() {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'ads')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdsSectionSettings.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  // جلب أقسام المنتجات فقط
  Stream<List<AdsSectionSettings>> getProductsSections() {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'products')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdsSectionSettings.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  // إضافة قسم منتجات جديد
  Future<void> addProductSection({
    required String title,
    required String position,
    int maxItems = 6,
    String? description,
  }) async {
    try {
      // الحصول على آخر ترتيب
      final lastOrderQuery = await _firestore
          .collection(_collection)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      final nextOrder = lastOrderQuery.docs.isEmpty ? 0 : 
          (lastOrderQuery.docs.first.data()['order'] ?? 0) + 1;

      final section = AdsSectionSettings.createProductSection(
        title: title,
        position: position,
        order: nextOrder,
        maxItems: maxItems,
        description: description,
      );

      await addNewSection(section);
      print('✅ تم إضافة قسم المنتجات بنجاح');
    } catch (e) {
      print('❌ خطأ في إضافة قسم المنتجات: $e');
      rethrow;
    }
  }

  // الحصول على جميع الأقسام مع محتواها (إعلانات ومنتجات)
  Stream<List<Map<String, dynamic>>> getAllSectionsWithContent() {
    return getSectionSettings().asyncMap((sections) async {
      final List<Map<String, dynamic>> sectionsWithContent = [];
      
      for (final section in sections.where((s) => s.isVisible)) {
        Map<String, dynamic> sectionData = {
          'section': section,
          'content': <dynamic>[],
        };

        if (section.isAdsSection) {
          // جلب الإعلانات
          final adsSnapshot = await _firestore
              .collection('ads')
              .where('sectionId', isEqualTo: section.id)
              .where('isVisible', isEqualTo: true)
              .orderBy('order')
              .get();
          
          sectionData['content'] = adsSnapshot.docs
              .map((doc) => {
                    'type': 'ad',
                    'data': {'id': doc.id, ...doc.data()},
                  })
              .toList();
        } else if (section.isProductsSection) {
          // جلب المنتجات
          final productItemsSnapshot = await _firestore
              .collection('product_section_items')
              .where('sectionId', isEqualTo: section.id)
              .where('isVisible', isEqualTo: true)
              .orderBy('order')
              .limit(section.maxItems)
              .get();
          
          final List<Map<String, dynamic>> products = [];
          for (final itemDoc in productItemsSnapshot.docs) {
            final productId = itemDoc.data()['productId'];
            final productDoc = await _firestore
                .collection('products')
                .doc(productId)
                .get();
            
            if (productDoc.exists) {
              products.add({
                'type': 'product',
                'data': {'id': productDoc.id, ...productDoc.data()!},
                'item': {'id': itemDoc.id, ...itemDoc.data()},
              });
            }
          }
          sectionData['content'] = products;
        }

        sectionsWithContent.add(sectionData);
      }
      
      return sectionsWithContent;
    });
  }

  // تحديث ترتيب جميع الأقسام (محسن)
  Future<void> reorderAllSections(List<AdsSectionSettings> sections) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < sections.length; i++) {
        final updatedSection = sections[i].copyWith(order: i);
        final docRef = _firestore.collection(_collection).doc(updatedSection.id);
        batch.update(docRef, updatedSection.toMap());
      }
      
      await batch.commit();
      print('✅ تم تحديث ترتيب الأقسام بنجاح');
    } catch (e) {
      print('❌ خطأ في تحديث ترتيب الأقسام: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات الأقسام
  Future<Map<String, dynamic>> getSectionsStats() async {
    try {
      final sectionsSnapshot = await _firestore.collection(_collection).get();
      final sections = sectionsSnapshot.docs
          .map((doc) => AdsSectionSettings.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      final adsSections = sections.where((s) => s.isAdsSection).length;
      final productsSections = sections.where((s) => s.isProductsSection).length;
      final visibleSections = sections.where((s) => s.isVisible).length;

      return {
        'total': sections.length,
        'ads': adsSections,
        'products': productsSections,
        'visible': visibleSections,
        'hidden': sections.length - visibleSections,
      };
    } catch (e) {
      print('❌ خطأ في الحصول على إحصائيات الأقسام: $e');
      return {
        'total': 0,
        'ads': 0,
        'products': 0,
        'visible': 0,
        'hidden': 0,
      };
    }
  }
}
