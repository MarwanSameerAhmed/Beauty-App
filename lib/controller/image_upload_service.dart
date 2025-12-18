import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ImageKitConfig {
  final String endpoint;
  final String publicKey;
  final String privateKey;

  ImageKitConfig({
    required this.endpoint,
    required this.publicKey,
    required this.privateKey,
  });
}

class ImageUploadService {
  static ImageUploadService? _instance;
  static ImageUploadService get instance => _instance ??= ImageUploadService._();
  ImageUploadService._();

  Future<String> uploadImage(Uint8List imageBytes, String folder) async {
    return await _uploadImageWithConfig(imageBytes, folder, _getConfigForFolder(folder));
  }

  Future<String> uploadProductImage(Uint8List imageBytes, String folder) async {
    return await _uploadImageWithConfig(imageBytes, folder, _getProductsConfig());
  }

  Future<String> uploadAdImage(Uint8List imageBytes, String folder) async {
    return await _uploadImageWithConfig(imageBytes, folder, _getAdsConfig());
  }

  ImageKitConfig _getConfigForFolder(String folder) {
    // تحديد نوع الصورة بناءً على المجلد
    if (folder.contains('products')) {
      return _getProductsConfig();
    } else if (folder.contains('ads') || folder.contains('carousel')) {
      return _getAdsConfig();
    } else {
      // افتراضي للمنتجات
      return _getProductsConfig();
    }
  }

  ImageKitConfig _getProductsConfig() {
    final config = AppConfig.instance;
    return ImageKitConfig(
      endpoint: config.productsImageKitEndpoint,
      publicKey: config.productsImageKitPublicKey,
      privateKey: config.productsImageKitPrivateKey,
    );
  }

  ImageKitConfig _getAdsConfig() {
    final config = AppConfig.instance;
    return ImageKitConfig(
      endpoint: config.adsImageKitEndpoint,
      publicKey: config.adsImageKitPublicKey,
      privateKey: config.adsImageKitPrivateKey,
    );
  }

  Future<String> _uploadImageWithConfig(Uint8List imageBytes, String folder, ImageKitConfig imageKitConfig) async {
    try {
      // Ensure config is initialized
      await AppConfig.instance.initialize();
      
      // Validate that we have the required keys
      if (imageKitConfig.publicKey.isEmpty || imageKitConfig.privateKey.isEmpty) {
        throw Exception('ImageKit credentials not configured for this service. Please check Firebase Remote Config.');
      }

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      int expiry = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 60 * 5; // 5 minutes
      String token = DateTime.now().millisecondsSinceEpoch.toString();

      // Create signature
      var key = utf8.encode(imageKitConfig.privateKey);
      var bytes = utf8.encode(token + expiry.toString());
      var hmacSha1 = Hmac(sha1, key);
      var digest = hmacSha1.convert(bytes);
      String signature = digest.toString();

      var request = http.MultipartRequest('POST', Uri.parse(imageKitConfig.endpoint));

      // Add authentication fields
      request.fields['publicKey'] = imageKitConfig.publicKey;
      request.fields['signature'] = signature;
      request.fields['expire'] = expiry.toString();
      request.fields['token'] = token;
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: '$fileName.jpg'),
      );

      var response = await request.send();
      var respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(respStr);
        return data['url'];
      } else {
        // Failed to upload image. Status: ${response.statusCode}
        throw Exception("فشل رفع الصورة: ${response.statusCode}");
      }
    } catch (e) {
      // Error in uploadImage: $e
      rethrow;
    }
  }

  Future<List<String>> uploadMultipleImages(List<Uint8List> imageBytesList, String folder) async {
    List<String> imageUrls = [];
    
    for (var imageBytes in imageBytesList) {
      try {
        String url = await uploadImage(imageBytes, folder);
        imageUrls.add(url);
      } catch (e) {
        // Error uploading image: $e
        rethrow; // Stop on first error to maintain data consistency
      }
    }
    
    return imageUrls;
  }

  Future<List<String>> uploadMultipleProductImages(List<Uint8List> imageBytesList, String folder) async {
    List<String> imageUrls = [];
    
    for (var imageBytes in imageBytesList) {
      try {
        String url = await uploadProductImage(imageBytes, folder);
        imageUrls.add(url);
      } catch (e) {
        // Error uploading product image: $e
        rethrow; // Stop on first error to maintain data consistency
      }
    }
    
    return imageUrls;
  }

  Future<List<String>> uploadMultipleAdImages(List<Uint8List> imageBytesList, String folder) async {
    List<String> imageUrls = [];
    
    for (var imageBytes in imageBytesList) {
      try {
        String url = await uploadAdImage(imageBytes, folder);
        imageUrls.add(url);
      } catch (e) {
        // Error uploading ad image: $e
        rethrow; // Stop on first error to maintain data consistency
      }
    }
    
    return imageUrls;
  }
}
