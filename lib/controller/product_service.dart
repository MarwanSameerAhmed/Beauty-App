import 'dart:io';
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
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    List<String> imageUrls = [];

    for (var file in imageFiles) {
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
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

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
}
