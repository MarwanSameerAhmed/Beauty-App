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

  // Force Update keys
  static const String _latestVersionKey = 'latest_version';
  static const String _minVersionKey = 'min_version';
  static const String _forceUpdateAfterDaysKey = 'force_update_after_days';
  static const String _updateMessageKey = 'update_message';
  static const String _storeUrlAndroidKey = 'store_url_android';
  static const String _storeUrlIosKey = 'store_url_ios';
  
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
        // Force Update defaults
        _latestVersionKey: '1.0.0',
        _minVersionKey: '1.0.0',
        _forceUpdateAfterDaysKey: 10,
        _updateMessageKey: 'تحديث جديد متاح! يتضمن تحسينات في الأداء وميزات جديدة.',
        _storeUrlAndroidKey: '',
        _storeUrlIosKey: '',
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
      
      // Remote Config initialized successfully
    } catch (e) {
      // Error initializing Remote Config: $e
    }
  }
  
  Future<void> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      // Remote Config fetched
    } catch (e) {
      // Error fetching Remote Config: $e
    }
  }
  
  bool get isAppEnabled => _remoteConfig.getBool(_appEnabledKey);
  
  String get maintenanceTitle => _remoteConfig.getString(_maintenanceTitleKey);
  
  String get maintenanceMessage => _remoteConfig.getString(_maintenanceMessageKey);
  
  String get maintenanceImageUrl => _remoteConfig.getString(_maintenanceImageUrlKey);
  
  String get estimatedTime => _remoteConfig.getString(_estimatedTimeKey);

  // Force Update getters
  String get latestVersion => _remoteConfig.getString(_latestVersionKey);
  
  String get minVersion => _remoteConfig.getString(_minVersionKey);
  
  int get forceUpdateAfterDays => _remoteConfig.getInt(_forceUpdateAfterDaysKey);
  
  String get updateMessage => _remoteConfig.getString(_updateMessageKey);
  
  String get storeUrlAndroid => _remoteConfig.getString(_storeUrlAndroidKey);
  
  String get storeUrlIos => _remoteConfig.getString(_storeUrlIosKey);
  
  // Method to check app status periodically
  Stream<bool> get appStatusStream async* {
    while (true) {
      await fetchConfig();
      yield isAppEnabled;
      await Future.delayed(const Duration(minutes: 1)); // Check every minute
    }
  }
}
