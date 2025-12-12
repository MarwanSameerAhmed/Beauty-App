import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/product_section_item.dart';
import 'package:test_pro/model/product.dart';

class ProductSectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // الحصول على جميع عناصر قسم معين
  Stream<List<ProductSectionItem>> getSectionItems(String sectionId) {
    return _firestore
        .collection('product_section_items')
        .where('sectionId', isEqualTo: sectionId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductSectionItem.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // الحصول على المنتجات مع تفاصيلها لقسم معين
  Stream<List<Map<String, dynamic>>> getSectionProductsWithDetails(String sectionId) {
    return getSectionItems(sectionId).asyncMap((items) async {
      final List<Map<String, dynamic>> productsWithDetails = [];
      
      for (final item in items.where((i) => i.isVisible)) {
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(item.productId)
              .get();
          
          if (productDoc.exists) {
            final product = Product.fromMap({
              'id': productDoc.id,
              ...productDoc.data()!,
            });
            
            productsWithDetails.add({
              'item': item,
              'product': product,
            });
          }
        } catch (e) {
          print('Error fetching product ${item.productId}: $e');
        }
      }
      
      // ترتيب حسب order
      productsWithDetails.sort((a, b) => 
          (a['item'] as ProductSectionItem).order.compareTo(
              (b['item'] as ProductSectionItem).order));
      
      return productsWithDetails;
    });
  }

  // إضافة منتج إلى قسم
  Future<void> addProductToSection({
    required String sectionId,
    required String productId,
    int? order,
  }) async {
    try {
      // الحصول على آخر ترتيب في القسم
      final lastOrderQuery = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      final nextOrder = order ?? 
          (lastOrderQuery.docs.isEmpty ? 0 : 
           (lastOrderQuery.docs.first.data()['order'] ?? 0) + 1);

      // التحقق من عدم وجود المنتج في القسم مسبقاً
      final existingQuery = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        throw Exception('المنتج موجود في القسم مسبقاً');
      }

      final item = ProductSectionItem.create(
        sectionId: sectionId,
        productId: productId,
        order: nextOrder,
      );

      await _firestore
          .collection('product_section_items')
          .doc(item.id)
          .set(item.toMap());
      
      print('✅ تم إضافة المنتج إلى القسم بنجاح');
    } catch (e) {
      print('❌ خطأ في إضافة المنتج إلى القسم: $e');
      rethrow;
    }
  }

  // إزالة منتج من قسم
  Future<void> removeProductFromSection(String itemId) async {
    try {
      await _firestore
          .collection('product_section_items')
          .doc(itemId)
          .delete();
      
      print('✅ تم إزالة المنتج من القسم بنجاح');
    } catch (e) {
      print('❌ خطأ في إزالة المنتج من القسم: $e');
      rethrow;
    }
  }

  // تحديث ترتيب المنتجات في القسم
  Future<void> updateSectionItemsOrder(List<ProductSectionItem> items) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < items.length; i++) {
        final updatedItem = items[i].copyWith(order: i);
        final docRef = _firestore
            .collection('product_section_items')
            .doc(updatedItem.id);
        
        batch.update(docRef, updatedItem.toMap());
      }
      
      await batch.commit();
      print('✅ تم تحديث ترتيب المنتجات بنجاح');
    } catch (e) {
      print('❌ خطأ في تحديث ترتيب المنتجات: $e');
      rethrow;
    }
  }

  // تغيير حالة ظهور منتج في القسم
  Future<void> toggleItemVisibility(String itemId, bool isVisible) async {
    try {
      await _firestore
          .collection('product_section_items')
          .doc(itemId)
          .update({
        'isVisible': isVisible,
        'updatedAt': DateTime.now(),
      });
      
      print('✅ تم تحديث حالة ظهور المنتج');
    } catch (e) {
      print('❌ خطأ في تحديث حالة ظهور المنتج: $e');
      rethrow;
    }
  }

  // نقل منتج من قسم إلى آخر
  Future<void> moveProductToSection({
    required String itemId,
    required String newSectionId,
  }) async {
    try {
      // الحصول على آخر ترتيب في القسم الجديد
      final lastOrderQuery = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: newSectionId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      final nextOrder = lastOrderQuery.docs.isEmpty ? 0 : 
          (lastOrderQuery.docs.first.data()['order'] ?? 0) + 1;

      await _firestore
          .collection('product_section_items')
          .doc(itemId)
          .update({
        'sectionId': newSectionId,
        'order': nextOrder,
        'updatedAt': DateTime.now(),
      });
      
      print('✅ تم نقل المنتج إلى القسم الجديد');
    } catch (e) {
      print('❌ خطأ في نقل المنتج: $e');
      rethrow;
    }
  }

  // الحصول على المنتجات المتاحة للإضافة (غير موجودة في القسم)
  Stream<List<Product>> getAvailableProductsForSection(String sectionId) {
    return _firestore
        .collection('products')
        .snapshots()
        .asyncMap((productsSnapshot) async {
      // الحصول على المنتجات الموجودة في القسم
      final sectionItemsSnapshot = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .get();
      
      final existingProductIds = sectionItemsSnapshot.docs
          .map((doc) => doc.data()['productId'] as String)
          .toSet();
      
      // فلترة المنتجات المتاحة
      final availableProducts = productsSnapshot.docs
          .where((doc) => !existingProductIds.contains(doc.id))
          .map((doc) => Product.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      return availableProducts;
    });
  }

  // حذف جميع عناصر قسم معين
  Future<void> clearSection(String sectionId) async {
    try {
      final itemsQuery = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in itemsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ تم مسح جميع منتجات القسم');
    } catch (e) {
      print('❌ خطأ في مسح منتجات القسم: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات القسم
  Future<Map<String, int>> getSectionStats(String sectionId) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .get();
      
      final totalItems = itemsSnapshot.docs.length;
      final visibleItems = itemsSnapshot.docs
          .where((doc) => doc.data()['isVisible'] == true)
          .length;
      
      return {
        'total': totalItems,
        'visible': visibleItems,
        'hidden': totalItems - visibleItems,
      };
    } catch (e) {
      print('❌ خطأ في الحصول على إحصائيات القسم: $e');
      return {'total': 0, 'visible': 0, 'hidden': 0};
    }
  }
}
