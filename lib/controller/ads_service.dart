import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test_pro/model/ad.dart';

class AdsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'ads';

  // ImageKit Credentials
  final String imageKitEndpoint =
      "https://upload.imagekit.io/api/v1/files/upload";
  final String imageKitPublicKey = "public_nqx61eKROJvfStHVbj2NgMqrHEw=";
  final String imageKitPrivateKey = "private_XF+0X9Xj25cfAeREpralrnMdMuQ=";
  final String imageKitFolder = "/ads";

  Future<String> uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    int expiry =
        (DateTime.now().millisecondsSinceEpoch / 1000).round() +
        60 * 5; // 5 minutes
    String token = DateTime.now().millisecondsSinceEpoch.toString();

    // Create signature
    var key = utf8.encode(imageKitPrivateKey);
    var bytes = utf8.encode(token + expiry.toString());
    var hmacSha1 = Hmac(sha1, key);
    var digest = hmacSha1.convert(bytes);
    String signature = digest.toString();

    var request = http.MultipartRequest('POST', Uri.parse(imageKitEndpoint));

    request.fields['publicKey'] = imageKitPublicKey;
    request.fields['signature'] = signature;
    request.fields['expire'] = expiry.toString();
    request.fields['token'] = token;
    request.fields['fileName'] = fileName;
    request.fields['folder'] = imageKitFolder;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var data = jsonDecode(respStr);
      return data['url']; // Final URL from ImageKit
    } else {
      print('Failed to upload image. Response: $respStr');
      throw Exception("Failed to upload image: ${response.statusCode}");
    }
  }

  Future<void> addAd(Ad ad) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      ad.id = docRef.id;
      await docRef.set(ad.toMap());
    } catch (e) {
      print(e); // for debugging
      throw Exception('Failed to add ad');
    }
  }

  Stream<List<Ad>> getAds() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Ad.fromMap(doc.data())).toList();
    });
  }
}
