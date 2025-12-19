import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

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

      // فحص الاتصال الفعلي بالإنترنت عبر HTTP ping
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// فحص سريع بدون timeout طويل
  Future<bool> quickCheck() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
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
