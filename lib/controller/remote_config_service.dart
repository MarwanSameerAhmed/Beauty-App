import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  
  // Default values
  static const String _appEnabledKey = 'app_enabled';
  static const String _maintenanceTitleKey = 'maintenance_title';
  static const String _maintenanceMessageKey = 'maintenance_message';
  static const String _maintenanceImageUrlKey = 'maintenance_image_url';
  static const String _estimatedTimeKey = 'estimated_maintenance_time';
  
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values
      await _remoteConfig.setDefaults({
        _appEnabledKey: true,
        _maintenanceTitleKey: 'التطبيق قيد الصيانة',
        _maintenanceMessageKey: 'نعتذر عن الإزعاج، التطبيق قيد الصيانة حالياً لتحسين الخدمة. سيعود التطبيق للعمل قريباً.',
        _maintenanceImageUrlKey: '',
        _estimatedTimeKey: 'قريباً',
      });
      
      // Configure settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(seconds: 1), // Very short for testing
        ),
      );
      
      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      print('🔧 Remote Config initialized successfully');
      print('🔧 App enabled: ${_remoteConfig.getBool(_appEnabledKey)}');
      print('🔧 Maintenance title: ${_remoteConfig.getString(_maintenanceTitleKey)}');
    } catch (e) {
      print('❌ Error initializing Remote Config: $e');
    }
  }
  
  Future<void> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('🔄 Remote Config fetched - App enabled: ${_remoteConfig.getBool(_appEnabledKey)}');
    } catch (e) {
      print('❌ Error fetching Remote Config: $e');
    }
  }
  
  bool get isAppEnabled => _remoteConfig.getBool(_appEnabledKey);
  
  String get maintenanceTitle => _remoteConfig.getString(_maintenanceTitleKey);
  
  String get maintenanceMessage => _remoteConfig.getString(_maintenanceMessageKey);
  
  String get maintenanceImageUrl => _remoteConfig.getString(_maintenanceImageUrlKey);
  
  String get estimatedTime => _remoteConfig.getString(_estimatedTimeKey);
  
  // Method to check app status periodically
  Stream<bool> get appStatusStream async* {
    while (true) {
      await fetchConfig();
      yield isAppEnabled;
      await Future.delayed(const Duration(minutes: 1)); // Check every minute
    }
  }
}
