import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/ad.dart';
import 'image_upload_service.dart';
import '../utils/logger.dart';

class AdsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'ads';

  static const String _imageFolder = "/ads";

  Future<String> uploadImage(Uint8List imageBytes) async {
    try {
      return await ImageUploadService.instance.uploadImage(
        imageBytes, 
        _imageFolder,
      );
    } catch (e) {
      AppLogger.error('Error uploading ad image', tag: 'ADS', error: e);
      throw Exception('فشل رفع صورة الإعلان: ${e.toString()}');
    }
  }

  Future<void> addAd(Ad ad) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      ad.id = docRef.id;
      await docRef.set(ad.toMap());
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding ad', tag: 'ADS', error: e, data: {'code': e.code});
      throw Exception('فشل إضافة الإعلان: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error adding ad', tag: 'ADS', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء إضافة الإعلان');
    }
  }

  Stream<List<Ad>> getAds() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          try {
            return Ad.fromMap(doc.data(), doc.id);
          } catch (e) {
            AppLogger.warning('Error parsing ad document', tag: 'ADS', data: {'docId': doc.id}, error: e);
            return null;
          }
        }).where((ad) => ad != null).cast<Ad>().toList();
      } catch (e) {
        AppLogger.error('Error processing ads snapshot', tag: 'ADS', error: e);
        return <Ad>[];
      }
    }).handleError((error) {
      AppLogger.error('Error in ads stream', tag: 'ADS', error: error);
      return <Ad>[];
    });
  }

  Future<void> updateAd(Ad ad) async {
    try {
      await _firestore.collection(_collectionPath).doc(ad.id).update(ad.toMap());
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating ad', tag: 'ADS', error: e, data: {'code': e.code});
      throw Exception('فشل تحديث الإعلان: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating ad', tag: 'ADS', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء تحديث الإعلان');
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      await _firestore.collection(_collectionPath).doc(adId).delete();
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error deleting ad', tag: 'ADS', error: e, data: {'code': e.code});
      throw Exception('فشل حذف الإعلان: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error deleting ad', tag: 'ADS', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء حذف الإعلان');
    }
  }
}
