import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// نظام Logging احترافي للتطبيق
/// يدعم مستويات مختلفة من الـ logging ويعمل فقط في Debug mode
class AppLogger {
  static const String _appName = 'Glamify';
  
  /// تسجيل رسائل Debug - يظهر فقط في Development
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final logTag = tag ?? 'DEBUG';
      developer.log(
        message,
        name: '$_appName:$logTag',
        time: DateTime.now(),
      );
      if (data != null) {
        developer.log(
          'Data: $data',
          name: '$_appName:$logTag:DATA',
        );
      }
    }
  }

  /// تسجيل معلومات عامة - يظهر فقط في Development
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final logTag = tag ?? 'INFO';
      developer.log(
        message,
        name: '$_appName:$logTag',
        time: DateTime.now(),
      );
      if (data != null) {
        developer.log(
          'Data: $data',
          name: '$_appName:$logTag:DATA',
        );
      }
    }
  }

  /// تسجيل تحذيرات - يظهر فقط في Development
  static void warning(String message, {String? tag, Map<String, dynamic>? data, Object? error}) {
    if (kDebugMode) {
      final logTag = tag ?? 'WARNING';
      developer.log(
        message,
        name: '$_appName:$logTag',
        time: DateTime.now(),
        level: 900, // Warning level
        error: error,
      );
      if (data != null) {
        developer.log(
          'Warning Data: $data',
          name: '$_appName:$logTag:DATA',
        );
      }
    }
  }

  /// تسجيل الأخطاء - يعمل في جميع البيئات ويرسل للـ Crashlytics
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    bool sendToCrashlytics = true,
  }) {
    final logTag = tag ?? 'ERROR';
    
    // تسجيل محلي في Development
    if (kDebugMode) {
      developer.log(
        message,
        name: '$_appName:$logTag',
        time: DateTime.now(),
        level: 1000, // Error level
        error: error,
        stackTrace: stackTrace,
      );
      
      if (data != null) {
        developer.log(
          'Error Data: $data',
          name: '$_appName:$logTag:DATA',
        );
      }
    }
    
    // إرسال للـ Crashlytics في Production (إذا كان مفعل)
    if (sendToCrashlytics && !kDebugMode) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          information: [tag ?? 'Unknown'],
        );
      } catch (e) {
        // تجاهل أخطاء Crashlytics لتجنب التكرار
      }
    }
  }

  /// تسجيل الأحداث المهمة للتطبيق
  static void event(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      developer.log(
        'Event: $eventName',
        name: '$_appName:EVENT',
        time: DateTime.now(),
      );
      if (parameters != null && parameters.isNotEmpty) {
        developer.log(
          'Parameters: $parameters',
          name: '$_appName:EVENT:PARAMS',
        );
      }
    }
  }

  /// تسجيل عمليات الشبكة
  static void network(
    String method,
    String url, {
    int? statusCode,
    String? response,
    Object? error,
  }) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      developer.log(
        '$method $url$status',
        name: '$_appName:NETWORK',
        time: DateTime.now(),
      );
      
      if (error != null) {
        developer.log(
          'Network Error: $error',
          name: '$_appName:NETWORK:ERROR',
          level: 1000,
        );
      }
      
      if (response != null && response.length < 500) {
        developer.log(
          'Response: $response',
          name: '$_appName:NETWORK:RESPONSE',
        );
      }
    }
  }

  /// تسجيل عمليات قاعدة البيانات
  static void database(String operation, {String? collection, Object? data, Object? error}) {
    if (kDebugMode) {
      final collectionInfo = collection != null ? ' [$collection]' : '';
      developer.log(
        'DB $operation$collectionInfo',
        name: '$_appName:DATABASE',
        time: DateTime.now(),
      );
      
      if (error != null) {
        developer.log(
          'DB Error: $error',
          name: '$_appName:DATABASE:ERROR',
          level: 1000,
        );
      }
    }
  }

  /// تسجيل أداء العمليات
  static void performance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    if (kDebugMode) {
      developer.log(
        '$operation completed in ${duration.inMilliseconds}ms',
        name: '$_appName:PERFORMANCE',
        time: DateTime.now(),
      );
      
      if (metrics != null && metrics.isNotEmpty) {
        developer.log(
          'Metrics: $metrics',
          name: '$_appName:PERFORMANCE:METRICS',
        );
      }
    }
  }

  /// تسجيل حالة المستخدم
  static void user(String action, {String? userId, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final userInfo = userId != null ? ' [User: ${userId.substring(0, 8)}...]' : '';
      developer.log(
        'User $action$userInfo',
        name: '$_appName:USER',
        time: DateTime.now(),
      );
      
      if (data != null && data.isNotEmpty) {
        // إزالة المعلومات الحساسة
        final sanitizedData = Map<String, dynamic>.from(data);
        sanitizedData.removeWhere((key, value) => 
          key.toLowerCase().contains('password') ||
          key.toLowerCase().contains('token') ||
          key.toLowerCase().contains('secret')
        );
        
        if (sanitizedData.isNotEmpty) {
          developer.log(
            'User Data: $sanitizedData',
            name: '$_appName:USER:DATA',
          );
        }
      }
    }
  }
}
