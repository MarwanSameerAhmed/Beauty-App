import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/model/product.dart';
import 'image_upload_service.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // فولدر مخصص للصور
  static const String _imageFolder = "/products";

  // إضافة منتج جديد
  Future<void> addProduct(Product product) async {
    try {
      final docRef = _productsCollection.doc();
      product.id = docRef.id;
      await docRef.set(product.toMap());
    } catch (e) {
      // Error adding product: $e
      rethrow;
    }
  }

  // رفع صور إلى ImageKit باستخدام الخدمة المركزية الآمنة
  Future<List<String>> uploadImages(List<Uint8List> imageBytesList) async {
    try {
      return await ImageUploadService.instance.uploadMultipleImages(
        imageBytesList, 
        _imageFolder,
      );
    } catch (e) {
      // Error uploading product images: $e
      throw Exception('فشل رفع صور المنتج: ${e.toString()}');
    }
  }

  // جلب المنتجات
  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // جلب جميع المنتجات كـ Future للاستخدام في الفواتير
  Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection.get();
      return querySnapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // Error fetching all products: $e
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final docSnapshot = await _productsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return Product.fromMap(docSnapshot.data()! as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      // Error fetching product by ID: $e
      return null;
    }
  }

  Stream<List<Product>> getProductsByCategories(List<String> categoryIds) {
    if (categoryIds.isEmpty) {
      return Stream.value([]);
    }
    return _productsCollection
        .where('categoryId', whereIn: categoryIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Product>> getProductsByCategory(String categoryId) {
    return _productsCollection
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<Product>> getProductsByCompanyId(String companyId) {
    return _productsCollection
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // تحديث منتج
  Future<void> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toMap());
    } catch (e) {
      // Error updating product: $e
      rethrow;
    }
  }

  // حذف منتج
  Future<void> deleteProduct(String productId) async {
    try {
      // Image deletion from ImageKit not implemented yet
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      // Error deleting product: $e
      rethrow;
    }
  }

  // البحث في المنتجات
  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    
    // تحويل النص إلى أحرف صغيرة للبحث
    String searchQuery = query.toLowerCase().trim();
    
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .where((product) {
            // البحث في اسم المنتج والوصف
            return product.name.toLowerCase().contains(searchQuery) ||
                   product.description.toLowerCase().contains(searchQuery);
          })
          .toList();
    });
  }

  // البحث المتقدم في المنتجات مع فلترة حسب الفئة
  Stream<List<Product>> searchProductsWithCategory(String query, String? categoryId) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    
    String searchQuery = query.toLowerCase().trim();
    
    Query queryRef = _productsCollection;
    if (categoryId != null && categoryId.isNotEmpty) {
      queryRef = queryRef.where('categoryId', isEqualTo: categoryId);
    }
    
    return queryRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .where((product) {
            return product.name.toLowerCase().contains(searchQuery) ||
                   product.description.toLowerCase().contains(searchQuery);
          })
          .toList();
    });
  }

  // الحصول على اقتراحات البحث
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }
    
    String searchQuery = query.toLowerCase().trim();
    
    try {
      final snapshot = await _productsCollection.get();
      final suggestions = <String>{};
      
      for (var doc in snapshot.docs) {
        final product = Product.fromMap(doc.data() as Map<String, dynamic>);
        
        // إضافة أسماء المنتجات التي تحتوي على النص المدخل
        if (product.name.toLowerCase().contains(searchQuery)) {
          suggestions.add(product.name);
        }
        
        // إضافة كلمات من الوصف
        final descriptionWords = product.description.toLowerCase().split(' ');
        for (String word in descriptionWords) {
          if (word.contains(searchQuery) && word.length > 2) {
            suggestions.add(word);
          }
        }
      }
      
      // ترتيب الاقتراحات وإرجاع أفضل 5
      final sortedSuggestions = suggestions.toList()
        ..sort((a, b) => a.length.compareTo(b.length));
      
      return sortedSuggestions.take(5).toList();
    } catch (e) {
      // Error getting search suggestions: $e
      return [];
    }
  }
}
