import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test_pro/model/product.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // معلومات ImageKit
  final String imageKitEndpoint =
      "https://upload.imagekit.io/api/v1/files/upload";
  final String imageKitPublicKey =
      "public_DGaQn58MnRn4ACgF1gggQOeRynU="; // ضع مفتاحك هنا
  final String imageKitPrivateKey =
      "private_VDQdsQtRYRJ17dC1c0UVukm/WxU="; // فقط للسيرفر إذا احتجت
  final String imageKitFolder = "/products"; // فولدر مخصص للصور

  // إضافة منتج جديد
  Future<void> addProduct(Product product) async {
    try {
      final docRef = _productsCollection.doc();
      product.id = docRef.id;
      await docRef.set(product.toMap());
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // رفع صور إلى ImageKit
  Future<List<String>> uploadImages(List<Uint8List> imageBytesList) async {
    List<String> imageUrls = [];

    for (var imageBytes in imageBytesList) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      int expiry =
          (DateTime.now().millisecondsSinceEpoch / 1000).round() +
          60 * 5; // 5 دقائق
      String token = DateTime.now().millisecondsSinceEpoch
          .toString(); // يمكن استخدام UUID هنا

      // إنشاء التوقيع
      var key = utf8.encode(imageKitPrivateKey);
      var bytes = utf8.encode(token + expiry.toString());
      var hmacSha1 = Hmac(sha1, key);
      var digest = hmacSha1.convert(bytes);
      String signature = digest.toString();

      var request = http.MultipartRequest('POST', Uri.parse(imageKitEndpoint));

      // إضافة الحقول المطلوبة للمصادقة
      request.fields['publicKey'] = imageKitPublicKey;
      request.fields['signature'] = signature;
      request.fields['expire'] = expiry.toString();
      request.fields['token'] = token;
      request.fields['fileName'] = fileName;
      request.fields['folder'] = imageKitFolder;
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: '$fileName.jpg'));

      var response = await request.send();
      var respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(respStr);
        imageUrls.add(data['url']); // URL النهائي من ImageKit
      } else {
        // طباعة الاستجابة من السيرفر لتسهيل تصحيح الأخطاء
        print('فشل رفع الصورة. الاستجابة: $respStr');
        throw Exception("فشل رفع الصورة: ${response.statusCode}");
      }
    }

    return imageUrls;
  }

  // جلب المنتجات
  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
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
      print('Error fetching product by ID: $e');
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
      print('Error updating product: $e');
      rethrow;
    }
  }

  // حذف منتج
  Future<void> deleteProduct(String productId) async {
    try {
      // TODO: Implement image deletion from ImageKit if possible
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
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
      print('Error getting search suggestions: $e');
      return [];
    }
  }
}
