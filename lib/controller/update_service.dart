import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/controller/remote_config_service.dart';
import 'package:glamify/utils/logger.dart';

/// نتيجة فحص التحديث
enum UpdateStatus {
  /// لا يوجد تحديث - النسخة الحالية هي الأحدث
  upToDate,
  /// تحديث اختياري - يقدر يتخطاه
  optionalUpdate,
  /// تحديث إجباري - ما يقدر يتخطاه
  forceUpdate,
}

/// معلومات التحديث
class UpdateInfo {
  final UpdateStatus status;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;
  final int remainingDays; // الأيام المتبقية قبل الإجبار

  const UpdateInfo({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
    this.remainingDays = 0,
  });
}

/// خدمة التحقق من التحديثات
class UpdateService {
  static const String _firstSeenUpdateKey = 'first_seen_update_timestamp';
  static const String _dismissedVersionKey = 'dismissed_update_version';

  final RemoteConfigService _remoteConfig;

  UpdateService(this._remoteConfig);

  /// فحص التحديث
  Future<UpdateInfo> checkForUpdate() async {
    try {
      // نجلب آخر قيم من Firebase أولاً
      await _remoteConfig.fetchConfig();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // مثلاً "1.0.1"
      final latestVersion = _remoteConfig.latestVersion;
      final minVersion = _remoteConfig.minVersion;
      final forceAfterDays = _remoteConfig.forceUpdateAfterDays;
      final message = _remoteConfig.updateMessage;
      final storeUrl = _getStoreUrl();

      AppLogger.info('Update check', tag: 'UPDATE', data: {
        'current': currentVersion,
        'latest': latestVersion,
        'min': minVersion,
        'forceAfterDays': forceAfterDays,
      });

      // طباعة للتتبع
      print('🔄 [UPDATE CHECK]');
      print('   النسخة الحالية: $currentVersion');
      print('   آخر نسخة (Firebase): $latestVersion');
      print('   أقل نسخة مسموحة: $minVersion');
      print('   أيام الإجبار: $forceAfterDays');
      print('   النتيجة: ${_compareVersions(currentVersion, latestVersion)}');

      // النسخة الحالية = أو أحدث من latest → ما فيه تحديث
      if (_compareVersions(currentVersion, latestVersion) >= 0) {
        await _clearFirstSeenTimestamp();
        return UpdateInfo(
          status: UpdateStatus.upToDate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: message,
          storeUrl: storeUrl,
        );
      }

      // النسخة الحالية أقل من الحد الأدنى → تحديث إجباري فوري
      if (_compareVersions(currentVersion, minVersion) < 0) {
        return UpdateInfo(
          status: UpdateStatus.forceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: message,
          storeUrl: storeUrl,
          remainingDays: 0,
        );
      }

      // النسخة الحالية أقل من الأحدث → نحسب الأيام
      final firstSeen = await _getFirstSeenTimestamp();
      final daysSinceFirstSeen = DateTime.now().difference(firstSeen).inDays;
      final remainingDays = forceAfterDays - daysSinceFirstSeen;

      // هل مرت المدة المحددة؟
      if (remainingDays <= 0) {
        return UpdateInfo(
          status: UpdateStatus.forceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: message,
          storeUrl: storeUrl,
          remainingDays: 0,
        );
      }

      // تحديث اختياري
      return UpdateInfo(
        status: UpdateStatus.optionalUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        message: message,
        storeUrl: storeUrl,
        remainingDays: remainingDays,
      );
    } catch (e) {
      AppLogger.error('Error checking for update', tag: 'UPDATE', error: e);
      // في حالة خطأ → ندخل المستخدم عادي
      return const UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '',
        latestVersion: '',
        message: '',
        storeUrl: '',
      );
    }
  }

  /// رابط المتجر حسب النظام
  String _getStoreUrl() {
    if (kIsWeb) return '';
    // نستخدم defaultTargetPlatform بدل dart:io عشان يشتغل على الويب
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _remoteConfig.storeUrlAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _remoteConfig.storeUrlIos;
    }
    return '';
  }

  /// مقارنة نسختين (مثل "1.0.1" و "1.0.2")
  /// يرجع: >0 إذا v1 أكبر، <0 إذا v1 أصغر، 0 إذا متساوية
  int _compareVersions(String v1, String v2) {
    if (v1.isEmpty || v2.isEmpty) return 0;

    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // نكمّل الأقصر بأصفار
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// جلب أول مرة شاف التحديث (أو حفظها إذا أول مرة)
  Future<DateTime> _getFirstSeenTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_firstSeenUpdateKey);

    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    // أول مرة يشوف التحديث → نحفظ الوقت الحالي
    final now = DateTime.now();
    await prefs.setInt(_firstSeenUpdateKey, now.millisecondsSinceEpoch);
    AppLogger.info('First time seeing update, saved timestamp', tag: 'UPDATE');
    return now;
  }

  /// مسح timestamp أول مشاهدة (لما يحدّث)
  Future<void> _clearFirstSeenTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstSeenUpdateKey);
    await prefs.remove(_dismissedVersionKey);
  }

  /// حفظ إن المستخدم ضغط "لاحقاً" لهالنسخة
  Future<void> dismissUpdate(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
    AppLogger.info('User dismissed update for $version', tag: 'UPDATE');
  }

  /// هل المستخدم تخطى التحديث لهالنسخة اليوم؟
  Future<bool> wasUpdateDismissedForSession(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_dismissedVersionKey);
    return dismissed == version;
  }
}
