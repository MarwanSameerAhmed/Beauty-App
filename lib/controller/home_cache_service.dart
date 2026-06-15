import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/model/ad.dart';
import 'package:glamify/model/carousel_ad.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/utils/logger.dart';

/// خدمة الكاش المحلي للهوم بيج
/// تحفظ البيانات في SharedPreferences وتجلبها فوراً عند الفتح
/// نمط: Stale-While-Revalidate (عرض القديم فوراً + تحديث بالخلفية)
class HomeCacheService {
  static const String _keyProducts = 'home_cache_products';
  static const String _keyAds = 'home_cache_ads';
  static const String _keyCarouselAds = 'home_cache_carousel';
  static const String _keySections = 'home_cache_sections';
  static const String _keyCategories = 'home_cache_categories';
  static const String _keyLastFetch = 'home_cache_last_fetch';

  /// مدة صلاحية الكاش (30 دقيقة)
  static const Duration cacheValidity = Duration(minutes: 30);

  /// هل الكاش صالح (ما انتهت صلاحيته)
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_keyLastFetch);
      if (lastFetch == null) return false;

      final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      return DateTime.now().difference(lastFetchTime) < cacheValidity;
    } catch (e) {
      return false;
    }
  }

  /// هل يوجد كاش محفوظ (بغض النظر عن الصلاحية)
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyProducts) ||
          prefs.containsKey(_keyAds) ||
          prefs.containsKey(_keyCarouselAds);
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════
  //  حفظ البيانات
  // ═══════════════════════════════════════════

  /// حفظ المنتجات
  static Future<void> cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_keyProducts, jsonList);
      AppLogger.info('Cached ${products.length} products', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache products', tag: 'CACHE', error: e);
    }
  }

  /// حفظ الإعلانات
  static Future<void> cacheAds(List<Ad> ads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = ads.map((a) {
        final map = a.toMap();
        map['id'] = a.id; // الـ id مو موجود في toMap
        return jsonEncode(map);
      }).toList();
      await prefs.setStringList(_keyAds, jsonList);
      AppLogger.info('Cached ${ads.length} ads', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache ads', tag: 'CACHE', error: e);
    }
  }

  /// حفظ إعلانات الكاروسيل
  static Future<void> cacheCarouselAds(List<CarouselAd> carouselAds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = carouselAds.map((c) => jsonEncode(c.toMap())).toList();
      await prefs.setStringList(_keyCarouselAds, jsonList);
      AppLogger.info('Cached ${carouselAds.length} carousel ads', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache carousel ads', tag: 'CACHE', error: e);
    }
  }

  /// حفظ الأقسام
  static Future<void> cacheSections(List<AdsSectionSettings> sections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sections.map((s) => jsonEncode(s.toMap())).toList();
      await prefs.setStringList(_keySections, jsonList);
      AppLogger.info('Cached ${sections.length} sections', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache sections', tag: 'CACHE', error: e);
    }
  }

  /// حفظ الأقسام (Categories)
  static Future<void> cacheCategories(List categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((c) => jsonEncode(c.toMap())).toList();
      await prefs.setStringList(_keyCategories, jsonList.cast<String>());
      AppLogger.info('Cached ${categories.length} categories', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache categories', tag: 'CACHE', error: e);
    }
  }

  /// تحديث timestamp آخر جلب
  static Future<void> updateLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _keyLastFetch,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      AppLogger.error('Failed to update last fetch time', tag: 'CACHE', error: e);
    }
  }

  /// حفظ كل البيانات مرة واحدة
  static Future<void> cacheAll({
    required List<Product> products,
    required List<Ad> ads,
    required List<CarouselAd> carouselAds,
    required List<AdsSectionSettings> sections,
  }) async {
    await Future.wait([
      cacheProducts(products),
      cacheAds(ads),
      cacheCarouselAds(carouselAds),
      cacheSections(sections),
      updateLastFetchTime(),
    ]);
  }

  // ═══════════════════════════════════════════
  //  جلب البيانات المحفوظة
  // ═══════════════════════════════════════════

  /// جلب المنتجات المحفوظة
  static Future<List<Product>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keyProducts);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList.map((json) {
        return Product.fromMap(jsonDecode(json) as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached products', tag: 'CACHE', error: e);
      return [];
    }
  }

  /// جلب الإعلانات المحفوظة
  static Future<List<Ad>> getCachedAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keyAds);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return Ad.fromMap(map, map['id'] ?? '');
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached ads', tag: 'CACHE', error: e);
      return [];
    }
  }

  /// جلب إعلانات الكاروسيل المحفوظة
  static Future<List<CarouselAd>> getCachedCarouselAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keyCarouselAds);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return CarouselAd.fromMap(map, map['id'] ?? '');
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached carousel ads', tag: 'CACHE', error: e);
      return [];
    }
  }

  /// جلب الأقسام المحفوظة
  static Future<List<AdsSectionSettings>> getCachedSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keySections);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList.map((json) {
        return AdsSectionSettings.fromMap(
          jsonDecode(json) as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached sections', tag: 'CACHE', error: e);
      return [];
    }
  }

  /// جلب الأقسام (Categories) المحفوظة
  static Future<List<Map<String, dynamic>>> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keyCategories);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList.map((json) {
        return jsonDecode(json) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached categories', tag: 'CACHE', error: e);
      return [];
    }
  }


  /// مسح كل الكاش
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keyProducts),
        prefs.remove(_keyAds),
        prefs.remove(_keyCarouselAds),
        prefs.remove(_keySections),
        prefs.remove(_keyCategories),
        prefs.remove(_keyLastFetch),
      ]);
      AppLogger.info('Cache cleared', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to clear cache', tag: 'CACHE', error: e);
    }
  }
}
