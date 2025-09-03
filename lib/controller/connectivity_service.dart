import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectionStatusController = StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectionStatusStream => _connectionStatusController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (result.isNotEmpty) {
        _connectionStatusController.add(result.first);
      } else {
        _connectionStatusController.add(ConnectivityResult.none);
      }
    });
  }

  Future<ConnectivityResult> checkConnectivity() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
      return results.firstWhere((result) => result != ConnectivityResult.none, orElse: () => ConnectivityResult.none);
    } else {
      return ConnectivityResult.none;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
