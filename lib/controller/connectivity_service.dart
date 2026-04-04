import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

// Conditional import: dart:io فقط على الموبايل
import 'connectivity_io_helper.dart'
    if (dart.library.html) 'connectivity_web_helper.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  bool _isConnected = true;
  Timer? _periodicCheck;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    _initConnectivity();
    _startPeriodicCheck();
  }

  void _initConnectivity() {
    // الاستماع لتغييرات الاتصال
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      await _updateConnectionStatus();
    });
    
    // فحص أولي
    _updateConnectionStatus();
  }

  void _startPeriodicCheck() {
    // فحص دوري كل 10 ثواني للتأكد من الاتصال الفعلي
    _periodicCheck = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateConnectionStatus();
    });
  }

  Future<void> _updateConnectionStatus() async {
    final hasInternet = await hasInternetConnection();
    if (_isConnected != hasInternet) {
      _isConnected = hasInternet;
      _connectionStatusController.add(_isConnected);
    }
  }

  /// فحص الاتصال الفعلي بالإنترنت (ليس فقط الاتصال بالشبكة)
  Future<bool> hasInternetConnection() async {
    try {
      // فحص الاتصال بالشبكة أولاً
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (!connectivityResult.contains(ConnectivityResult.mobile) && 
          !connectivityResult.contains(ConnectivityResult.wifi)) {
        return false;
      }

      if (kIsWeb) {
        // على الويب: الاعتماد فقط على connectivity_plus (لا يوجد InternetAddress)
        return true;
      }

      // على الموبايل: فحص DNS lookup للتأكد من الاتصال الفعلي
      return await platformDnsLookup('google.com', 5);
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// فحص سريع بدون timeout طويل
  Future<bool> quickCheck() async {
    if (kIsWeb) {
      // على الويب: فحص سريع عبر connectivity_plus
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) || 
             results.contains(ConnectivityResult.wifi);
    }
    try {
      return await platformDnsLookup('google.com', 2);
    } catch (_) {
      return false;
    }
  }

  Future<ConnectivityResult> checkConnectivity() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.mobile) || 
        results.contains(ConnectivityResult.wifi)) {
      return results.firstWhere(
        (result) => result != ConnectivityResult.none, 
        orElse: () => ConnectivityResult.none
      );
    } else {
      return ConnectivityResult.none;
    }
  }

  void dispose() {
    _periodicCheck?.cancel();
    _connectionStatusController.close();
  }
}
