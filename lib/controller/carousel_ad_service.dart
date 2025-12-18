import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/carousel_ad.dart';
import 'image_upload_service.dart';
import '../utils/logger.dart';

class CarouselAdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'carousel_ads';

  static const String _imageFolder = "/carousel_ads";

  Future<String> uploadImage(Uint8List imageBytes) async {
    try {
      return await ImageUploadService.instance.uploadImage(
        imageBytes, 
        _imageFolder,
      );
    } catch (e) {
      AppLogger.error('Error uploading carousel ad image', tag: 'CAROUSEL', error: e);
      throw Exception('فشل رفع صورة إعلان الكاروسيل: ${e.toString()}');
    }
  }

  Future<void> addCarouselAd(CarouselAd ad) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      ad.id = docRef.id;
      await docRef.set(ad.toMap());
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding carousel ad', tag: 'CAROUSEL', error: e, data: {'code': e.code});
      throw Exception('فشل إضافة إعلان الكاروسيل: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error adding carousel ad', tag: 'CAROUSEL', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء إضافة إعلان الكاروسيل');
    }
  }

  Stream<List<CarouselAd>> getCarouselAds() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          try {
            return CarouselAd.fromMap(doc.data());
          } catch (e) {
            AppLogger.warning('Error parsing carousel ad document', tag: 'CAROUSEL', data: {'docId': doc.id}, error: e);
            return null;
          }
        }).where((ad) => ad != null).cast<CarouselAd>().toList();
      } catch (e) {
        AppLogger.error('Error processing carousel ads snapshot', tag: 'CAROUSEL', error: e);
        return <CarouselAd>[];
      }
    }).handleError((error) {
      AppLogger.error('Error in carousel ads stream', tag: 'CAROUSEL', error: error);
      return <CarouselAd>[];
    });
  }

  Future<void> updateCarouselAd(CarouselAd ad) async {
    try {
      await _firestore.collection(_collectionPath).doc(ad.id).update(ad.toMap());
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating carousel ad', tag: 'CAROUSEL', error: e, data: {'code': e.code});
      throw Exception('فشل تحديث إعلان الكاروسيل: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating carousel ad', tag: 'CAROUSEL', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء تحديث إعلان الكاروسيل');
    }
  }

  Future<void> deleteCarouselAd(String adId) async {
    try {
      await _firestore.collection(_collectionPath).doc(adId).delete();
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error deleting carousel ad', tag: 'CAROUSEL', error: e, data: {'code': e.code});
      throw Exception('فشل حذف إعلان الكاروسيل: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error deleting carousel ad', tag: 'CAROUSEL', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء حذف إعلان الكاروسيل');
    }
  }
}
